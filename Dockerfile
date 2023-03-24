FROM --platform=amd64 ubuntu:22.04 AS environment

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

RUN wget https://golang.org/dl/go1.18.4.linux-amd64.tar.gz
RUN sudo rm -rf /usr/local/go && sudo tar -C /usr/local -xzf go1.18.4.linux-amd64.tar.gz

RUN git clone https://github.com/multiversx/mx-chain-go.git
RUN git clone https://github.com/multiversx/mx-chain-proxy-go.git
RUN git clone https://github.com/multiversx/mx-chain-vm-go.git

RUN cd /home/ubuntu/mx-chain-go/cmd/seednode && sudo /usr/local/go/bin/go build -buildvcs=false .
RUN cd /home/ubuntu/mx-chain-go/cmd/node && sudo /usr/local/go/bin/go build -buildvcs=false .
RUN cd /home/ubuntu/mx-chain-proxy-go/cmd/proxy && sudo /usr/local/go/bin/go build -buildvcs=false .

RUN sudo chmod +x /home/ubuntu/mx-chain-go/cmd/node/node
RUN sudo chmod +x /home/ubuntu/mx-chain-go/cmd/seednode/seednode
RUN sudo chmod +x /home/ubuntu/mx-chain-proxy-go/cmd/proxy/proxy

RUN cp /home/ubuntu/mx-chain-vm-go/wasmer/libwasmer_linux_amd64.so /home/ubuntu/mx-chain-go/cmd/node/libwasmer_linux_amd64.so
RUN cp /home/ubuntu/mx-chain-vm-go/wasmer/libwasmer_linux_amd64.so /home/ubuntu/mx-chain-go/cmd/seednode/libwasmer_linux_amd64.so
RUN cp /home/ubuntu/mx-chain-vm-go/wasmer/libwasmer_linux_amd64.so /home/ubuntu/mx-chain-proxy-go/cmd/proxy/libwasmer_linux_amd64.so

RUN sudo wget -O mxpy-up.py https://raw.githubusercontent.com/multiversx/mx-sdk-py-cli/main/mxpy-up.py
RUN python3 mxpy-up.py --not-interactive --from-branch workaround-testnet-prebuild
ENV PATH="$PATH:/home/ubuntu/multiversx-sdk"

COPY testnet.toml .
RUN mxpy testnet prerequisites

RUN mxpy config set chainID local-testnet
RUN mxpy config set proxy http://localhost:7950
