# A DNSMasq image that helps routing DNS queries for specific domain to specific
# nameservers... and all the rest to nameservers of your choice :)
FROM alpine:latest
MAINTAINER Étienne Lafarge <etienne.lafarge@gmail.com>

RUN apk add --update dnsmasq && \
      rm -rf /var/cache/apk/*

ADD ./dnsmasq.conf /etc/dnsmasq.conf
ADD ./entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
CMD ["/usr/sbin/dnsmasq", "-C", "/etc/dnsmasq.conf", "-d"]
