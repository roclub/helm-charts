# booking-tool

Workload-only chart for [booking-tool issue #61](https://github.com/roclub/booking-tool/issues/61),
part of [REP-0055](https://github.com/roclub/docs/blob/main/roclub-enhancements-proposals/REP-0055-Booking-Tool-Kubernetes-Deployment/README.md).
It creates a Deployment, ClusterIP Service and application ConfigMap. Routing,
edge resources, workload identity and Argo CD applications belong to later tickets.
The existing RDS database is not managed by this chart.

## Image and chart releases

Chart version `0.1.0` is prepared for the existing **Release Charts** workflow.
The default image is `ghcr.io/roclub/booking-tool:v0.0.0-4d40c61`, published after
[booking-tool PR #69](https://github.com/roclub/booking-tool/pull/69) completed
[issue #60](https://github.com/roclub/booking-tool/issues/60).
The [publish workflow](https://github.com/roclub/booking-tool/actions/runs/40493549104)
pulled the published image and verified its ARM64 architecture. A non-empty
`image.tag` overrides `Chart.yaml`'s `appVersion`.

The existing release workflow packages changed charts, creates versioned GitHub
releases and updates the Helm repository index on pushes to `main`. Increment
`Chart.yaml`'s chart `version` for subsequent releases. Local validation and
packaging do not publish anything.

## Namespace and configuration

As with the existing charts, the Helm release namespace is the workload namespace.
Use the dedicated `booking-tool` namespace. Namespace creation is handled by
Helm's `--create-namespace` or the later Argo CD application, rather than a
chart-owned Namespace resource.

The chart follows `controlplane-app`'s configuration convention: environment
values produce a ConfigMap named `<release>-deployment-config`, and its
`config.yaml` is mounted read-only using `subPath`. Booking-tool's image reads
`/srv/config.yaml`, so the chart preserves the image entrypoint and working
directory rather than copying controlplane-app's command.

`config` uses booking-tool's existing YAML keys (`zitadel`, `database`, `email`,
`storage`, `sms`, and `control_plane_app`). `config.annotations` only annotates
the ConfigMap and is not included in the file. The chart supplies `server.port`
from `service.httpPort`, keeping the listener, Service and health probes aligned.
Do not set `config.server`; TLS terminates outside the Pod.

Provide the existing environment configuration through private GitOps values;
the empty defaults are not a runnable application configuration. This preserves
the current chart convention, not a new secret-management scheme. ConfigMaps
and Helm release data can contain credentials: restrict their access and never
check real credentials into this chart or its test fixtures.

The private GHCR pull Secret must already exist in the release namespace.
`imagePullSecrets` defaults to `dockerconfigjson-github-com`, as in
`controlplane-app`. The chart does not create registry credentials.

## Single-process deployment

`replicaCount` defaults to `1` and accepts only `0` or `1`. The Deployment uses
`Recreate`, so an upgrade stops the old process before starting its replacement.
There is no HPA. Set `replicaCount: 0` while the EC2 process is still running.
Only scale to one after the EC2 process has stopped and the later connectivity,
configuration and workload-access prerequisites are satisfied.

All three probes use HTTP `GET /health` on the named `http` port, with a
10-second period, 5-second timeout and failure threshold of 5. The Pod does not
automount a service-account token, and defaults to ARM64 nodes using the stable
`kubernetes.io/arch` label for the image produced by issue #60.

The initial resources follow the REP:

| Resource | Request | Limit |
| --- | --- | --- |
| CPU | `200m` | `1` |
| Memory | `256Mi` | `1Gi` |
| Ephemeral storage | `128Mi` | `1Gi` |

Stage the workload without running it, using the chart's published default image:

```bash
helm upgrade --install booking-tool ./charts/booking-tool \
  --namespace booking-tool --create-namespace \
  --values /path/to/private-booking-values.yaml \
  --set replicaCount=0
```

Changing the mounted ConfigMap alone does not reload the running application.
After a configuration-only update, explicitly restart the Deployment:

```bash
kubectl rollout restart deployment/booking-tool --namespace booking-tool
```

## Validation

From the repository root:

```bash
python3 -m venv .venv
.venv/bin/python -m pip install -r tests/requirements.txt
helm lint charts/booking-tool --strict
helm lint charts/booking-tool --strict --values tests/booking-tool/values.yaml
.venv/bin/python -m unittest discover -s tests/booking-tool -p 'test_*.py' -v
helm template booking-tool charts/booking-tool --namespace booking-tool \
  --values tests/booking-tool/values.yaml
helm package charts/booking-tool --destination /tmp
```

The fixtures contain render-only examples, including a non-published image tag.
Tests exercise Helm's public rendering interface, not a live Kubernetes cluster.
CI runs the same checks with Helm 3 and Helm 4.
