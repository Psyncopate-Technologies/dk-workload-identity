# tools/

Pinned local copies of every CLI this project uses. `tools/install.sh` downloads
them into `tools/bin/`. Both laptops and the GitHub Actions runner install from
this same script — no system-wide installs, no "works on my machine."

## What's pinned

Versions live in `versions.env`. Current set:

- Terraform
- Terragrunt
- Confluent CLI
- Python 3.12 (installed via `uv`)

Bump a version in `versions.env`, commit, and the pipeline picks it up on the
next run.

## Local use

```bash
./tools/install.sh          # downloads binaries into tools/bin
source ./tools/env.sh       # prepends tools/bin to PATH for this shell
terraform -version
terragrunt -version
confluent version
python3.12 --version
```

`tools/bin/`, `tools/.cache/`, and `tools/.python/` are gitignored — they are
rebuilt from `versions.env` on demand.

## CI use

`.github/workflows/terraform.yml` runs `./tools/install.sh` on each run, then
prepends `tools/bin` to `$GITHUB_PATH`. The runner is a stock GitHub-hosted
Linux image — no pre-installed dependencies are assumed.
