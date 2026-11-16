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

```bash
helm lint charts/booking-tool --strict --values charts/booking-tool/ci/sample-values.yaml
helm lint charts/booking-tool --strict --values charts/booking-tool/ci/secret-values.yaml
helm template booking-tool charts/booking-tool --namespace booking-tool \
  --values charts/booking-tool/ci/secret-values.yaml
helm package charts/booking-tool --destination /tmp
```

CI checks default, inline and existing-Secret values with Helm 3 and Helm 4,
including invalid inputs. These offline checks do not prove runtime access;
the fixtures are not deployable environment configuration.
