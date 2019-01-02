FROM envoyproxy/envoy-alpine:latest

# Install Python, required libs and bash
RUN apk update && apk add python3 bash jq ca-certificates
RUN pip3 install --upgrade pip
RUN python3 --version && pip3 --version
RUN pip3 install -q Flask==1.0.2 requests==2.21.0

#Install Vault
RUN wget https://releases.hashicorp.com/vault/1.0.1/vault_1.0.1_linux_amd64.zip -O /tmp/vault.zip
RUN unzip /tmp/vault.zip -d /usr/local/bin

# Move code / scripts into the image
RUN mkdir /code
ADD ./service.py /code
ADD ./start_service.sh /usr/local/bin/start_service.sh
RUN chmod u+x /usr/local/bin/start_service.sh

ENTRYPOINT /usr/local/bin/start_service.sh