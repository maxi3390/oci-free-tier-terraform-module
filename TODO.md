# TODO

## CI hardening

The GitHub Actions workflow (`.github/workflows/terraform.yml`) already runs
`terraform fmt -check`, `terraform validate` and `terraform test`. Two
additions are still pending:

- [ ] **tflint** with the OCI provider ruleset
      (<https://github.com/terraform-linters/tflint-ruleset-oci>) — catches
      provider-specific issues that `terraform validate` misses, such as
      invalid instance shapes or malformed OCIDs.
- [ ] **Security scanning** with `trivy config` or `checkov` — would surface
      findings in CI such as the default SSH ingress rule allowing `0.0.0.0/0`,
      making the wide-open default visible instead of silent.
