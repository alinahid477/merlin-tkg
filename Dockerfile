FROM debian:buster-slim


ENV DOCKER_VERSION=20.10.8

# culr (optional) for downloading/browsing stuff
# procps for ps aux to remove sshuttle background process as part of clean up
# openssh-client (required) for creating ssh tunnel
# psmisc (optional) I needed it to test port binding after ssh tunnel (eg: netstat -ntlp | grep 6443)
# nano (required) buster-slim doesn't even have less. so I needed an editor to view/edit file (eg: /etc/hosts) 
# jq for parsing json (output of az commands, kubectl output etc)
# unzip needed 
# sshuttle - "vpn" solution, route TCP traffic through ssh connection;
# sshpass - ssh password authentication (octopus does not accept ssh keys)
# libdigest-sha-perl - needed to carvel tool install
RUN apt-get update && apt-get install -y \
	apt-transport-https \
	ca-certificates \
	curl \
	procps \
    openssh-client \
	psmisc \
	nano \
	less \
	unzip \
	python2 \
	sshpass \
	iptables \
	sshuttle \
	net-tools \
	libdigest-sha-perl \
	&& curl -L https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl -o /usr/local/bin/kubectl \
	&& chmod +x /usr/local/bin/kubectl


RUN curl -o /usr/local/bin/jq -L https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64 && \
  	chmod +x /usr/local/bin/jq
RUN curl -o /usr/local/bin/yq -L https://github.com/mikefarah/yq/releases/download/v4.14.2/yq_linux_386 && \
	chmod +x /usr/local/bin/yq

RUN curl -fsSLO https://download.docker.com/linux/static/stable/x86_64/docker-${DOCKER_VERSION}.tgz \
  && tar xzvf docker-${DOCKER_VERSION}.tgz --strip 1 \
                 -C /usr/local/bin docker/docker \
  && rm docker-${DOCKER_VERSION}.tgz


RUN curl -L https://carvel.dev/install.sh | bash

COPY binaries/init.sh /usr/local/init.sh
RUN chmod +x /usr/local/init.sh

# COPY binaries/tmc /usr/local/bin/
# RUN chmod +x /usr/local/bin/tmc



ENTRYPOINT [ "/usr/local/init.sh"]