FROM nginx:1.18-alpine

USER root

ARG USER_ID
ARG GROUP_ID

RUN addgroup -g "$USER_ID" app \
 && adduser -G app -u "$GROUP_ID" -h /var/www -s /bin/bash -S app
RUN touch /var/run/nginx.pid
RUN mkdir /sock


RUN apt-get update
RUN apt-get upgrade -y
RUN apt-get install -y nano 

RUN apk add --no-cache \
  curl \
  nss-tools \
  openssl

RUN mkdir /etc/nginx/certs \
  && echo -e "\n\n\n\n\n\n\n" | openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /etc/nginx/certs/nginx.key -out /etc/nginx/certs/nginx.crt

ARG TARGETARCH

RUN cd /usr/local/bin/ \
  && curl -L https://github.com/FiloSottile/mkcert/releases/download/v1.4.3/mkcert-v1.4.3-linux-$TARGETARCH -o mkcert \
  && chmod +x mkcert

COPY ./conf/nginx.conf /etc/nginx/
COPY ./conf/default.conf /etc/nginx/conf.d/

RUN mkdir -p /etc/nginx/html /var/www/html \
  && chown -R app:app /etc/nginx /var/www /var/cache/nginx /var/run/nginx.pid /sock

EXPOSE 8443

USER app:app

VOLUME /var/www

WORKDIR /var/www/html