---
name: dokploy-create-service
description: Use when asked to create a new Dokploy project and application/service for the current repo using the Dokploy MCP tools
---

# dokploy-create-service

Creates a Dokploy project and Docker-provider application for the current repo using the Dokploy MCP, defaulting to the "Lightning" server.

## Steps

Follow these steps in order. Ask one question at a time and wait for the user's reply before continuing.

### 1. Check for a git repo

Run:

```bash
git rev-parse --show-toplevel 2>/dev/null
```

- If it succeeds, record `{IN_GIT_REPO}` = `true` and use `basename` of the output as the default `{PROJECT_NAME}` and `{APP_NAME}`.
- If it fails, record `{IN_GIT_REPO}` = `false`. There are no defaults — ask directly in steps 2 and 3.

### 2. Ask for project name

Ask: "What should the Dokploy project be called? (default: `{PROJECT_NAME}`)"

Wait for reply. If blank, use the default. Record as `{PROJECT_NAME}`.

Also derive `{PROJECT_SLUG}` from `{PROJECT_NAME}`: lowercase, replace spaces and non-alphanumeric characters (except `.`, `_`, `-`) with `-`.

### 3. Ask for application name

Ask: "What should the application/service be called? (default: `{APP_NAME}`)"

Wait for reply. If blank, use the default. Record as `{APP_NAME}`.

Also derive `{APP_SLUG}` = `{PROJECT_SLUG}-{APP_NAME_SLUG}` (same slug rules as above), truncated to 63 chars.

### 4. Derive Docker image default

If `{IN_GIT_REPO}` = `true`:

Run:

```bash
git remote get-url origin
```

Parse the output to extract the path (e.g. `gitea.callumserver.com/callumwk/hodor-api`). Strip any `.git` suffix. Use this as `{DOCKER_IMAGE_DEFAULT}`.

Ask: "What Docker image should this application use? (default: `{DOCKER_IMAGE_DEFAULT}:latest`)"

Wait for reply. If blank, use `{DOCKER_IMAGE_DEFAULT}:latest`. Record as `{DOCKER_IMAGE}`.

If `{IN_GIT_REPO}` = `false`:

Ask: "What Docker image should this application use?"

Wait for reply. Record as `{DOCKER_IMAGE}`.

Set `{REGISTRY_USERNAME}` to `callumwk` and `{REGISTRY_URL}` to `gitea.callumserver.com`.

### 5. Ask for registry password

Ask: "What's the registry password for `callumwk` at `gitea.callumserver.com`? (press enter to skip if not required)"

Wait for reply. If blank or "no", set `{REGISTRY_PASSWORD}` to `null`. Otherwise record as `{REGISTRY_PASSWORD}`.

### 6. Find the Lightning server

Call `mcp__dokploy-mcp__server-all` with no arguments.

Search the returned list for a server whose `name` contains "Lightning" (case-insensitive). Record its `serverId` as `{SERVER_ID}`.

If not found, tell the user: "Could not find a server named 'Lightning'. Available servers: [list names]" and ask which to use.

### 7. Create the project

Call `mcp__dokploy-mcp__project-create` with:
- `name`: `{PROJECT_NAME}`

Record the returned `projectId` as `{PROJECT_ID}`.

### 8. Get or create an environment

Call `mcp__dokploy-mcp__environment-byProjectId` with `projectId: {PROJECT_ID}`. Use the first result if any exist; otherwise call `mcp__dokploy-mcp__environment-create` with `name: "Production"` and `projectId: {PROJECT_ID}`. Record the `environmentId` as `{ENVIRONMENT_ID}`.

### 9. Create the application

Call `mcp__dokploy-mcp__application-create` with:
- `name`: `{APP_NAME}`
- `appName`: `{APP_SLUG}` (i.e. `{PROJECT_SLUG}-{APP_NAME_SLUG}`)
- `environmentId`: `{ENVIRONMENT_ID}`
- `serverId`: `{SERVER_ID}`

Record the returned `applicationId` as `{APPLICATION_ID}`.

### 10. Configure Docker provider

Call `mcp__dokploy-mcp__application-saveDockerProvider` with:
- `applicationId`: `{APPLICATION_ID}`
- `dockerImage`: `{DOCKER_IMAGE}`
- `username`: `{REGISTRY_USERNAME}`
- `password`: `{REGISTRY_PASSWORD}`
- `registryUrl`: `{REGISTRY_URL}`

### 11. Confirm to the user

Tell the user:

> "Dokploy service created:
> - **Project:** `{PROJECT_NAME}` (`{PROJECT_ID}`)
> - **Application:** `{APP_NAME}` (`{APPLICATION_ID}`)
> - **Server:** Lightning
> - **Image:** `{DOCKER_IMAGE}`"

### 12. Set APPLICATION_ID as a Gitea Actions variable

If `{IN_GIT_REPO}` = `true` and the origin URL contains `gitea.callumserver.com`:

Parse `{GITEA_OWNER}` and `{GITEA_REPO}` from the origin URL. Examples:
- `https://gitea.callumserver.com/callumwk/hodor-api.git` → owner `callumwk`, repo `hodor-api`
- `git@git.callumserver.com:callumwk/hodor-api.git` → owner `callumwk`, repo `hodor-api`

Call `mcp__gitea__actions_config_write` with:
- `method`: `create_repo_variable`
- `owner`: `{GITEA_OWNER}`
- `repo`: `{GITEA_REPO}`
- `name`: `APPLICATION_ID`
- `value`: `{APPLICATION_ID}`

If the call fails because the variable already exists, retry with `method`: `update_repo_variable` (same other params).

Tell the user: "Set `APPLICATION_ID` = `{APPLICATION_ID}` as a Gitea Actions variable on `{GITEA_OWNER}/{GITEA_REPO}`."

If `{IN_GIT_REPO}` = `false` or the origin is not on `gitea.callumserver.com`, skip this step.

### 13. Optionally set up a CI/CD workflow

Ask: "Would you also like to set up a CI/CD workflow for this service? (y/n)"

Wait for reply.

- If **yes**: invoke the `dokploy-workflow` skill via the Skill tool. The `{APPLICATION_ID}` is already known from this session.
- If **no**: stop.
