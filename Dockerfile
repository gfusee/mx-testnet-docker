FROM ubuntu:22.04 AS environment

ARG TARGETPLATFORM

SHELL ["/bin/bash", "-c"]

RUN apt update -y
RUN apt install sudo -y

RUN adduser --disabled-password --gecos '' ubuntu
RUN adduser ubuntu sudo
RUN echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers
USER ubuntu
WORKDIR /home/ubuntu

#mxpy setup
RUN sudo apt install build-essential -y
RUN sudo apt install software-properties-common -y
RUN sudo add-apt-repository ppa:deadsnakes/ppa -y
RUN sudo DEBIAN_FRONTEND=noninteractive apt install python3.10 -y
RUN sudo apt install python3-pip -y
RUN sudo apt install python3.10-venv -y
RUN sudo apt install git -y
RUN sudo apt install libncurses5 -y
RUN sudo apt install wget -y
RUN sudo apt install curl -y
RUN sudo apt install lsof -y

# Use a shell script or inline commands to conditionally run commands
RUN case ${TARGETPLATFORM} in \
         "linux/amd64") \
           wget https://golang.org/dl/go1.20.7.linux-amd64.tar.gz \
            && sudo rm -rf /usr/local/go && sudo tar -C /usr/local -xzf go1.20.7.linux-amd64.tar.gz ;; \
         "linux/arm64") \
           wget https://golang.org/dl/go1.20.7.linux-arm64.tar.gz \
           && sudo rm -rf /usr/local/go && sudo tar -C /usr/local -xzf go1.20.7.linux-arm64.tar.gz ;; \
         *) \
           echo "Unknown architecture: ${TARGETPLATFORM}" \
           && exit 1 ;; \
    esac

RUN git clone -b apple-arm64 https://github.com/multiversx/mx-chain-go.git --depth 1
RUN git clone https://github.com/multiversx/mx-chain-proxy-go.git --depth 1
RUN git clone -b apple-arm64 https://github.com/multiversx/mx-chain-vm-go.git --depth 1

RUN cd /home/ubuntu/mx-chain-go/cmd/seednode && sudo /usr/local/go/bin/go build -buildvcs=false .
RUN cd /home/ubuntu/mx-chain-go/cmd/node && sudo /usr/local/go/bin/go build -buildvcs=false .
RUN cd /home/ubuntu/mx-chain-proxy-go/cmd/proxy && sudo /usr/local/go/bin/go build -buildvcs=false .

RUN sudo chmod +x /home/ubuntu/mx-chain-go/cmd/node/node
RUN sudo chmod +x /home/ubuntu/mx-chain-go/cmd/seednode/seednode
RUN sudo chmod +x /home/ubuntu/mx-chain-proxy-go/cmd/proxy/proxy

RUN sudo pip install multiversx-sdk-cli
ENV PATH="$PATH:/home/ubuntu/multiversx-sdk"

COPY localnet.toml .
RUN mxpy localnet prerequisites
