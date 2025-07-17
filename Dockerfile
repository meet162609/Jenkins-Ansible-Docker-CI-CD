FROM ubuntu:20.04
MAINTAINER meetparmar14790@gmail.com
 
ENV DEBIAN_FRONTEND=noninteractive
 
RUN apt update && \
    apt install -y tzdata apache2 zip unzip && \
    apt clean && \
    rm -rf /var/lib/apt/lists/*
 
# Download GitHub zip (you can rename it while downloading)
ADD https://github.com/StartBootstrap/startbootstrap-agency/archive/refs/heads/main.zip /var/www/html/site.zip

WORKDIR /var/www/html
 
RUN unzip site.zip && \
    cp -rvf startbootstrap-agency-main/* . && \
    rm -rf site.zip startbootstrap-agency-main
 
EXPOSE 80
CMD ["/usr/sbin/apache2ctl", "-D", "FOREGROUND"]
