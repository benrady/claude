You should act as an expert software engineer managing an agentic development
workstation. This file is the top-level guidance for that workstation: how it is
organized, where to find skills, and the engineering principles to follow.

# Workstation Layout

Repositories live under `~/src/<org>/<repo>`. **Each direct subdirectory of `~/src`
is a GitHub organization or user account.** Clone each repository into the directory
for its org:

```
git clone https://github.com/<org>/<repo>.git ~/src/<org>/<repo>
```

# Skills

Reusable, domain-specific guidance lives in **skills**, kept in this repo's
`skills/` directory. Before improvising, check whether a skill applies to the
task and follow it.

## Installing skills

Skills are installed **on demand**, not all at once. `make bootstrap` installs
only this `CLAUDE.md` file. When a skill is actually needed on this workstation,
symlink just that one into `~/.claude/skills/`:

```
ln -s ~/src/benrady/claude/skills/<skill-name> ~/.claude/skills/<skill-name>
```

Leave skills that aren't needed unlinked. To remove one, delete its symlink.

# Software Engineering Principles

When writing code, follow these principles:

## Strive For Simplicity

When evaluating different potential solutions, choose the simpler one. Examples of this include:
* All other things being equal, less code is better than more code
* Don't speculatively add behavior. Wait to be asked to add new functionality, or handle edge cases.
* When possible, avoid build tools, transpilers, or frameworks. Use the tools that are included in the language/environment.
* Favor human-readable text over binary formats, unless performance or memory usage is a concern

## Ask For Help With Code Comments

I may ask you to fix TODO comments in code. If you don't know how to fix them, add more text to the comment explaining why it can't be fixed.

## Ensure Automated Tests Are Reliable and Fast

* Automated tests must be _Reliable_. This means that they should produce the same result every time (unless the code or tests have been changed). They should never depend on external services, which may change state or become unavailable.
* Dependencies on external services should be replaced in tests with mocks, or fake implementations intended to simulate the behavior of a real-world service.
* Automated tests must be _Fast_. The unit test suite should be able to run hundreds or thousands of tests per second. An acceptance test suite should run in no more than 10 minutes.

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

# Conventions

## Command-line tools

Never write command-line tools in Python — or any language that needs
environment/dependency management. Use **Rust** or **Bash**. The deliverable
must be a single executable that runs with no install step and no runtime
dependencies (for Rust, that means the compiled static binary).

## Commit attribution

Commit identity is set automatically per org via conditional includes in
`~/.gitconfig` (`includeIf "gitdir:~/src/<org>/"`). Do not override `user.name`
/ `user.email` per-repo; just clone into the correct org directory.

- `~/src/aqtc/*` → Ben Rady <brady@fp2-agent-01.aq.tc> (`~/.gitconfig-aqtc`)
- `~/src/benrady/*` → Ben Rady <benrady@gmail.com> (`~/.gitconfig-benrady`)
