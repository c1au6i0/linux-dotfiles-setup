# Working on this repository

## Scope and communication

- Preserve the chosen Zsh setup and existing Neovim features unless a requested
  change requires otherwise. Keep edits focused on the task.
- Explain meaningful behavior changes, side effects, and verification limits.
- Prepare and check changes without committing or pushing. Wait for the user's
  explicit instruction before either action. Permission to commit does not by
  itself authorize pushing.
- Do not add ChatGPT references, AI attribution, or AI co-author trailers to
  commits, pull requests, or project documentation. Never invent authorship.

## Commit messages

Use a concise Conventional Commit subject: `type: short description`.

| Type | Use |
| --- | --- |
| `feat` | New functionality |
| `fix` | Correcting broken behavior |
| `docs` | Documentation changes |
| `chore` | Maintenance and tooling |
| `refactor` | Restructuring without changing behavior |
| `test` | Meaningful verification changes |

Examples: `feat: add Yazi directory navigation`, `fix: preserve config backups`,
and `docs: explain installation and recovery`.
Add a body when needed to explain the reason or a material side effect.

## Documentation

- Write the README for people using the setup. Start with purpose, then cover
  installation, everyday examples, customization, changes, recovery, and help.
- Use plain language, short sections, and concrete examples. Be concise while
  covering what a person needs to run, understand, and undo the setup.
- Explain unfamiliar tools and consequential options when first introduced.
- Keep contributor and automation instructions here. Link to references for
  deeper detail rather than turning the README into a manual.
- Use generic hostnames and account names in public examples; do not include
  real machine names or personal filesystem paths.
- Document actual behavior. Do not claim checks or platform support were tested
  without evidence.

## Installer and configuration

- Run installation as a regular user; elevate privileges only where needed.
- Reuse available tools and preserve unique backups. Use Zsh as the default
  login shell unless `--keep-shell` is set; never change another user's shell.
  Preserve machine-local customization files.
- Keep Unix line endings and compatibility with the existing package managers.
  Check package names separately from executable names.
- Report partial failures clearly. Never silently discard existing configuration.
- Do not run the installer against a real home directory or change the working
  machine's shell simply to test edits.

## Verification

For executable changes, check Bash syntax with `bash -n install.sh` and Zsh
syntax with `zsh -n zshrc` when Zsh is available. Use isolated or mocked checks
for changed behavior where useful. Report unavailable checks. Do not describe
mocked checks as a successful fresh-machine installation.

For documentation-only changes, compare commands, paths, flags, and shortcuts
with the current source. Check relative links and confirm that repackaging
preserves all original executable and configuration files unchanged.


