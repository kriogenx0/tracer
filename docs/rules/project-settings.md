<!-- agent-rules:synced from agent-rules@2.0.0 (e6de8a1) sha256:d689d09f4ac8. Edit agent-rules/docs/rules/project-settings.md, then run `make rules`; local edits here are not kept. -->
## Project Settings

Every repo keeps a short settings file at `docs/project/settings.md`, in this shape (the agent-rules repo keeps a copy in `templates/settings.md`). Read it before anything else; the shared rules depend on it.

```markdown
## Project Settings

- **Platforms:** frontend, backend
- **Prototyping mode:** off
```

### Platforms

One or more of:

- `frontend`: UI that runs in a browser, whether a SPA or pages rendered by the server.
- `backend`: a server or API, including one that renders pages.
- `mac`: a native macOS app.
- `iOS`: a native iOS app.
- `audio-plugin`: an audio plugin (effect or instrument) and any host app that tests it. Listed alongside the platform it runs on, such as `mac`.

Apply only the rules for the listed platforms: [backend.md](backend.md) for `backend`, [frontend.md](frontend.md) and [design-principles.md](design-principles.md) for `frontend`, and [native.md](native.md) plus the platform's own conventions (and the design principles, where they make sense natively) for `mac` and `iOS`, and [audio-plugins.md](audio-plugins.md) for `audio-plugin`. Platforms not listed are out of scope here; for example, don't add a backend to a `frontend`-only repo, and don't assume an iOS app lives in a `frontend` repo.

### Prototyping mode

`on` or `off` (default `off`). When `on`, [prototyping-mode.md](prototyping-mode.md) applies for every session in the repo: ordinary changes go directly to main without PRs; backlog tasks use branches, automatically merging completed tasks while keeping incomplete work on its branch. The user can also switch it on or off for one session by saying so; that overrides the file for that session only. Change the file only when the user asks.

### When agent-rules is added to a repo

Do this when the rules are installed into a repo that has no `docs/project/settings.md` yet. Re-syncing a repo that already has one doesn't count. Before any other work:

1. Audit the existing code against every rule that applies to the repo's listed platforms, including the design principles for `frontend`.
2. Fix every violation you find. Rules that can be checked objectively (sizes, durations, class names, make targets, file locations) must all be fixed; for judgment rules (such as minimal UI), fix what is clearly wrong.
3. Run the repo's tests and checks to confirm nothing broke.
4. Don't leave violations for later, and don't turn them into backlog tasks instead of fixing them.
5. If a fix needs a decision from the user, or would change more than about 20 files, stop, list what remains, and ask.

When an update to the rules adds or changes a requirement, audit only against the changed rules.
