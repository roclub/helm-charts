# booking-tool

Workload chart for [REP-0055](https://github.com/roclub/docs/blob/main/roclub-enhancements-proposals/REP-0055-Booking-Tool-Kubernetes-Deployment/README.md).
The existing RDS database remains in use. Envoy/TLS
([#64](https://github.com/roclub/booking-tool/issues/64)) and the non-prod
CloudFront/WAF hostname ([#65](https://github.com/roclub/booking-tool/issues/65)) follow later.

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

## Image compatibility

The default image includes the controlplane-authz integration from
[booking-tool #92](https://github.com/roclub/booking-tool/pull/92).
Both control-plane clients use client-ID/client-secret authentication. For initial
development, supply approved client-ID/client-secret credentials in the private
configuration; no JSON-key migration is required.

If adopting the
[new Zitadel machine keys](https://github.com/roclub/gitops/commit/04f43baacc73f9e09d54bdbdaf087cd647d41249)
instead, first publish and select an image with JWT authentication support using
`image.tag`, then use that build's verified configuration settings. JSON machine
keys are not client secrets.

## Configuration

Set `config.existingSecret` to a Secret in the release namespace containing the
complete application file under `config.yaml`, including SMTP authentication and
identity/control-plane settings. It is mounted read-only at `/srv/config.yaml`;
the chart neither provisions the Secret nor renders a ConfigMap in this mode.
Do not pass credentials through Helm values or Terraform; they are retained in
Helm releases or Terraform state.

Inline `config` values remain supported for compatibility and synthetic
validation; empty defaults are not runnable. Without an existing Secret, the
chart generates a ConfigMap. Keys match the application, including
`control_plane_app` and `controlplane_authz`; chart settings `config.annotations` and
`config.existingSecret` are excluded from its contents.

Supply the required HTTPS `conference.base_url` and complete `control_plane_app`
settings. Country lookups require that API even when `control_plane_app.enabled`
is false. If enabling `controlplane_authz`, supply all four of its settings.

`service.httpPort` also sets `server.port`; do not set `config.server`.
When supplying a Secret, its `server.port` must match `service.httpPort`.
After updating either configuration source, restart the Deployment to reload
the `subPath`-mounted file:

```bash
kubectl rollout restart deployment/booking-tool --namespace booking-tool
```

## Workload identity

The chart creates a dedicated service account named after the release. Set
`eks.amazonaws.com/role-arn` in `serviceAccount.annotations` to the IRSA role
provisioned by GitOps. Its trust must match the namespace and service-account name.

The Kubernetes API token remains disabled; the IRSA webhook supplies a separate
projected STS token. Verify injection and credential retrieval before activation.
`AWS_EC2_METADATA_DISABLED=true` prevents the AWS SDK default credential chain
from falling back to the node role. No static AWS keys are introduced.

To use an externally managed account, set `serviceAccount.create: false` and a
non-empty `serviceAccount.name`. Configure its IRSA annotation externally:
annotations supplied to this chart are rejected in that mode.

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
