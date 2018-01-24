DNSMask proxy: send DNS requests for specific domains to specific rameservers
=============================================================================

This DNSMasq container can come in pretty handy when using multiple private
networks, with private DNS inside. It basically enables you to tell your
machine: "forward requests for all `*.mycompany.com` to this private server of
ours, `*.example.org` to this pool of DNS servers and all the rest to OpenNIC's
uncensored DNS servers (or Google's `8.8.8.8`/`8.8.4.4`, if you really want to).

NOTE: I just built a light DNSMasq docker image to simplify packaging and
configuration of a DNSMasq server and have strictly no credit for DNSMasq
itself. Also, this image is just leveraging the "DNS Server" feature of DNSMasq,
which is [much more than that](https://wiki.archlinux.org/index.php/dnsmasq).

NOTE2: DNSMasq simply routes dns queries to specific servers, to resolve
internal IPs on a remote cluster you'll need a VPN appliance such as OpenVPN,
Pritunl, Pertino...

NOTE3: We're using the last dnsmasq version from the `alpine:latest` repo, all
critical CVE fixes should be included ;-)

How to run this image ?
=======================

### Requirements
Just [docker](https://docs.docker.com/engine/installation/) :)

### With docker, directly.
You can run the docker image directly, with `--restart=always` so that it
survives reboots... however it won't survive your `docker rm -f $(docker ps
-aq)` (do not forget to update the `DNS_DOMAINS`, `NAMESERVERS` and
`DEFAULT_NAMESERVERS` env. variables to your use case):
```shell
docker run -d --restart=always --net=host --name=dnsmasq-proxy \
    -e SPECIFIC_NAMESERVERS="mycompany.com:10.0.0.53 example.org:192.168.0.53"  \
    -e DEFAULT_NAMESERVERS="185.121.177.177 185.121.177.53"  \
    elafarge/dnsmasq-proxy
```

DNSMasq will run a DNS reverse proxy of its own on your computer on port `53`,
read below to figure out how to route DNS queries from all your apps to this
local DNS reverse proxy.

#### A more resilient approach with systemd

If your Linux laptop runs systemd (that's the case of most Linux distribution
released in the past two years), you can let it start (on boot) and monitor your
DNSMasq container. Create an `/etc/systemd/system/dnsmasq-docker.service` file
and paste the following content (do not forget to update the `DNS_DOMAINS`,
`NAMESERVERS` and `DEFAULT_NAMESERVERS` env. variables to your use case):

```
[Unit]
Description=DNSMasq proxy
After=docker.service

[Service]
Type=simple
Restart=always
ExecStart=/usr/bin/docker run --restart=always --net=host --name=dnsmasq-proxy \
    -e SPECIFIC_NAMESERVERS="mycompany.com:10.0.0.53 example.org:192.168.0.53"  \
    -e DEFAULT_NAMESERVERS="185.121.177.177 185.121.177.53"  \
    elafarge/dnsmasq-proxy

[Install]
WantedBy=multi-user.target
```

To enable the service on boot, and start it right now:
```shell
sudo systemctl daemon-reload
sudo systemctl enable dnsmasq-docker.service
sudo systemctl start dnsmasq-docker.service
```

Such a setup should survive everything... even a `docker rm -f $(docker ps
-aq)`!

### Extra configuration for `/etc/resolv.conf`
Now you'll need to change your `/etc/resolv.conf` so that applications (Web
Browsers, docker, kubectl...) send their DNS queries to your dnsmasq container,
not your local network's DNS provider.

On most Linux distributions this can be done by editing your `/etc/resolv.conf`:
```
# Use your local dnsmasq server that forwards only the required
# requests to the kube-dns service.
nameserver 127.0.0.1
options timeout:1
```

On many systems, `/etc/resolv.conf` will be overriden when you connect to a new
network. To prevent this, here's the violent way to go:
```shell
sudo chattr +i /etc/resolv.conf    # Makes the file 100% read-only :o
```

The smooth way to go being to disable the daemon that overrides this file during
the DHCP process (when you connect your computer to a network, get your local IP
Address, your router will also give you the address of its internal DNS resolver
and this file is usually overriden). Don't disable the entire `dhcpcd` daemon
however, or you won't be able to retrieve an IP address and therefore, to
connect to most networks :D

NOTE: if you want to remove the write lock on `/etc/resolv.conf`:
```shell
sudo chattr -i /etc/resolv.conf    # Makes the file 100% read-only :o
```

### Check that it's working
First check that you can resolve any domain at all:
```
$ getent hosts kubernetes.io
23.236.58.218   kubernetes.io
```

Then, make sure that you can resolve your internal domains:
```
$ getent hosts mycompany.com
10.12.13.14   mycompany.com
```

Going further
-------------
 * [DNSMasq's official page](http://www.thekelleys.org.uk/dnsmasq/doc.html)

Maintainers:
------------
 * Étienne Lafarge <etienne.lafarge _at_ gmail.com>
