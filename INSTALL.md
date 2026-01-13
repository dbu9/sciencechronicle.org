# Install and Build

This project uses Hugo with the Blist theme (as a git submodule) and a PostCSS pipeline.

## Prerequisites
- Hugo (extended build recommended for asset pipeline)
- Node.js and npm (for PostCSS/Tailwind dependencies)
- Git (for submodules)

## First-time setup
1. Fetch the theme submodule:
   ```bash
   git submodule update --init --recursive
   ```
2. Install Node dependencies:
   ```bash
   npm install
   ```

## Build the site
```bash
hugo
```

## Development server
```bash
hugo server --disableFastRender
```

## Troubleshooting
- If you see `POSTCSS: failed to transform ...` or `postcss not found`, run `npm install`.
- If you see `found no layout file ...`, the theme submodule is missing; run the submodule update command above.
