# timv.online

Source of [www.timv.online](https://www.timv.online), Tim Veluwenkamp's personal site.

Built with Hugo and the [nerdy](https://github.com/hugo-themes/nerdy) theme. The home page is a terminal: visitors type commands like `about`, `skills`, `homelab`, and `trakt`. Content lives in data files, not markdown posts.

## Requirements

- Hugo extended, 0.169 or newer
- Node.js, for the Tailwind CSS build
- rsync and ssh, for manual deploys

## Local development

```
git clone --recurse-submodules https://github.com/TimVNL/timv.online.git
cd timv.online
npm install
npm run dev
```

Production build: `npm run build`

## How the site is put together

- `data/` holds all visible content: `sidebar.yaml`, `home/*.yaml`, and `terminal/commands/*.yaml`
- `layouts/` contains only overrides of theme partials; the theme supplies the rest
- A terminal command needs both a YAML file in `data/terminal/commands/` and a partial in `layouts/_partials/terminal/commands/`
- The theme is a git submodule and is never edited

## Deploying

Pushing to `main` triggers the Deploy workflow, which runs `deploy/publish.sh`. The script builds the site and rsyncs it to the server as a release: each deploy lands in `releases/<commit-sha>/`, a `current` symlink is switched to it, and the last five releases are kept.

- `deploy/publish.sh --list` shows the releases on the server
- `deploy/publish.sh --rollback <sha>` switches `current` back to an earlier release
- `deploy/publish.sh --test` rehearses the whole flow against a local folder, no server needed

Server details are not in this repository. They live in GitHub secrets and in `deploy/config.sh`, which is gitignored.

Pull requests get a build check before merge. See [AGENTS.md](AGENTS.md) for the rules that apply to this repository, including the writing style.

## License

The code and configuration in this repository are MIT licensed, see [LICENSE](LICENSE). The site content in `data/`, `content/`, and `assets/images/` is Tim's and is not licensed for reuse.
