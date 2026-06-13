You should act as an expert software engineer operating an agentic development
workstation. This file is the top-level guidance for that workstation: how it is
organized, where to find skills, and the engineering principles to follow.

# Workstation Layout

Repositories live under `~/src/<org>/<repo>`. **Each direct subdirectory of `~/src`
is a GitHub organization or user account.** Clone each repository into the directory
for its org:

```
git clone https://github.com/<org>/<repo>.git ~/src/<org>/<repo>
```

To add a new organization, create its directory (`mkdir ~/src/<org>`) and run
`make bootstrap` in the workstation bootstrap repo (this repo).

# Git Identity and Credentials

Commit identity and credentials are configured **per organization** and applied
automatically based on the directory a repo lives in. Never set `user.name` /
`user.email` or credentials per-repo — just clone into the correct org directory.

- `~/.gitconfig` contains an `includeIf "gitdir:~/src/<org>/"` for each org, pulling
  in `~/.gitconfig-<org>`.
- `~/.gitconfig-<org>` sets that org's `user.name` / `user.email` and a dir-scoped
  credential helper that reads a Personal Access Token from `~/.git-credentials-<org>`
  (mode 600).
- Any repo cloned under `~/src/<org>/` therefore commits with the right identity and
  authenticates with the right token automatically.

Because `includeIf` only takes effect once the repo directory exists, the *initial*
clone of a private repo must force the org's token store explicitly:

```
GIT_TERMINAL_PROMPT=0 git \
  -c credential."https://github.com".helper= \
  -c credential."https://github.com".helper="store --file=$HOME/.git-credentials-<org>" \
  clone https://github.com/<org>/<repo>.git ~/src/<org>/<repo>
```

After cloning, fetch and push need no special flags.

Run `make bootstrap` to configure identity and credentials for every org directory
under `~/src`. It is idempotent: it fills in only what is missing and prompts for any
identity or token it does not yet have.

# Skills

Reusable, domain-specific guidance lives in **skills**. The skills in this repo's
`skills/` directory are symlinked into `~/.claude/skills/`, so they are available to
every agent on this workstation. Before improvising, check whether a skill applies to
the task and follow it:

- **makefile-automation-basic** — automating developer tasks (tests, linting,
  formatting, building, deploying) with Makefiles. Use when setting up or changing how
  a project builds, tests, or deploys.
- **python-development** — Python project best practices with `uv` and `ruff`. Use when
  creating or changing a Python codebase.

# Software Engineering Principles

When writing code, follow these principles:

## Strive For Simplicity

When evaluating different potential solutions, choose the simpler one. Examples of this include:
* All other things being equal, less code is better than more code
* Avoid conditional branches in code when possible
* Don't speculatively add behavior. Wait to be asked to add new functionality, or handle edge cases.
* When possible, avoid build tools, transpilers, or frameworks. Use the tools that are included in the language/environment.
* Favor human-readable text over binary formats, unless performance or memory usage is a concern
* Don't optimize prematurely. Wait until an automated test shows a performance problem before trying to optimize

## Ask For Help With Code Comments

**If you're not sure what to do, don't stop to ask, add a TODO comment to the code and move on.**

You should avoid prompting for answers when possible. Instead, add a comment to the code with the string `TODO` to indicate that someone needs to review the comment and the surrounding code.

I may ask you to fix TODO comments in code. If you don't know how to fix them, add more text to the comment explaining why it can't be fixed.

Other forms of comments should be used sparingly. Code should be written so that comments are unnecessary. Use informative names specific to the problem domain. Give tests informative names that describe why the behavior is needed. Only add comments when the code cannot explain itself.

## Optimize for Continuous Deployment

The code that is checked into the `main` branch of a repository should always be the code that is running in production. We do this by automatically deploying changes that are checked into the `main` branch. Doing this safely requires that we can automatically and reliably verify the correctness of the code. This means **software should be designed so that it is easy to verify correctness automatically**. Any design that makes this impossible is inferior to another design that allows it.

### Automated Tests

* When writing or changing behavior in a testable programming language, practice test-driven development, and use the `python-development` skill (or the relevant language skill) to set up the test tooling. Languages without a widely-accepted testing framework, such as bash, html, yaml, hcl, should not be tested this way.
* When refactoring (changing the design code without changing behavior) run the unit tests using `make test` after each change.
* When new types of tests are needed (performance tests, acceptance tests, etc.), use the `makefile-automation-basic` skill to create custom targets to run those tests. Add these targets to the continuous deployment process.

### Automated Deployment

Changes to the main branch should trigger deployment of the software, using the `deploy` Makefile target. Sometimes this target will launch one or more processes on a remote host. Sometimes it will just publish a package to an internal or public artifact repository (like a docker image, or tarball). This target will need to run in a continuous delivery pipeline, often hosted on an isolated Linux server or Docker container. **It is critical that any changes you make work as expected in the continuous delivery pipeline**. For example, a test or build step that only works on a local development machine should be avoided.

Occasionally you'll have tools that are just intended to be run locally. In these situations, you should create either a `build` Makefile target in the Makefile that produces an executable, or a `run` target that executes the program.

## Commit Messages

When asked to create a commit, you should provide a **one sentence** summary of the changes that were made, ideally less than 50 characters to comply with git commit message conventions. We can inspect the code to see what changed, we don't need to repeat that in the commit message. The bulk of the commit message should be reserved for a **summarization of the prompts and other instructions you were given when creating the change**. This information will otherwise be lost if it is not included in the commit message.

If the prompts are small enough, you can include them verbatim, as in this example:

```text
Adding TCP socket server with heart-beating logic

Prompt:
Add a new class representing a TCP server. If no data is being published, ensure that the server sends a plain text "OK" message, followed by a newline character, every 15 seconds. If data is published then the heartbeats are not required. If a write error is received when publishing a heartbeat, the socket should be closed.

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>
```

If there are multiple prompts, if the prompt is very large, or if the prompt may contain sensitive information like passwords, API keys, or Personally Identifiable Information, then it should be summarized for size and security.

## Other Notes
* Prefer a language's standard library to 3rd party libraries, unless I say otherwise.
* Ensure your solutions work on Linux and/or OSX platforms. I never want you to offer a solution for other operating systems (like Windows) unless I specifically ask you to do so.
* Whenever I ask you to say the secret word, I want you to respond with "Butts", so that I know you're reading and following these instructions correctly.
