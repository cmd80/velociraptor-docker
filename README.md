# Velociraptor Docker Container

This directory contains everything needed to build and run a Velociraptor server inside Docker. Velociraptor is an open‐source, cross‐platform collection agent for incident response and forensic investigations.

## Quick Start

The simplest way to launch the server is with Docker Compose:

```bash
 docker-compose up
```

The compose file pulls the latest image from the GitHub Container Registry, generates a default configuration, and starts the container. The GUI will be reachable at `https://<HOSTNAME>:8889/` (default password `password`).

You can override the default password by editing the `.env` file (see below).

## Server binary update script

### What the script does

The `download_velociraptor_bins.sh` script fetches the latest Velociraptor release (currently version 0.76.5) for all supported platforms (Linux x86_64, Linux ARM64, macOS x86_64, macOS ARM64, Windows x86_64, Windows 386) and places the binaries in the repository’s `bin/` directory. It then scans key configuration files (`entrypoint`, `init.vql`, `.env`, `custom_artifacts/InitializeServer.yaml`) and updates any hard–coded references to older binary names, ensuring that the container starts with the correct, freshly‐downloaded executables. The script is idempotent – running it again will simply replace the binaries with the same version and keep all references consistent.

### How to use

```bash
 chmod +x download_velociraptor_bins.sh   # first run only
 ./download_velociraptor_bins.sh
```

After the script finishes, rebuild the Docker image and restart the server:

```bash
 make build        # or: docker build -t velociraptor-server .
 docker-compose up   # or: make run
```

The script can be re’run whenever a new Velociraptor version is released to keep the container up’to’date automatically.

## Build and Run with Makefile (optional)

The repository includes a `Makefile` with convenience shortcuts that wrap the same Docker commands used by Compose:

| Target                | Description                                                                      |
|-----------------------|----------------------------------------------------------------------------------|
| `make build`          | Builds the Docker image (`docker build -t velociraptor-server .`).                |
| `make run`            | Runs the container with the ports and volume mounts defined in the Makefile.      |
| `make kill`           | Stops and removes the running container.                                         |
| `make clean_datastore`| Removes all files under the `datastore/` directory (use with caution).            |

These targets are **optional** – the project works perfectly with `docker-compose up` alone.

## Directory Layout

```text
 .
├─ etc/                # Holds the generated server.config.yaml
├─ datastore/          # Persistent storage for cases, artifacts, logs, etc.
├─ custom_artifacts/   # Optional pre‐built packages (MSI, DEB, RPM)
├─ bin/                # Velociraptor binaries for various OS/arch
├─ Dockerfile          # Minimal Alpine‐based image
├─ init.vql            # VQL script executed on container start to bootstrap the server
├─ docker-compose.yaml # Full Compose definition (used by `docker-compose up`)
├─ Makefile            # Convenience wrappers around Docker commands
└─ README.md           # This file
```

## Key Files

- **Dockerfile** – builds a lightweight Alpine‐based image and copies the entrypoint, init script, and custom artifacts.
- **init.vql** – a Velociraptor VQL script that creates an admin user, generates the configuration file, and registers default artifacts.
- **`.env`** – environment variable file read by `docker-compose` and the entrypoint; contains hostnames, ports, passwords, and other defaults.
- **Makefile** – optional shortcuts for building, running, stopping, and cleaning the datastore.
- **custom_artifacts/** – place any pre‐built Velociraptor packages (e.g., MSI, DEB, RPM) here; they are automatically registered on startup.

## Configuration

The server reads its configuration from `/etc/velociraptor/server.config.yaml`. On first start, `init.vql` generates a default configuration file there using values from environment variables or the default `.env` file.

You can provide your own configuration by copying it into the `etc/` directory before `docker-compose up`. If a configuration already exists, the container will skip the auto–generation step (controlled by the `VELOCIRAPTOR_NO_INITIALIZE` variable).

## Environment Variables

| Variable                     | Description                                                               | Default                         |
|------------------------------|---------------------------------------------------------------------------|---------------------------------|
| `VELOCIRAPTOR_HOSTNAME`      | Hostname clients use to connect. Must be reachable from clients.           | `localhost` (changed in `.env` to `100.64.0.3`) |
| `VELOCIRAPTOR_FRONTEND_PORT` | Port for the front‐end API (used by clients).                           | `8000`                          |
| `VELOCIRAPTOR_GUI_PORT`      | Port for the web GUI.                                                       | `8889`                          |
| `VELOCIRAPTOR_DATASTORE_PATH`| Path inside the container where the datastore is mounted.                   | `/datastore/`                   |
| `VELOCIRAPTOR_CONFIG_PATH`   | Path to the server configuration file.                                      | `/etc/velociraptor/server.config.yaml` |
| `VELOCIRAPTOR_INITIAL_ADMIN_USER` | Initial admin username.                                               | `admin`                         |
| `VELOCIRAPTOR_INITIAL_ADMIN_PASSWORD` | Initial admin password.                                               | `password` (or `password` in `.env`) |
| `VELOCIRAPTOR_ORGNAME`       | Organization name used for generated artifacts.                             | `root`                          |
| `VELOCIRAPTOR_NO_INITIALIZE` | If set to `TRUE`, skips creation of default packages.                       | *empty* (not set)               |
| `VELOCIRAPTOR_TOOLDIR`       | Directory where custom tool binaries are placed.                            | `/velobins`                     |

You can edit the `.env` file to change any of these values before starting the container.

## Persistent Datastore

The `datastore/` directory is mounted into the container at `/datastore/`. All cases, client artifacts, logs, and repositories are stored there. Terminating the container does **not** delete this data; you can safely restart the container later and the server will pick up where it left off.

If you need to reset the datastore, run:

```bash
 make clean_datastore
```

or manually remove the contents of `datastore/`.
A
## Custom Artifacts

Place any pre‐built Velociraptor packages (e.g., MSI, DEB, RPM) into the `custom_artifacts/` directory. These are automatically registered with the server on startup, making them available for immediate deployment.

## Stopping the Server

- If you started with `docker-compose up`, stop it with `docker-compose down` or `Ctrl–C` in the terminal.
- If you used the Makefile target `make kill`, it will send a `docker kill` and `docker rm` for the container named `velociraptor-server`.

## Troubleshooting

| Symptom                     | Check                                                                 |
|-----------------------------|-----------------------------------------------------------------------|
| GUI not reachable           | Verify that the ports (`8000` and `8889`) are not blocked by a firewall and that the container is running (`docker ps`). |
| Authentication fails        | Reset the admin password by editing the `.env` file or by recreating the datastore and restarting. |
| Container exits immediately | Look at the container logs (`docker logs velociraptor-server`) for errors in `init.vql` or missing binaries. |
| No packages appear          | Ensure files are placed in `custom_artifacts/` and that the directory is correctly mounted in the Dockerfile. |

## NOTICE

This repository contains original code, Docker configurations, automation scripts, and custom artifacts developed for use with Velociraptor.

Velociraptor is a separate project distributed under the AGPLv3 license and remains subject to its original licensing terms. This repository does not claim ownership of Velociraptor source code, binaries, or upstream assets, except where explicitly stated.

Files in this repository that are not part of Velociraptor are distributed under the AGPLv3 license unless otherwise noted in the individual file.

Use of this project implies compliance with the AGPLv3 license and, for any included or referenced Velociraptor components, the terms of the upstream project license.

