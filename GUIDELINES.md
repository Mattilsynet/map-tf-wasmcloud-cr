# Module repository guidelines

- [Module repository guidelines](#module-repository-guidelines)
  - [Terraform module](#terraform-module)
    - [Examples](#examples)
    - [Submodules](#submodules)
    - [Versioning](#versioning)
  - [Auto-documentation tooling](#auto-documentation-tooling)
  - [Pre-commit checks (optional but recommended)](#pre-commit-checks-optional-but-recommended)
  - [Github workflows](#github-workflows)
    - [Release workflows](#release-workflows)
      - [Automated draft release (release\_auto.yaml)](#automated-draft-release-release_autoyaml)
      - [Semi-auto draft release (release\_on\_tag\_push.yaml)](#semi-auto-draft-release-release_on_tag_pushyaml)
    - [Linting workflows](#linting-workflows)
      - [Terraform format and lint checker (tf\_format\_lint.yaml)](#terraform-format-and-lint-checker-tf_format_lintyaml)
    - [Additional](#additional)
      - [Tag tester (tag\_tester.yaml)](#tag-tester-tag_testeryaml)
  - [Notifications](#notifications)
  - [Changelog and Release Notes generator](#changelog-and-release-notes-generator)
    - [Manual Changelog Generation](#manual-changelog-generation)

## Terraform module

### Examples

Always include usage examples of your module under corresponding `/examples` folder. It is a good practice to include several examples under `/examples/<descriptive_name>` sub folders if module supports several modes of operation based on unique set of input variables.

### Submodules

If module contains additional submodules, please place terraform code files under corresponding folders:

```fs
     `./modules/<submodule_nameA>/`
     ....
     `./modules/<submodule_nameZ>/`
```

### Versioning

For ease of use, set github tags to denote module versions. Later on, users can specify concrete module version via corresponding field in `module` structure:

```hcl
module "module_name" {
  source = "github.com/Mattilsynet/map-tf-module?ref=v1.0.0"
  ...
}
```

> IMPORTANT: We're trying to follow semantic versioning specification for our tags and releases

see [Release workflow](#release-workflows) section for details

## Auto-documentation tooling

Please use [terraform-docs](<https://github.com/terraform-docs/terraform-docs>) for auto-generation of module documentation (in addition to hand-written if any). Example usage:

```terminal
# from the root of a module
terraform-docs markdown table --output-file README.md --output-mode inject .
```

Command above will update (or generate on first run) README.md file without changing manually added paragraphs.

See [next section](#pre-commit-checks-optional-but-recommended) for automation tips.

## Pre-commit checks (optional but recommended)

Current repository includes configuration file for [pre-commit hooks package manager](https://pre-commit.com) which automates terraform code formatting and module documentation generation.

1. Install [pre-commit](https://pre-commit.com/#install)
1. Create config file `.pre-commit-config.yaml` ([ships](.pre-commit-config.yaml) with current template repository):

    ```yaml
          repos:
            - repo: https://github.com/terraform-docs/terraform-docs
              rev: "v0.16.0"
              hooks:
                - id: terraform-docs-go
                  args: ["markdown", "table", "--output-file", "README.md","--output-mode","inject", "."]
            - repo: https://github.com/antonbabenko/pre-commit-terraform
              rev: "v1.77.0" # Get the latest from: https://github.com/gruntwork-io/pre-commit/releases
              hooks:
                - id: terraform_fmt
    ```

1. Run:

   ```terminal
    pre-commit install
    pre-commit install-hooks
   ```

1. From now on every commit attempt will call corresponding checks

## Github workflows

> NB: rename `.github/_workflows` to `.github/workflows` in the actual repository for github to pickup supplied workflows.

> Actual workflows are implemented as github reusable workflows and placed in a separate repository (<https://github.com/Mattilsynet/wf-map-tf-releases>)

### Release workflows

Key points:

1. Requires conventional commits
1. Semantic releases for versioning (`major.minor.patch`)
1. Automatic generation of the next semantic version number based on commit type(see regex in [corresponding workflow](.github/_workflows/release_auto.yaml) and read the following section)
1. Automatic Release Notes(Changelog) generation

#### Automated draft release (release_auto.yaml)

>IMPORTANT: The very first tag must be created manually.

1. Auto-release workflow triggers on changes in `*.tf` files in the repository (`/examples` folder is **excluded**)
1. Create a new branch (branch name is not respected in the process of next tag name generation).
   > Forks not tested
1. Add commit(s).

      Commit title is supposed to be in the format: (`<type>`(`<scope>`): `<subject>`):

      - `<scope>` is arbitrary and can be omitted

      - `<type>` can be arbitrary but in order to generate structured `Changelog` and `Release notes` a set of named groups were defined in changelog generator. Check [corresponding configuration file](./.chglog/config.yml). Example: all `docs:` and `doc:` titled commits will be shown under `Documentation:` section of Release Notes/Changelog.

      - `<subject>` is required. Starts after `:` (single space after `:` is required)

1. Create PR

1. Predicted next tag version will be generated and pasted as a comment to the PR

1. According to the specified commit `<type>`:

      - `[major|breaking|break]` or **any** type with appended exclamation mark (**!**): increments **major** version

      - `[feat|feature]`: increments **minor** version

      - `any other type`: increments **patch** version.

      > In case of multiple commits with different "levels of urgency", e.g. "fix" and "breaking", the highest(breaking in this example) is taken to generate next tag.
1. Set a `release` tag on the **PR**
   > IMPORTANT: if the label is not set, no tag and release will be generated
1. Merge & Close PR. This is what triggers [tag and release workflow](./.github/_workflows/release_auto.yaml)
1. Follow to the `Releases` section of your repository to find newly created draft release. Review and publish. See [Notifications](#notifications) section for setting slack notifications.

#### Semi-auto draft release (release_on_tag_push.yaml)

New draft release is created after manual tag push. Same rules apply in regards to release notes generation.

### Linting workflows

#### Terraform format and lint checker (tf_format_lint.yaml)

Triggers on `open` and `synchronize` PR events if `*.tf` files are modified.
List of available/implemented lint checks:

   1. [terraform fmt](https://developer.hashicorp.com/terraform/cli/commands/fmt)
   1. [tflint (basic)](https://github.com/terraform-linters/tflint)
   1. [tfsec (not implemented)](https://aquasecurity.github.io/tfsec/)

### Additional

#### Tag tester (tag_tester.yaml)

This is an informational workflow to inform PR creator on the the auto-generated tag name that will be created on merging/closing PR.

## Notifications

Inform your users about new releases.

1. Create a new slack channel. `#plattform-map-releases` channel was recently created.
1. Configure slack channel(subscribe to repository, exclude all integrations except for releases):

```slack
/github subscribe Mattilsynet/map-tf-<module-name>
/github unsubscribe Mattilsynet/map-tf-test-<module-name> issues pulls commits deployments
```

## Changelog and Release Notes generator

Changelog generator (`git-chglog`) is used by workflows to generate release notes. Changelog (CHANGELOG.md) on the other hand has to be generated **manually**.

> IMPORTANT: `.chglog` folder contains configuration files for `git-chglog` which are supposed to be used by release notes generator step in corresponding github-actions workflow. Do not modify or delete them.

Repository ships with configuration files for [git-chglog](https://github.com/git-chglog/git-chglog) changelog generator tool. The layout of the `Changelog` and `Release Notes` use the same template and configuration **by default** (may be changed).

### Manual Changelog Generation

1. Install `git-chglog` either [following instructions](https://github.com/git-chglog/git-chglog#installation) or download via [releases page](https://github.com/git-chglog/git-chglog/releases)

1. Required configuration files supplied under `.chglog` folder so `init` step is not required.
1. Run `git-chglog -o CHANGELOG.md` to generate full changelog for current module repository.
