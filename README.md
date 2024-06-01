# soulmask-dedicated-server

[![Static Badge](https://img.shields.io/badge/DockerHub-blue)](https://hub.docker.com/r/sknnr/soulmask-dedicated-server) ![Docker Pulls](https://img.shields.io/docker/pulls/sknnr/soulmask-dedicated-server) [![Static Badge](https://img.shields.io/badge/GitHub-green)](https://github.com/jsknnr/soulmask-dedicated-server) ![GitHub Repo stars](https://img.shields.io/github/stars/jsknnr/soulmask-dedicated-server)


Run Soulmask dedicated server in a container. Optionally includes helm chart for running in Kubernetes.

**Disclaimer:** This is not an official image. No support, implied or otherwise is offered to any end user by the author or anyone else. Feel free to do what you please with the contents of this repo.
## Usage

The processes within the container do **NOT** run as root. Everything runs as the user steam (gid:10000/uid:10000 by default). If you exec into the container, you will drop into `/home/steam` as the steam user. Soulmask will be installed to `/home/steam/soulmask`. Any persistent volumes should be mounted to `/home/steam/soulmask` and be owned by 10000:10000. 

### Ports

Game ports are arbitrary. You can use which ever values you want above 1000. Make sure that you are port forwarding (DNAT) correctly to your instance and that firewall rules are set correctly.

| Port | Description | Protocol | Default |
| ---- | ----------- | -------- | --------|
| Game Port | Port for client connections, should be value above 1000 | UDP | 27050 |
| Query Port | Port for server browser queries, should be a value above 1000 | UDP | 27051 |

### Environment Variables

| Name | Description | Default | Required |
| ---- | ----------- | ------- | -------- |
| SERVER_NAME | Name for the Server | Enshrouded Containerized | False |
| GAME_MODE | Set server to either 'pve' or 'pvp' | None | True |
| SERVER_PASSWORD | Password for the server | None | False |
| ADMIN_PASSWORD | Password for GM admin on server | AdminPleaseChangeMe | False |
| SERVER_LEVEL | Level for server to load. Currently there is only 1 so no need to change | Level01_Main | False |
| GAME_PORT | Port for server connections | 27050 | False |
| QUERY_PORT | Port for steam query of server | 27051 | False |
| SERVER_SLOTS | Number of slots for connections (Max 70) | 50 | False |
| LISTEN_ADDRESS | IP address for server to listen on | 0.0.0.0 | False |

### Docker

To run the container in Docker, run the following command:

```bash
docker volume create soulmask-persistent-data
docker run \
  --detach \
  --name soulmask-server \
  --mount type=volume,source=soulmask-persistent-data,target=/home/steam/soulmask \
  --publish 27050:27050/udp \
  --publish 27051:27051/udp \
  --env=SERVER_NAME='Soulmask Containerized Server' \
  --env=GAME_MODE='pve' \
  --env=SERVER_SLOTS=50 \
  --env=SERVER_PASSWORD='PleaseChangeMe' \
  --env=ADMIN_PASSWORD='AdminPleaseChangeMe' \
  --env=GAME_PORT=27050 \
  --env=QUERY_PORT=27051 \
  --env=LISTEN_ADDRESS='0.0.0.0' \
  --stop-timeout 90 \
  sknnr/soulmask-dedicated-server:latest
```

### Docker Compose

To use Docker Compose, either clone this repo or copy the `compose.yaml` file out of the `container` directory to your local machine. Edit the compose file to change the environment variables to the values you desire and then save the changes. Once you have made your changes, from the same directory that contains the compose and the env files, simply run:

```bash
docker-compose up -d
```

To bring the container down:

```bash
docker-compose down --timeout 90
```

compose.yaml file:
```yaml
services:
  soulmask:
    image: sknnr/soulmask-dedicated-server:latest
    ports:
      - "27050:27050/udp"
      - "27051:27051/udp"
    env_file:
      - default.env
    volumes:
      - soulmask-persistent-data:/home/steam/soulmask
    stop_grace_period: 90s

volumes:
  soulmask-persistent-data:
```

default.env file:
```properties
SERVER_NAME="Soulmask Containerized"
GAME_MODE="pve"
SERVER_PASSWORD="ChangeMePlease"
ADMIN_PASSWORD="AdminChangeMePlease"
GAME_PORT="27050"
QUERY_PORT="27051"
SERVER_SLOTS="50"
LISTEN_ADDRESS="0.0.0.0"
```

### Podman

To run the container in Podman, run the following command:

```bash
podman volume create soulmask-persistent-data
podman run \
  --detach \
  --name soulmask-server \
  --mount type=volume,source=soulmask-persistent-data,target=/home/steam/soulmask \
  --publish 27050:27050/udp \
  --publish 27051:27051/udp \
  --env=SERVER_NAME='Soulmask Containerized Server' \
  --env=GAME_MODE='pve' \
  --env=SERVER_SLOTS=50 \
  --env=SERVER_PASSWORD='PleaseChangeMe' \
  --env=ADMIN_PASSWORD='AdminPleaseChangeMe' \
  --env=GAME_PORT=27050 \
  --env=QUERY_PORT=27051 \
  --env=LISTEN_ADDRESS='0.0.0.0' \
  --stop-timeout 90 \
  docker.io/sknnr/soulmask-dedicated-server:latest
```

### Quadlet
To run the container with Podman's new quadlet subsystem, make a file under (when running as root) /etc/containers/systemd/enshrouded.container containing:
```properties
[Unit]
Description=Soulmask Game Server

[Container]
Image=docker.io/sknnr/soulmask-dedicated-server:latest
Volume=soulmask-persistent-data:/home/steam/soulmask
PublishPort=27050-27051:27050-27051/udp
ContainerName=soulmask-server
Environment=SERVER_NAME="Soulmask Containerized"
Environment=GAME_MODE="pve"
Environment=SERVER_PASSWORD="ChangeMePlease"
Environment=ADMIN_PASSWORD="AdminChangeMePlease"
Environment=GAME_PORT="27050"
Environment=QUERY_PORT="27051"
Environment=SERVER_SLOTS="50"
Environment=LISTEN_ADDRESS="0.0.0.0"

[Service]
# Restart service when sleep finishes
Restart=always
# Extend Timeout to allow time to pull the image
TimeoutStartSec=900

[Install]
# Start by default on boot
WantedBy=multi-user.target default.target
```

### Kubernetes

I've built a Helm chart and have included it in the `helm` directory within this repo. Modify the `values.yaml` file to your liking and install the chart into your cluster. Be sure to create and specify a namespace as I did not include a template for provisioning a namespace.

## Troubleshooting

### Connectivity

If you are having issues connecting to the server once the container is deployed, I promise the issue is not with this image. You need to make sure that the ports 27050 UDP and 27051 UDP (or whichever ones you decide to use) are open on your router as well as the container host where this container image is running. You will also have to port-forward the game-port and query-port from your router to the private IP address of the container host where this image is running. After this has been done correctly and you are still experiencing issues, your internet service provider (ISP) may be blocking the ports and you should contact them to troubleshoot.

### Storage

I recommend having Docker or Podman manage the volume that gets mounted into the container. However, if you absolutely must bind mount a directory into the container you need to make sure that on your container host the directory you are bind mounting is owned by 10000:10000 by default (`chown -R 10000:10000 /path/to/directory`). If the ownership of the directory is not correct the container will not start as the server will be unable to persist the savegame.
