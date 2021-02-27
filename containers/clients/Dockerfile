FROM ubuntu

RUN apt-get update && apt upgrade -y && \
	apt install libmosquitto-dev vim tcpdump -y

VOLUME ["/client/data", "/client/log"]

# Set up the entry point script and default command
COPY ./publisher ./client/
COPY ./subscriber ./client/

EXPOSE 1883
# ENTRYPOINT ["./docker-entrypoint.sh"]
ENTRYPOINT ["/bin/bash"]
