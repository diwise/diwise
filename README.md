# diwise

Main repository for diwise

## How to run

### docker compose

The docker compose environment assumes that you have modified your hosts file to add local DNS entries for diwise.local and iam.diwise.local. See Preparations below for instructions on how to do this.

Start a composed environment using docker compose with the following command.

`docker compose -f deployments/docker/docker-compose.yaml up`

The services will start, but with MQTT disabled. How to change the configuration to start consuming data over MQTT is currently left as an exercise for the reader.

Data packets can be ingested using curl or another tool of your choice by posting data to http://127.0.0.1:8090/api/v0/messages. More documentation about how this can be used will be added soon.

To cleanup your environment after testing, run

`docker compose -f deployments/docker/docker-compose.yaml down -v --remove-orphans`

#### Preparations

MacOSX:

Edit your /private/etc/hosts file to include the two lines:

```
127.0.0.1 diwise.local
127.0.0.1 iam.diwise.local
```

Then invoke the following command to allow the mappings to take effect:

```
sudo killall -HUP mDNSResponder
```

### Code Ready Containers

**TODO**

### Kubernetes

**TODO**
