# booking-tool

Workload chart for [REP-0055](https://github.com/roclub/docs/blob/main/roclub-enhancements-proposals/REP-0055-Booking-Tool-Kubernetes-Deployment/README.md).

## Deployment

Use the `booking-tool` namespace. The GHCR pull Secret named by `imagePullSecrets`
must already exist there (default: `dockerconfigjson-github-com`).

Keep `replicaCount: 0` while the corresponding EC2 process runs. Verify dependency
access and stop EC2 before activating one replica. `Recreate` prevents overlapping
Deployment replacements.

```bash
helm upgrade --install booking-tool ./charts/booking-tool \
  --namespace booking-tool --create-namespace \
  --values /path/to/booking-values.yaml \
  --set replicaCount=0
```

For chart-option explanations, see the comments in [values.yaml](values.yaml).
Environment-specific prerequisites, authentication and activation checks live in
the [GitOps runbook](https://github.com/roclub/gitops/blob/main/docs/booking-tool.md).

## Validation

From the repository root, using synthetic fixtures:

The [main sample](ci/sample-values.yaml) mirrors development's existing configuration
Secret and chart-created IRSA account. The [inline fixture](ci/inline-values.yaml)
covers ConfigMap generation and an externally managed service account.

```bash
helm lint charts/booking-tool --strict --values charts/booking-tool/ci/sample-values.yaml
helm lint charts/booking-tool --strict --values charts/booking-tool/ci/inline-values.yaml
helm template booking-tool charts/booking-tool --namespace booking-tool \
  --values charts/booking-tool/ci/sample-values.yaml
helm package charts/booking-tool --destination /tmp
```

CI checks default, inline and existing-Secret values with Helm 3 and Helm 4,
including invalid inputs. These offline checks do not prove runtime access;
the fixtures are not deployable environment configuration.

Helm validates merged values against [values.schema.json](values.schema.json)
during lint, template, install and upgrade. The
[chart workflow](../../.github/workflows/booking-tool-test.yml) runs these synthetic
checks on matching pull requests and pushes to `main`.

GitOps environment values are not copied into this repository. Argo CD combines
them with the published chart and validates the merged values during rendering,
before applying resources.
