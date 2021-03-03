FROM ubuntu

RUN apt-get update && apt upgrade -y && \
	apt install openssl vim tcpdump -y

VOLUME ["/broker/data", "/broker/log"]

# Set up the entry point script and default command
COPY ./sub_flood_config.conf ./broker/
COPY ./pub_flood_config.conf ./broker/
COPY ./sub_flood_broker ./broker/
COPY ./sub_flood_broker_v2 ./broker/
COPY ./pub_flood_broker ./broker/

EXPOSE 1883
# ENTRYPOINT ["./docker-entrypoint.sh"]
ENTRYPOINT ["/bin/bash"]
