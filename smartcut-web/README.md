# SmartCut AI web prototype

This standalone website lives in `smartcut-web/` and is isolated from the WARFOX Godot project files.

## Deploy
The GitHub Actions workflow `.github/workflows/smartcut-pages.yml` deploys the contents of this folder to GitHub Pages from branch `smartcut-site`.

If Pages is not enabled, open repository Settings → Pages and set Build and deployment source to **GitHub Actions**.

Expected URL after a successful deployment:
https://hicham07dzz-cyber.github.io/WARFOX/

## Current prototype limits
- Selects a reference video and multiple user clips.
- Reads local media metadata in the browser.
- Creates and downloads a basic proposed timeline JSON.
- It does not yet understand scenes or reference editing style semantically.
- It does not apply transitions/effects/color grading or render an edited video.

The WARFOX Godot project and its existing files are not changed by this branch's website additions.
