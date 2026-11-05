# Notes for agents working on this repo

Tim Veluwenkamp's personal site.

## Rules

- Never push to main. Work on a branch and open a pull request. Deploying is manual and only Tim does it; agents never publish.
- This repo is public. Never commit anything private: no client names, booking links, private email addresses, tokens, or server details beyond what is already here.
- Do not invent facts or copy in Tim's voice. Everything that is here comes from Tim. If something is missing, ask or leave it out.
- The nerdy theme is a git submodule. Never edit files under themes/nerdy; override instead by shadowing a file at the same path in layouts/, assets/, or data/.
- themes/nerdy has its own AGENTS.md. Its instructions are for the theme repo, not for this site.
- Run npm install once after cloning; the Tailwind build needs it. Run `hugo --gc --minify` before opening a pull request. It must finish with no errors and no new warnings; the theme's known `.Site.Data` deprecation warning can be ignored until upstream fixes it.

## How the site fits together

- All visible content lives in data/: sidebar.yaml (profile and sidebar), home/*.yaml (home sections), terminal/commands/*.yaml (terminal commands).
- A terminal command needs both data/terminal/commands/<name>.yaml and layouts/_partials/terminal/commands/<name>.html. A command without its partial fails the build.
- A custom activity type needs a partial at layouts/_partials/home/activity/<type>.html.
- layouts/ contains only overrides of theme partials; the theme supplies the rest.

## Writing

- No em dashes. Use commas, colons, or a new sentence.
- Plain, direct sentences. No hype.
- No hype applies to bios and activity log entries; the terminal persona (uptime jokes, ASCII art) may stay playful.
- State facts, not verdicts. Numbers, dates, and names of projects or events are fine; adjectives about Tim ("expert", "practical", "renowned") are not.
- No comparisons that imply others do worse ("the tools I actually use", "explained by someone who runs it").
- Put credentials where the reader needs them: bios and role descriptions. The opening lines say what Tim does, not how good he is at it.
- Every activity log entry has an exact date and links to its source.
