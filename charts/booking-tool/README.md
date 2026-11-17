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

## Database scope

Development uses the existing PostgreSQL RDS database through a private RDS Proxy
endpoint. This chart does not install PostgreSQL or migrate data. A later move to
PostgreSQL inside Kubernetes, following the controlplane-app approach, will be
covered by a separate new REP.

## Validation

The [sample](ci/sample-values.yaml) demonstrates inline configuration and a
chart-created IRSA account, matching the controlplane-app ConfigMap convention.
Helm generates the ConfigMap and mounts its application file read-only at
`/srv/config.yaml`; no separately provisioned application configuration Secret is
required.

From the repository root:

```bash
helm lint charts/booking-tool --strict --values charts/booking-tool/ci/sample-values.yaml
helm template booking-tool charts/booking-tool --namespace booking-tool \
  --values charts/booking-tool/ci/sample-values.yaml
helm package charts/booking-tool --destination /tmp
```

The [chart workflow](../../.github/workflows/booking-tool-test.yml) checks default,
sample and external-service-account values with Helm 3 and Helm 4, including
invalid inputs and packaging. Helm validates merged values against
[values.schema.json](values.schema.json). The fixtures are synthetic; these checks
do not verify live dependencies.

GitOps environment values are not copied into this repository. Argo CD combines
them with the published chart and validates the merged values during rendering,
before applying resources.
