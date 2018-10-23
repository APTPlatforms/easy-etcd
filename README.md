# easy-etcd

### Docker Image

[![](https://images.microbadger.com/badges/image/aptplatforms/easy-etcd:latest.svg)](https://microbadger.com/images/aptplatforms/easy-etcd:latest) [![](https://img.shields.io/docker/automated/aptplatforms/easy-etcd.svg)](https://hub.docker.com/r/aptplatforms/easy-etcd/builds/) [![](https://img.shields.io/docker/pulls/aptplatforms/easy-etcd.svg)](https://hub.docker.com/r/aptplatforms/easy-etcd/) [![](https://img.shields.io/docker/stars/aptplatforms/easy-etcd.svg)](https://hub.docker.com/r/aptplatforms/easy-etcd/)

This repository provides an easy way to deploy
[etcd](https://github.com/coreos/etcd) as Docker containers or as standalone
processes.

## Docker deployment with [docker-compose](https://docs.docker.com/compose/)

The provided [`docker-compose.sample.yml`](./docker-compose.sample.yml) file demonstrates how to quickly
deply a 3-node cluster. This sample will run as configured. If you're running
in a [Rancher](https://rancher.com/) environment, take advantage of host
affinity. Just edit the values in the `affinity` labels to match your
environment.

To start a 3-node sample cluster:

    docker-compose -f docker-compose.sample.yml up -d

Note: This sample is meant for development or demonstration purposes only, as
it does not build a robust cluster across multiple Docker hosts. Using
affinity labels, you can very easily create a robust cluster.

## Deploying an etcd cluster manually with Docker

All data is stored in /data. `ETCD_DATA_DIR=/data` is set when the image is built.
You'll want to map a persistent volume to `/data`.

To deploy the first etcd node:

    docker run -d --name infra0 -p 2379:2379 -p 2380:2380 -e ETCD_NAME=infra0 -v /data aptplatforms/easy-etcd

Alternatively, you can deploy the node without mapped ports, so then the
service can only be accessed from inside the Docker network:

    docker run -d --name infra0 -e ETCD_NAME=infra0 -v /data aptplatforms/easy-etcd

Find the internal IP address of the first etcd node.

    docker inspect --format='{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' infra0
    > 172.17.0.2

Deploy second and subsequent nodes as follows. The only difference is the
presence of the `CLUSTER_LEAD` variable.

    docker run -d --name infra1 -p 2379:2379 -p 2380:2380 -e CLUSTER_LEAD=172.17.0.2 -v /data aptplatforms/easy-etcd

You repeat the above command to add as many more nodes as you want!

Remember that the whole point of having a cluster is to avoid failure, so make
sure you use multiple Docker hosts. Having all etcd nodes in the same Docker
host is not going to help if the host goes down.

## Deploying etcd without Docker

The [`boot.sh`](./boot.sh) script can be used to deploy etcd as a regular process. The
etcd service binaries must be installed before using this script.

To deploy the first etcd node:

    ETCD_NAME=infra0 ./boot.sh &

Assuming the `FIRST_ETCD_IP_ADDRESS` variable is set to the IP address of the
first etcd node, you can deploy a second node as follows:

    CLUSTER_LEAD=$FIRST_ETCD_IP_ADDRESS ETCD_NAME=infra1 ./boot.sh &

The script runs the service on the default 2379 and 2380 ports. If you want to
create more than one node in a host, you need to specify different ports for
the additional nodes:

    CLUSTER_LEAD=$FIRST_ETCD_IP_ADDRESS CLIENT_PORT=2479 PEER_PORT=2480 ./boot.sh &

You repeat the above command to add as many more nodes as you want!

## Reference

The [`boot script`](./boot.sh) accepts a number of options through environment
variables. Below is a complete list. If you want to tweak etcd further, see [etcd Configuration flags](https://coreos.com/etcd/docs/latest/op-guide/configuration.html).

Variable | Value
--- | ---
`ETCD_NAME` | The name to give to the etcd node. You'll thank yourself later for setting a reasonable `ETCD_NAME` on each node especially if you're running in Docker. Cluster data includes this name and gets very unfriendly if you teardown an instance and rebuild it with the same `ETCD_DATADIR`. Default: `$(hostname)`.
`ETCD_INITIAL_CLUSTER_TOKEN` | The name of the cluster. Default: `etcd-cluster-token`.
`CLUSTER_LEAD` | The IP address of an already running node in the cluster. If this variable is set, the new node joins the existing cluster. If this variable is not set, the node starts a new cluster. Default: `<empty>`.
`LISTEN_IP_ADDRESS` | The IP address where etcd listens for requests. Default: `0.0.0.0`.
`CLIENT_PORT` | The port number where etcd should listen to client requests. Default: `2379`.
`PEER_PORT` | The port number where etcd should listen to requests from peers.  Default: `2380`.
`ETCD_DATADIR` | The directory to store persistent data. Default: `/data`.

## Thanks

Thanks to [Miguel Grinberg](https://github.com/miguelgrinberg) for his
[easy-etcd](https://github.com/miguelgrinberg/easy-etcd). This is my
modification of his work. Mainly I was trying to learn more about etcd itself
by making changes to things that I didn't understand without DoingItMyself
while at the same time adding notes about Rancher and docker-compose
deployment.
