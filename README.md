# diwise

Main repository for diwise

## How to run

### docker compose

The docker compose environment assumes that you have modified your hosts file to add local DNS entries for diwise.local and iam.diwise.local. See Preparations below for instructions on how to do this.

Start a composed environment using docker compose with the following command.

`docker compose -f deployments/docker/docker-compose.yaml up`

Data packets can be ingested using curl or another tool of your choice by posting data to https://diwise.local:8443/api/v0/messages.

To cleanup your environment after testing, run

`docker compose -f deployments/docker/docker-compose.yaml down -v --remove-orphans`

#### Configuration

On docker compose up, the services will start with MQTT disabled. The recommended way to add configuration parameters is to create a docker-compose.override.yaml file containing user or project specific settings/secrets that should not be pushed to the repo. For extra protection, this file name is added to the [.gitignore](.gitignore) file to reduce the likelihood that settings are pushed to GitHub.

An example configuration looks like this:

```
version: '3'
services:

  iot-agent:
    environment:
      MQTT_DISABLED: 'false'
      MQTT_HOST: 'your.mqtt.server'
      MQTT_USER: '<mqtt-user>'
      MQTT_PASSWORD: '<mqtt-password>'
      MQTT_TOPIC_0: '<mqtt-topic>'

```

And is merged with the default configuration by adding a -f argument to compose like so:

`docker compose -f deployments/docker/docker-compose.yaml -f deployments/docker/docker-compose.override.yaml up`

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

Windows:

Edit your C:\Windows\System32\drivers\etc\hosts file to include the two lines:

```
127.0.0.1 diwise.local
127.0.0.1 iam.diwise.local
```

### Code Ready Containers

**TODO**

### Kubernetes

**TODO**
