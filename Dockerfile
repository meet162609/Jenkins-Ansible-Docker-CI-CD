FROM ubuntu:20.04
MAINTAINER meetparmar14790@gmail.com
 
ENV DEBIAN_FRONTEND=noninteractive
 
RUN apt update && \
    apt install -y tzdata apache2 zip unzip && \
    apt clean && \
    rm -rf /var/lib/apt/lists/*
 
# Download GitHub zip (you can rename it while downloading)
ADD https://github.com/cloudacademy/static-website-example/archive/refs/heads/master.zip /var/www/html/site.zip

WORKDIR /var/www/html

RUN apt update && apt install -y unzip && \
    unzip site.zip && \
    cp -rvf static-website-example-master/* . && \
    rm -rf site.zip static-website-example-master
    
EXPOSE 80
CMD ["/usr/sbin/apache2ctl", "-D", "FOREGROUND"]
