[![codecov](https://codecov.io/gh/alpindale/pygbooru/branch/master/graph/badge.svg)](https://codecov.io/gh/alpindale/pygbooru) [![Discord](https://img.shields.io/discord/310432830138089472?label=Discord)](https://discord.gg/pygmalionai)


Forked from [danbooru](https://github.com/danbooru/danbooru)

## Quickstart

Run this to start a basic Danbooru instance:

```sh
curl -sSL https://raw.githubusercontent.com/alpindale/pygbooru/master/bin/pygbooru | sh
```

This will install [Docker Compose](https://docs.docker.com/compose/) and use it
to start Danbooru. When it's done, Danbooru will be running at http://localhost:3000.

Alternatively, if you already have Docker Compose installed, you can just do:

```sh
wget https://raw.githubusercontent.com/alpindale/pygbooru/master/docker-compose.yaml
docker-compose up
```

If you get an error such as `'name' does not match any of the regexes: '^x-'` make sure
that you're running an updated version of Docker Compose.

## Installation

See the [Docker Guide](https://github.com/danbooru/danbooru/wiki/Docker-Guide) for more information on running PygBooru using Docker. This is the recommended way to run PygBooru.

## Services

Danboou depends on a couple of cloud services and several microservices to
implement certain features.

### Amazon Web Services

The following features require an Amazon AWS account:

* Pool history
* Post history

### Google APIs

The following features require a Google Cloud account:

* BigQuery database export

### IQDB Service

IQDB integration is delegated to the [IQDB service](https://github.com/danbooru/iqdb).

### Archive Service

In order to access pool and post histories you will need to install and
configure the [Archives service](https://github.com/danbooru/archives).

### Reportbooru Service

The following features are delegated to the [Reportbooru service](https://github.com/danbooru/reportbooru):

* Post views
* Missed searches report
* Popular searches report

### Recommender Service

Post recommendations require the [Recommender service](https://github.com/danbooru/recommender).
