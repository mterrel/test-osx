---
title: "Fixing DNS timeouts in Docker"
author: Mark Terrel
authorTitle: Co-founder, Unbounded Systems
authorURL: https://twitter.com/mterrel
authorTwitter: mterrel
authorImageURL: /img/profiles/mark.jpg
image: blog/assets/lukas-blazek-UAvYasdkzq8-unsplash.jpg
description: "How we debugged and fixed DNS issues in our CI testing with a Docker DNS cache -- with code!"
---

![Alarm clock](assets/lukas-blazek-UAvYasdkzq8-unsplash.jpg)

<p class="photocredit">Photo by <a href="https://unsplash.com/@goumbik">Lukas Blazek</a> on <a href="https://unsplash.com/">Unsplash</a></p>

Having flaky tests in in your CI is a nightmare.
You can't tell whether your new code broke something or if it's just those tests being flaky again.
So anytime we see strange, random failures in CI for our open source project, Adapt, we try to track down the culprit ASAP.
This is the story of how we discovered we were (accidentally) flooding our DNS server with traffic and how we used a DNS cache in Docker to solve the problem.

<!-- truncate -->

## Background

Our open source project, [Adapt](https://adaptjs.org), makes it easy to create and deploy full-stack apps, using [React](https://reactjs.org).
Adapt can deploy apps into multiple clouds and technologies, so we do a ton of system testing and end-to-end testing with Docker, Kubernetes, AWS, Google Cloud and other similar technologies.

We make heavy use of Docker in our tests, so we end up creating lots of short-lived containers that start up, do some work, like building or installing an app, and then get deleted.
And as we added more and more of those tests, we started seeing previously stable system tests fail randomly in CI.

## The symptom: test timeouts

The first symptoms we saw were test timeouts.
We have fairly short timeouts on many of our end-to-end tests so we can detect if new code suddenly makes things take longer for end users.
But now, a test that should normally take a half second would **sometimes** take 5.5 seconds.

The additional 5 seconds was a great clue--5 seconds sounded like it could be a timeout of some kind.
Armed with that hunch, we looked back through all the seemingly random test failures and found the common thread: they were all tests that initiated network requests.
We also noticed a few tests that had taken even longer to fail...always in increments of 5 seconds.

There weren't too many network protocols that could be involved here, so some quick Googling pointed us in the right direction.
The default timeout for DNS server queries on Linux just [happens to be 5 seconds](https://linux.die.net/man/5/resolv.conf).

To see what was going on with DNS, we reached for probably the single most important tool for debugging network issues on Linux: [tcpdump](https://www.tcpdump.org/).
(Or, if you prefer a GUI version, [wireshark](https://www.wireshark.org/) is great too.)
We ran tcpdump on the host system (an Amazon Workspaces Linux instance) and used a filter to see the DNS traffic:

```console
$ tcpdump -n -i eth1 port 53
11:35:59.474735 IP 172.16.0.131.54264 > 172.16.0.119.domain: 64859+ AAAA? registry-1.docker.io. (38)
11:35:59.474854 IP 172.16.0.131.49631 > 172.16.0.119.domain: 43524+ A? registry-1.docker.io. (38)
11:35:59.476871 IP 172.16.0.119.domain > 172.16.0.131.49631: 43524 8/0/1 A 34.197.189.129, A 34.199.40.84, A 34.199.77.19, A 34.201.196.144, A 34.228.211.243, A 34.232.31.24, A 52.2.186.244, A 52.55.198.220 (177)
11:35:59.476957 IP 172.16.0.119.domain > 172.16.0.131.54264: 64859 0/1/1 (133)
```

The first thing that we noticed was that we were generating a huge flood of DNS queries to the AWS default DNS server for our VPC.
It looked like all those short-lived containers tended to do a bunch of DNS lookups when starting up, for various reasons.
Next, we noticed that some of those DNS queries just went unanswered.

It's pretty common for shared DNS servers to implement rate limits so that a single user can't degrade performance for everyone else.
Here, we suspected that the AWS DNS servers were doing exactly that.
We weren’t able to find a way to confirm whether we were actually hitting AWS rate limits, but it seemed wise for us not to DoS our DNS server.

## The solution: a Docker DNS cache, using dnsmasq

In order to isolate DNS traffic within the host, we needed a local DNS server to act as a cache.
A great choice for a cache like this is [dnsmasq](http://www.thekelleys.org.uk/dnsmasq/doc.html).
It’s reliable, widely used, and super simple to set up.
And since all of our testing runs inside Docker containers, it made sense to run the DNS server in Docker too.

The basic idea is pretty simple: run a dnsmasq container as the DNS cache on the Docker host network and then run our test containers with the [--dns option](https://docs.docker.com/engine/reference/run/#network-settings) pointing to the cache container’s IP address.

Here’s the `dns_cache` script that starts the DNS cache container:

```bash
#!/usr/bin/env bash

: "${IMAGE:=andyshinn/dnsmasq:2.76}"
: "${NAME:=dnsmasq}"
: "${ADAPT_DNS_IP_FILE:=/tmp/adapt_dns_ip}"

# Get IP address for an interface, as visible from inside a container
# connected to the host network
interfaceIP() {
    # Run a container and get ifconfig output from inside
    # We need the ifconfig that will be visible from inside the dnsmaq
    # container
    docker run --rm --net=host busybox ifconfig "$1" 2>/dev/null | \
        awk '/inet /{print(gensub(/^.*inet (addr:)?([0-9.]+)\s.*$/, "\\2", 1))}'
}

if docker inspect --type container "${NAME}" >& /dev/null ; then
    if [ -f "${ADAPT_DNS_IP_FILE}" ]; then
        # dnsmasq is already started
        cat "${ADAPT_DNS_IP_FILE}"
        exit 0
    else
        echo DNS cache container running but file ${ADAPT_DNS_IP_FILE} does not exist. >&2
        exit 1
    fi
fi

# We only support attaching to the default (host) bridge named "bridge".
DOCKER_HOST_NETWORK=bridge

# Confirm that "bridge" is the default bridge
IS_DEFAULT=$(docker network inspect "${DOCKER_HOST_NETWORK}" --format '{{(index .Options "com.docker.network.bridge.default_bridge")}}')
if [ "${IS_DEFAULT}" != "true" ]; then
    echo Cannot start DNS cache. The Docker network named \"${DOCKER_HOST_NETWORK}\" does not exist or is not the default bridge. >&2
    exit 1
fi

# Get the Linux interface name for the bridge, typically "docker0"
INTF_NAME=$(docker network inspect "${DOCKER_HOST_NETWORK}" --format '{{(index .Options "com.docker.network.bridge.name")}}')
if [ -z "${INTF_NAME}" ]; then
    echo Cannot start DNS cache. Unable to determine default bridge interface name. >&2
    exit 1
fi

# Get the IP address of the bridge interface. This is the address that
# dnsmasq will listen on and other containers will send DNS requests to.
IP_ADDR=$(interfaceIP "${INTF_NAME}")
if [ -z "${IP_ADDR}" ]; then
    echo Cannot start DNS cache. Docker bridge interface ${INTF_NAME} does not exist. >&2
    exit 1
fi

# Run the dnsmasq container. The hosts's /etc/resolv.conf configuration will
# be used by dnsmasq to resolve requests.
docker run --rm -d --cap-add=NET_ADMIN --name "${NAME}" --net=host -v/etc/resolv.conf:/etc/resolv.conf "${IMAGE}" --bind-interfaces --listen-address="${IP_ADDR}" --log-facility=- > /dev/null
if [ $? -ne 0 ]; then
    echo Cannot start DNS cache. Docker run failed.
    exit 1
fi

# Remember what IP address to use as DNS server, then output it.
echo ${IP_ADDR} > "${ADAPT_DNS_IP_FILE}"
echo ${IP_ADDR}
```

In addition to starting the container (if it’s not already running), the script outputs the cache container’s IP address.
We’ll use that on the command line of any other containers we start.
The script also ensures that dnsmasq only listens for DNS requests within Docker (on the Docker bridge interface), so there’s a little additional work to determine the IP address to listen on.

Here’s an example of how to start the DNS cache, remembering the IP address in variable `DNS_IP` and then running another container that will use the cache.

```console
$ DNS_IP=$(dns_cache)
$ docker run --dns ${DNS_IP} --rm busybox ping -c1 adaptjs.org
```

## Verifying the cache works

After we started using the cache in our testing, the number of DNS queries that the host system sent to the AWS DNS server dropped to a small trickle.
We also confirmed that the cache was operating properly by checking the dnsmasq statistics.
Sending a `SIGUSR1` to dnsmasq causes it to [print statistics to its log](http://www.thekelleys.org.uk/dnsmasq/docs/dnsmasq-man.html):

```console
$ docker kill -s USR1 dnsmasq
$ docker logs dnsmasq
dnsmasq[1]: cache size 150, 1085/4664 cache insertions re-used unexpired cache entries.
dnsmasq[1]: queries forwarded 1712, queries answered locally 3940
dnsmasq[1]: queries for authoritative zones 0
dnsmasq[1]: server 172.16.0.119#53: queries sent 1172, retried or failed 0
dnsmasq[1]: server 172.16.1.65#53: queries sent 252, retried or failed 0
dnsmasq[1]: server 172.16.0.2#53: queries sent 608, retried or failed 0
```

And most importantly, we saw a dramatic decrease in system test timeouts and our CI runs stabilized.

This issue took us a while to track down.
But keeping CI healthy is extremely important.
If you have too many sporadic test failures, developers tend to ignore CI results and push potentially broken code.

So, even though it was time consuming to track down these failures, given the ease of the fix, it was definitely worth the investment.
