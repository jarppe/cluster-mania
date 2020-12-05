#!/bin/bash

echo "$(date '+%Y/%m/%d %T') - Setup started" > /var/log/startup.log

adduser --disabled-password --gecos "" jarppe

BUCKET=cluster-maniaz
gsutil cp "gs://${BUCKET}/init/zshenv"     /home/jarppe/.zshenv
gsutil cp "gs://${BUCKET}/init/zshrc"      /home/jarppe/.zshrc

echo "$(date '+%Y/%m/%d %T') - Install tools" >> /var/log/startup.log

apt -qq update
apt -qq install -y wget                    \
                   curl                    \
                   ca-certificates         \
                   net-tools               \
                   httpie                  \
                   jq                      \
                   zsh                     \
                   inetutils-ping          \
                   tcptraceroute           \
                   socat                   \
                   mtr                     \
                   gnupg                   \
                   gnupg-agent             \
                   postgresql-client       \
                   exa                     \
                   direnv                  \
                   kubectl                 \
                   kubectx

chsh --shell /bin/zsh jarppe

echo "$(date '+%Y/%m/%d %T') - Setup done" >> /var/log/startup.log
