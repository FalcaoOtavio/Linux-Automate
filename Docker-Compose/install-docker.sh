#!/bin/bash

# Atualize o sistema
sudo apt update
sudo apt upgrade -y

# Instale dependências
sudo apt install apt-transport-https ca-certificates curl software-properties-common -y

# Adicione o repositório oficial do Docker
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Instale o Docker
sudo apt update
sudo apt install docker-ce docker-ce-cli containerd.io  docker -y

# Verifique a instalação do Docker
sudo systemctl enable docker
sudo docker --version

# Adicione o usuário ao grupo docker (opcional)
sudo usermod -aG docker ${USER}

# Instale o Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/download/$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep -Po '"tag_name": "\K.*?(?=")')/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Verifique a instalação do Docker Compose
docker-compose --version

echo "Instalação concluída!"