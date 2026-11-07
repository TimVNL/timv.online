# Notes for agents working on this repo

Tim Veluwenkamp's personal site.

## Rules

- Agents never push. Commit changes locally and leave the push to Tim; he checks every change by hand before it goes to GitHub. Pushing to main publishes the site via GitHub Actions.
- Never rewrite published history or force push unless Tim asks for it explicitly.
- deploy/publish.sh is the single build-and-rsync script; the workflow runs it on push to main, Tim can run it by hand. Server details live in GitHub secrets or deploy/config.sh, never in the repo.
- deploy/config.sh and .secret/ are gitignored on purpose; never stage or commit them.
- This repo is public. Never commit anything private: no client names, booking links, private email addresses, tokens, or server details beyond what is already here.
- Do not invent facts or copy in Tim's voice. Everything that is here comes from Tim. If something is missing, ask or leave it out.
- The nerdy theme is a git submodule. Never edit files under themes/nerdy; override instead by shadowing a file at the same path in layouts/, assets/, or data/.
- themes/nerdy has its own AGENTS.md. Its instructions are for the theme repo, not for this site.
- Run npm install once after cloning; the Tailwind build needs it. Run `hugo --gc --minify` before committing. It must finish with no errors and no new warnings; the theme's known `.Site.Data` deprecation warning can be ignored until upstream fixes it.

## How the site fits together

- All visible content lives in data/: sidebar.yaml (profile and sidebar), home/*.yaml (home sections), terminal/commands/*.yaml (terminal commands).
- A terminal command needs both data/terminal/commands/<name>.yaml and layouts/_partials/terminal/commands/<name>.html. A command without its partial fails the build.
- A custom activity type needs a partial at layouts/_partials/home/activity/<type>.html. For one-off entries, the generic `event` type (label, optional url, text) already exists and needs no new partial.
- The Projects grid and the Activity Log render a visible subset (`featuredLimit` in their data files) with the rest behind a more/less toggle; the toggle lives in the shadowed section partials.
- Snapshot data (trakt months, homelab containers, uptime) changes only when Tim supplies fresh numbers.
- layouts/ contains only overrides of theme partials; the theme supplies the rest.
- The palette lives in assets/css/custom.css as CSS variable overrides: Latte for light mode, Frappé accents on deep tinted surfaces for dark. Style new components with the variables (--accent-*, --background, --surface, --card); the theme hardcodes slate colors in places, so copied classes drift from the palette.
- The Activity Log section and the tail command both read data/home/activity-logs.yaml; add an entry once and it appears in both.
- Deploys are release-based: each release lands in $DEPLOY_PATH/<commit-sha>/ with a current symlink, five kept. deploy/publish.sh supports --test, --list, --rollback, and --dry-run.

## Writing

- No em dashes. Use commas, colons, or a new sentence.
- Plain, direct sentences. No hype.
- No hype applies to bios and activity log entries; the terminal persona (uptime jokes, ASCII art) may stay playful.
- State facts, not verdicts. Numbers, dates, and names of projects or events are fine; adjectives about Tim ("expert", "practical", "renowned") are not.
- No comparisons that imply others do worse ("the tools I actually use", "explained by someone who runs it").
- Put credentials where the reader needs them: bios and role descriptions. The opening lines say what Tim does, not how good he is at it.
- Every activity log entry has an exact date and links to its source.
