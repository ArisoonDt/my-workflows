# my-workflows

Shared GitHub Actions building blocks for Terraform on Azure (OIDC auth, plan → approval → apply).

| Path | Type | Purpose |
|---|---|---|
| `.github/workflows/terraform-plan.yml` | Reusable workflow | Init and plan; uploads `tfplan-<stack>` when there are changes; upserts a PR comment |
| `.github/workflows/pre-commit.yml` | Reusable workflow | Runs the caller's `.pre-commit-config.yaml` on all files (installs Terraform for Terraform hooks) |
| `.github/workflows/terraform-apply.yml` | Reusable workflow | Applies the saved `tfplan-<stack>` from the same run, gated by a GitHub environment |
| `.github/actions/terraform-init` | Composite action | Installs Terraform (single pinned version) and optionally runs `terraform init` |
| `.github/actions/detect-changed-stacks` | Composite action | Maps changed files to stacks (`<stacks-dir>/<name>/**`, `<env-dir>/<name>.tfvars`) |

## Usage

```yaml
jobs:
  pre-commit:
    uses: ArisoonDt/my-workflows/.github/workflows/pre-commit.yml@v1

  plan:
    needs: pre-commit
    permissions: { id-token: write, contents: read, pull-requests: write }
    uses: ArisoonDt/my-workflows/.github/workflows/terraform-plan.yml@v1
    with:
      stack: network
      working-directory: terraform/stack/network
      var-file: terraform/env/network.tfvars
      azure-client-id: ${{ vars.AZURE_CLIENT_ID }}
      azure-tenant-id: ${{ vars.AZURE_TENANT_ID }}
      azure-subscription-id: ${{ vars.AZURE_SUBSCRIPTION_ID }}

  apply:
    needs: plan
    permissions: { id-token: write, contents: read }
    uses: ArisoonDt/my-workflows/.github/workflows/terraform-apply.yml@v1
    with:
      stack: network
      working-directory: terraform/stack/network
      environment: test
      azure-client-id: ${{ vars.AZURE_CLIENT_ID }}
      azure-tenant-id: ${{ vars.AZURE_TENANT_ID }}
      azure-subscription-id: ${{ vars.AZURE_SUBSCRIPTION_ID }}
```

Azure federated credentials are matched against the **calling** repo, not this one.

## Versioning

Callers pin a major tag (`@v1`). The workflows reference the composite actions at the same tag,
so release by tagging a commit and moving the major tag:

```bash
git tag v1.0.1 && git tag -f v1 && git push origin v1.0.1 && git push -f origin v1
```

Breaking input/behaviour changes get a new major tag (`v2`) so existing callers keep working.
