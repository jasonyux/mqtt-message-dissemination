FROM ubuntu

RUN apt-get update && apt upgrade -y && \
	apt install openssl vim tcpdump -y

VOLUME ["/broker/data", "/broker/log"]

# Set up the entry point script and default command
COPY ./sub_flood_* /broker/
COPY ./pub_flood_* /broker/

EXPOSE 1883
# ENTRYPOINT ["./docker-entrypoint.sh"]
ENTRYPOINT ["/bin/bash"]
