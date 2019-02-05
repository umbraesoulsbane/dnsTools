FROM lucee/lucee52:latest

ENV APP_DIR="/var/www"

COPY ./srv/lucee/conf/catalina.properties /usr/local/tomcat/conf/catalina.properties
COPY ./srv/lucee/conf/server.xml /usr/local/tomcat/conf/server.xml
COPY ./srv/lucee/conf/web.xml /usr/local/tomcat/conf/web.xml
COPY ./srv/lucee/conf/lucee-server.xml /opt/lucee/server/lucee-server/context/lucee-server.xml
COPY ./srv/lucee/conf/lucee-web.xml.cfm /opt/lucee/web/lucee-web.xml.cfm

RUN apt-get update && apt-get install -yq dnsutils && apt-get install -yq whois && apt-get clean && rm -rf /var/lib/apt/lists/* 

EXPOSE 8888