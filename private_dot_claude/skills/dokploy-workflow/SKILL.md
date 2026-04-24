---
name: dokploy-workflow
description: Use when asked to create a deployment workflow, CI/CD pipeline, or GitHub/Gitea Actions file for a project using this user's Gitea + Dokploy stack
---

# dokploy-workflow

Generates a Gitea Actions workflow file that builds a Docker image, pushes it to the user's Gitea container registry (`gitea.callumserver.com`), and triggers a Dokploy deployment.

**Context note:** If `APPLICATION_ID` is already known from context (e.g. set as a Gitea variable by `dokploy-create-service`), skip step 4.

## Steps

Follow these steps in order. Ask one question at a time and wait for the user's reply before continuing.

### 1. Scan for Dockerfiles

Run this command and capture the output:

```bash
find . -name "Dockerfile" -not -path "*/.git/*" -not -path "*/node_modules/*" | sort
```

If no results are returned, tell the user: "No Dockerfiles found in this repository." and stop.

Otherwise, present a numbered list:

```
Found Dockerfiles:
1. ./GymTrackerApi/Dockerfile
2. ./OtherService/Dockerfile
```

### 2. Ask which Dockerfile to use

Ask: "Which Dockerfile would you like to use? (enter the number)"

Wait for the user's reply. If the number is out of range, re-prompt. Record the selected path as `{DOCKERFILE_PATH}`.

### 3. Ask for the build context

Ask: "What's the build context? (default: `.`)"

Wait for the user's reply. If they reply with nothing, a single dot, or a blank, use `.`. Record the result as `{BUILD_CONTEXT}`.

### 4. Set the Dokploy application ID

If `APPLICATION_ID` is already known from context (e.g. set by `dokploy-create-service`), skip this step.

Otherwise, ask: "What's the Dokploy application ID?"

Wait for the user's reply. Record the result as `{APPLICATION_ID}`.

If the current repo's origin is on `gitea.callumserver.com`, set it as a Gitea Actions variable so the workflow can reference it. Parse `{GITEA_OWNER}` and `{GITEA_REPO}` from the origin URL, then call `mcp__gitea__actions_config_write` with:
- `method`: `create_repo_variable`
- `owner`: `{GITEA_OWNER}`
- `repo`: `{GITEA_REPO}`
- `name`: `APPLICATION_ID`
- `value`: `{APPLICATION_ID}`

If it fails (variable already exists), retry with `method`: `update_repo_variable`.

### 5. Determine the output path

Run:

```bash
ls -d .gitea 2>/dev/null
```

- If `.gitea/` exists: output path is `.gitea/workflows/deploy.yaml`
- If not: output path is `.github/workflows/deploy.yaml`

Record the output path as `{OUTPUT_PATH}` and the directory portion as `{OUTPUT_DIR}`.

### 6. Check for an existing workflow file

Run:

```bash
ls {OUTPUT_PATH} 2>/dev/null
```

If the file exists, warn the user:

> "A workflow file already exists at `{OUTPUT_PATH}`. Overwrite it? (y/n)"

Wait for their reply. If they say no, stop. If yes, continue.

### 7. Create the directory and write the workflow file

Create the output directory if it doesn't exist:

```bash
mkdir -p {OUTPUT_DIR}
```

Write the following content to `{OUTPUT_PATH}`, substituting `{DOCKERFILE_PATH}` and `{BUILD_CONTEXT}`. The `APPLICATION_ID` is referenced via `${{ vars.APPLICATION_ID }}` — no substitution needed:

```yaml
name: Build Docker images

on:
  push:
    branches: ["main"]

env:
  REGISTRY: gitea.callumserver.com

jobs:
  build-and-push-dockerfile-image:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout repository
        uses: actions/checkout@v3

      - name: Log in to Gitea Container Registry
        uses: docker/login-action@v2
        with:
          registry: https://${{ env.REGISTRY }}
          username: ${{ gitea.actor }}
          password: ${{ secrets.REGISTRY_TOKEN }}

      - name: Build and push Docker image
        uses: docker/build-push-action@v4
        with:
          context: {BUILD_CONTEXT}
          file: {DOCKERFILE_PATH}
          push: true
          tags: |
            ${{ env.REGISTRY }}/${{ gitea.repository }}:latest
          platforms: linux/amd64

      - name: Dokploy Deployment
        uses: benbristow/dokploy-deploy-action@0.2.2
        with:
          api_token: ${{ secrets.DOKPLOY_API_KEY }}
          application_id: ${{ vars.APPLICATION_ID }}
          dokploy_url: ${{ secrets.DOKPLOY_URL }}
```

Confirm to the user: "Workflow file written to `{OUTPUT_PATH}`."
