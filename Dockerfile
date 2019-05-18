FROM golang AS builder

RUN apt-get update && apt-get install -y git bzr gcc build-essential libavahi-core-dev libcups2-dev libavahi-client-dev

RUN go get github.com/google/cloud-print-connector/gcp-cups-connector

FROM ubuntu:19.04
LABEL maintainer "Gavin Mogan <docker@gavinmogan.com>"

EXPOSE 631

RUN apt-get update \
      && apt-get install --no-install-recommends -y  -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" \
      cups \
      avahi-daemon \
      supervisor \
      brother-cups-wrapper-common \
      brother-cups-wrapper-extra \
      brother-cups-wrapper-laser \
      brother-cups-wrapper-laser1 \
      ca-certificates \
      && rm -rf /var/lib/apt/lists/* && \
      # Remove backends that don't make sense for container
      rm /usr/lib/cups/backend/parallel && \
      rm /usr/lib/cups/backend/serial && \
      rm /usr/lib/cups/backend/usb

RUN mkdir /config && \
    ln -s /config/printers.conf /etc/cups/printers.conf && \
    /etc/init.d/cups start && cupsctl --remote-admin --remote-any --share-printers --user-cancel-any && \
    sed -i 's/Listen localhost:631/Listen *:631/g' /etc/cups/cupsd.conf && \
    sed -i 's/DefaultAuthType Basic/DefaultAuthType None/g' /etc/cups/cupsd.conf && \
    sed -i 's/LogLevel warn/LogLevel warn/g' /etc/cups/cupsd.conf && \
    echo "ServerAlias *" >> /etc/cups/cupsd.conf && \
    sed -i 's/AccessLog .*/AccessLog stderr/g' /etc/cups/cups-files.conf && \
    sed -i 's/ErrorLog .*/ErrorLog stderr/g' /etc/cups/cups-files.conf && \
    sed -i 's/PageLog .*/PageLog stderr/g' /etc/cups/cups-files.conf

COPY --from=builder /go/bin/gcp-cups-connector /usr/bin/gcp-cups-connector
COPY ./supervisord.conf /etc/supervisord.conf

#CMD ["/bin/sh", "-c", "/usr/sbin/cupsd -f"]
CMD ["supervisord","-c","/etc/supervisord.conf"]
