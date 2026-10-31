# booking-tool

Workload-only chart for [REP-0055](https://github.com/roclub/docs/blob/main/roclub-enhancements-proposals/REP-0055-Booking-Tool-Kubernetes-Deployment/README.md).
The existing RDS database remains in use; routing and edge resources are separate.

## Deployment

Use the dedicated `booking-tool` release namespace; Helm or Argo CD supplies the
namespace for the resources. The GHCR pull Secret named by `imagePullSecrets`
must already exist there (default: `dockerconfigjson-github-com`).

Keep `replicaCount: 0` while EC2 runs. Only scale to one after stopping EC2 and
verifying dependency access. The Deployment uses `Recreate` to avoid overlapping
processes and duplicate background work.

```bash
helm upgrade --install booking-tool ./charts/booking-tool \
  --namespace booking-tool --create-namespace \
  --values /path/to/private-booking-values.yaml \
  --set replicaCount=0
```

## Configuration

Supply environment-specific `config` values privately; empty defaults are not
runnable. Keys match the application's configuration, including `control_plane_app`.
The generated ConfigMap is mounted read-only at `/srv/config.yaml` using `subPath`.
ConfigMaps and Helm release data can contain credentials; restrict access and
never commit real credentials.

`service.httpPort` also sets `server.port`; do not set `config.server`.
`config.annotations` annotates the ConfigMap, not the application configuration.
After a configuration-only update, restart the Deployment to reload the file:

```bash
kubectl rollout restart deployment/booking-tool --namespace booking-tool
```

## Validation

From the repository root:

```bash
helm lint charts/booking-tool --strict
helm lint charts/booking-tool --strict --values charts/booking-tool/ci/sample-values.yaml
helm template booking-tool charts/booking-tool --namespace booking-tool
helm template booking-tool charts/booking-tool --namespace booking-tool \
  --values charts/booking-tool/ci/sample-values.yaml
helm package charts/booking-tool --destination /tmp
```

CI runs these checks with Helm 3 and Helm 4. Lint validates the values schema;
rendering checks template generation, not runtime behavior or exact workload
settings. Sample values are validation-only examples, not deployable environment
values.
