# roclub Helm Charts

## Table Of Contents

### Getting Started

#### Initialize the helm chart folder

```bash
helm create {{ chartName }}
```

### Pull request validation

Changes below `charts/` are validated by the `Helm - Validate PR changes`
workflow. For every changed chart, the workflow:

- runs `helm lint`,
- requires a changed chart `version` for existing charts, and
- renders the base and pull request revisions with `helm template`.

The rendered Kubernetes manifest diff is posted as an automatically updated
pull request comment and is also available in the workflow's GitHub job
summary. Rendering currently uses each chart's default `values.yaml`.
Environment-specific values should be kept in this repository and added as
additional render scenarios if they also need to be covered by this check.

Configure `Lint and compare rendered manifests` as a required status check in
the `main` branch protection rules to prevent merging a chart that did not pass
validation.
