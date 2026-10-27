import shutil
import subprocess
import tempfile
import unittest
from pathlib import Path

import yaml


ROOT = Path(__file__).resolve().parents[2]
CHART = ROOT / "charts" / "booking-tool"
SAMPLE_VALUES = Path(__file__).with_name("values.yaml")


def render(*arguments, release="booking-tool", namespace="booking-tool", chart=CHART):
    result = subprocess.run(
        [
            "helm", "template", release, str(chart),
            "--namespace", namespace, *arguments,
        ],
        capture_output=True,
        text=True,
    )
    if result.returncode:
        raise AssertionError(result.stderr)
    documents = [document for document in yaml.safe_load_all(result.stdout) if document]
    resources = {document["kind"]: document for document in documents}
    if len(resources) != len(documents):
        raise AssertionError("Unexpected duplicate resource kind in workload chart")
    return resources


class BookingToolChartTests(unittest.TestCase):
    def test_default_workload_preserves_single_process_behavior(self):
        deployment = render()["Deployment"]
        self.assertEqual(deployment["spec"]["replicas"], 1)
        self.assertEqual(deployment["spec"]["strategy"], {"type": "Recreate"})
        pod = deployment["spec"]["template"]["spec"]
        self.assertFalse(pod["automountServiceAccountToken"])
        self.assertEqual(
            pod["imagePullSecrets"], [{"name": "dockerconfigjson-github-com"}]
        )
        self.assertEqual(pod["nodeSelector"], {"kubernetes.io/arch": "arm64"})
        self.assertEqual(len(pod["containers"]), 1)
        container = pod["containers"][0]
        self.assertNotIn("command", container)
        self.assertNotIn("args", container)
        self.assertEqual(
            container["resources"],
            {
                "requests": {
                    "cpu": "200m", "memory": "256Mi",
                    "ephemeral-storage": "128Mi",
                },
                "limits": {
                    "cpu": "1", "memory": "1Gi",
                    "ephemeral-storage": "1Gi",
                },
            },
        )

    def test_service_and_all_health_probes_target_http(self):
        resources = render()
        deployment = resources["Deployment"]
        service = resources["Service"]
        container = deployment["spec"]["template"]["spec"]["containers"][0]
        self.assertEqual(
            container["ports"],
            [{"name": "http", "containerPort": 8080, "protocol": "TCP"}],
        )
        for probe in ("startupProbe", "livenessProbe", "readinessProbe"):
            with self.subTest(probe=probe):
                self.assertEqual(
                    container[probe],
                    {
                        "httpGet": {"path": "/health", "port": "http"},
                        "failureThreshold": 5,
                        "periodSeconds": 10,
                        "timeoutSeconds": 5,
                    },
                )
        self.assertEqual(service["spec"]["type"], "ClusterIP")
        self.assertEqual(
            service["spec"]["ports"],
            [{"name": "http", "port": 8080, "targetPort": "http", "protocol": "TCP"}],
        )
        self.assertEqual(
            service["spec"]["selector"],
            deployment["spec"]["selector"]["matchLabels"],
        )
        self.assertEqual(
            service["spec"]["selector"],
            deployment["spec"]["template"]["metadata"]["labels"],
        )

    def test_existing_config_format_is_mounted_at_image_config_path(self):
        resources = render("--values", str(SAMPLE_VALUES))
        pod = resources["Deployment"]["spec"]["template"]["spec"]
        container = pod["containers"][0]
        self.assertEqual(
            container["volumeMounts"],
            [{
                "name": "app-config", "mountPath": "/srv/config.yaml",
                "subPath": "config.yaml", "readOnly": True,
            }],
        )
        self.assertEqual(
            pod["volumes"],
            [{
                "name": "app-config",
                "configMap": {"name": "booking-tool-deployment-config"},
            }],
        )
        config_map = resources["ConfigMap"]
        self.assertEqual(
            config_map["metadata"]["name"], "booking-tool-deployment-config"
        )
        config = yaml.safe_load(config_map["data"]["config.yaml"])
        self.assertNotIn("annotations", config)
        self.assertEqual(config["server"]["port"], 18080)
        self.assertEqual(config["zitadel"]["project_id"], "00123")
        self.assertEqual(config["zitadel"]["client_id"], "example-client")
        self.assertFalse(config["zitadel"]["slo_enabled"])
        self.assertEqual(
            config["database"]["dsn"],
            "postgres://database.example.com:5432/roclub_booking?sslmode=require",
        )
        self.assertEqual(
            config["database"]["secret_arn"],
            "arn:aws:secretsmanager:eu-central-1:123456789012:secret:example",
        )
        self.assertEqual(config["email"]["smtp_password"], "not-a-real-password:#")
        self.assertEqual(config["sms"]["origins"], {"+49": "example"})
        self.assertFalse(config["control_plane_app"]["enabled"])
        self.assertEqual(config["storage"]["max_upload_bytes"], 10485760)
        self.assertEqual(container["ports"][0]["containerPort"], 18080)
        self.assertEqual(resources["Service"]["spec"]["ports"][0]["port"], 18080)

    def test_nonprod_values_hold_workload_at_zero_and_preserve_annotations(self):
        resources = render("--values", str(SAMPLE_VALUES))
        deployment = resources["Deployment"]
        self.assertEqual(deployment["spec"]["replicas"], 0)
        pod = deployment["spec"]["template"]["spec"]
        self.assertEqual(pod["imagePullSecrets"], [{"name": "example-ghcr"}])
        self.assertEqual(
            pod["containers"][0]["image"],
            "ghcr.io/roclub/booking-tool:v0.0.0-example",
        )
        for kind, wave in (("Deployment", "1"), ("Service", "1"), ("ConfigMap", "0")):
            with self.subTest(kind=kind):
                self.assertEqual(
                    resources[kind]["metadata"]["annotations"],
                    {"argocd.argoproj.io/sync-wave": wave},
                )

    def test_workload_only_resources_follow_release_identity_and_namespace(self):
        resources = render(release="preview-booking", namespace="booking-preview")
        self.assertEqual(set(resources), {"Deployment", "Service", "ConfigMap"})
        for resource in resources.values():
            with self.subTest(kind=resource["kind"]):
                self.assertEqual(resource["metadata"]["namespace"], "booking-preview")
                self.assertEqual(
                    resource["metadata"]["labels"]["app.kubernetes.io/managed-by"],
                    "Helm",
                )
                self.assertTrue(resource["metadata"]["name"].startswith("preview-booking"))
        deployment = resources["Deployment"]
        self.assertEqual(
            deployment["spec"]["selector"]["matchLabels"],
            {
                "app.kubernetes.io/name": "booking-tool",
                "app.kubernetes.io/instance": "preview-booking",
            },
        )
        self.assertEqual(
            deployment["spec"]["template"]["spec"]["volumes"][0]["configMap"]["name"],
            resources["ConfigMap"]["metadata"]["name"],
        )

    def test_image_tag_defaults_to_chart_app_version(self):
        with tempfile.TemporaryDirectory() as directory:
            chart = Path(directory) / "booking-tool"
            shutil.copytree(CHART, chart)
            metadata = yaml.safe_load((chart / "Chart.yaml").read_text())
            metadata["appVersion"] = "v9.8.7"
            (chart / "Chart.yaml").write_text(yaml.safe_dump(metadata))
            deployment = render(chart=chart)["Deployment"]
        self.assertEqual(
            deployment["spec"]["template"]["spec"]["containers"][0]["image"],
            "ghcr.io/roclub/booking-tool:v9.8.7",
        )

    def test_invalid_workload_values_are_rejected(self):
        for value, field in (
            ("replicaCount=2", "replicaCount"),
            ("replicaCount=-1", "replicaCount"),
            ("replicaCount=one", "replicaCount"),
            ("service.httpPort=0", "httpPort"),
            ("service.httpPort=65536", "httpPort"),
            ("image.tag=123", "tag"),
            ("config.server.port=9000", "server"),
        ):
            with self.subTest(value=value):
                result = subprocess.run(
                    ["helm", "template", "booking-tool", str(CHART), "--set", value],
                    capture_output=True,
                    text=True,
                )
                self.assertNotEqual(result.returncode, 0)
                self.assertIn(field, result.stderr)


if __name__ == "__main__":
    unittest.main()
