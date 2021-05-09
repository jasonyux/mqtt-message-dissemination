FROM ubuntu

RUN apt-get update && apt upgrade -y && \
	apt install libmosquitto-dev vim tcpdump -y

VOLUME ["/client/data", "/client/log"]

# Set up the entry point script and default command
COPY ./client_program/publisher* ./client/
COPY ./client_program/subscriber* ./client/

EXPOSE 1883
# ENTRYPOINT ["./docker-entrypoint.sh"]
ENTRYPOINT ["/bin/bash"]
