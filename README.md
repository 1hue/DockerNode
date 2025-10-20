# Dockerized Node.js local development environment

Isolate your Node.js processes.

This could be used for running a local dev server like Vite, Next.js or Nest.js.

<br/>

## Reasoning

Why do this?

Docker, especially in [rootless mode](https://docs.docker.com/engine/security/rootless/), allows for:

1. **Greater security**

   - Thousands of those NPM dependencies are now prevented from getting any glimpse of the host.

2. **Improved reproducibility**

   - Platform compatibility issues like environment variables on Windows vs UNIX.

   - Developers working on the app get the exact same result every time, no matter if they are running Windows, macOS or Linux.

<br/>

## Setup

Ensure [Docker Engine](https://docs.docker.com/engine/) and [Docker Compose](https://docs.docker.com/compose/) are set up. Refer to platform-specific instructions: https://docs.docker.com/engine/install

With Docker Desktop (GUI) your mileage may vary.

To verify, the following commands should print:

```sh
docker -v
docker compose version
```

Optionally, make the `./dev` [convenience](./dev "Acts as a docker compose shortcut so we don't have to type long commands every time") shell script runnable:

```sh
chmod +x ./dev
```

This will allow us to avoid typing the verbose `docker compose yada yada yada` every time we want to spin up our dev environment.

For the first run, we must enter shell in order to first set up NPM/PNPM/Yarn/Bun (e.g. install vite as a dep):

```sh
./dev bash
```

<br/>

## Environment variables

Create an `.env` or remove `env_file` in [`docker-compose.yml`](docker-compose.yml#L12C5-L13C13).

Alternatively, env vars can be hardcoded (or otherwise piped in):

```yml
environment:
  - DEBUG=${DEBUG}
```

> [!NOTE]
> Variables via docker-compose will be available _in the environment_ of the container, i.e. OS level.<br/>
> This is identical to how env vars would be available during a CI/CD build.<br />
> For development, prefer `.env` loaded via framework tooling with auto-refresh, e.g. Vite dev server.

See 💡 [Docker Docs](https://docs.docker.com/compose/how-tos/environment-variables/set-environment-variables/)

<br/>

## Port mapping

Specify `host:container` ports in [`docker-compose.yml`](docker-compose.yml#L10C5-L11C20).

If our node.js process inside the container runs on `5173` but we want to avoid clashing with something else on our host machine, we could map it like so: `5174:5173`.

See 💡 [Docker Docs](https://docs.docker.com/compose/how-tos/networking/)

<br/>

## Usage

|             Command | Description                                                                                                    |
| ------------------: | -------------------------------------------------------------------------------------------------------------- |
|             `./dev` | Start development. Runs [`docker-compose.yml:15`](docker-compose.yml#L15) and [`dev:docker`](package.json#L7). |
|        `./dev stop` | Stop container explicitly.                                                                                     |
|        `./dev bash` | Enter shell to execute commands inside the container.                                                          |
|        `./dev logs` | View rolling logs (if you've closed them).                                                                     |
| `./dev any-command` | Pass any command to be executed inside the container (instead of `bash`).                                      |

> [!IMPORTANT]
> Ensure the `./dev` script is chmoded.

<br/>

## Useful docker commands

```sh
# List
docker ps -a
docker volume ls
docker image ls

# Clean
docker builder prune --all --force
docker system prune --all --volumes --force
```

<br/>

## Isolating Node.js further

The repository root `.` (as in, current dir) is [mounted](docker-compose.yml#L7) as `/app` within the container using [`WORKDIR`](Dockerfile#L20).

This means that all files in the repository root are available to any node.js process. For example,`.env.prod` or other secrets.

> [!TIP]\
> [`WORKDIR`](https://docs.docker.com/reference/dockerfile/#workdir) mounts everything as a filesystem volume, granting us real-time two-way synchronization. Useful for actual development work.\
> [`COPY`](https://docs.docker.com/reference/dockerfile/#copy), in contrast, copies files over _once_ at container build-time and respects `.dockerignore`.

To completely isolate a node.js app, we can mount a subdirectory instead of root `.`:

```yml
volumes:
  - ./app:/app # host:container
```

We then place `package.json` under `app/` along with the rest of our application-specific sourceode.

<br/>

## Using with PNPM

Want to use PNPM or another package manager like Yarn or Bun?

Modify `Dockerfile` along these lines:

```dockerfile
# ...
WORKDIR /app

ENV COREPACK_ENABLE_DOWNLOAD_PROMPT=0
ENV PNPM_HOME=/usr/local/share/.pnpm-store
ENV PATH=$PNPM_HOME:$PATH

RUN mkdir -p $PNPM_HOME

RUN npm install -g npm@latest corepack@latest
RUN corepack enable pnpm
RUN corepack use pnpm@latest
```

Then, ensure that [`docker-compose.yml`](docker-compose.yml#L15) knows what to run by default:

```yml
command: >
  bash -c "pnpm i && pnpm dev:docker"
```
