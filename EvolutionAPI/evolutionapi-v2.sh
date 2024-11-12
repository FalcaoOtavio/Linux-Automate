#!/bin/bash

echo "### Configuração da API Evolution com PostgreSQL ###"

# Confirmação do usuário para instalação da EvolutionAPI
read -p "Você deseja instalar a EvolutionAPI v2? (s/n - Enter para sim): " confirm
if [[ -z "$confirm" || "$confirm" =~ ^[sS\s]$ ]]; then
  echo "Instalação confirmada pelo usuário."
else
  echo "Instalação cancelada pelo usuário."
  exit 1
fi

# Verifica se o Docker está instalado
if ! command -v docker &> /dev/null; then
  echo "Docker não está instalado."
  install_docker=true
else
  echo "Docker já está instalado na versão $(docker --version | awk '{print $3}' | tr -d ',')."
  read -p "Deseja atualizar o Docker para a versão mais recente? (s/n - Enter para sim): " update_docker
  if [[ -z "$update_docker" || "$update_docker" =~ ^[sS\s]$ ]]; then
    install_docker=true
  else
    install_docker=false
  fi
fi

# Instalação ou atualização do Docker e Docker Compose
if [[ "$install_docker" == true ]]; then
  echo "### Instalando ou atualizando Docker e Docker Compose ###"

  # Atualize o sistema
  sudo apt update
  sudo apt upgrade -y

  # Remova versões antigas do Docker, se existirem
  sudo apt remove docker docker-engine docker.io containerd runc -y

  # Instale dependências
  sudo apt install apt-transport-https ca-certificates curl software-properties-common -y

  # Adicione o repositório oficial do Docker
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

  # Instale o Docker
  sudo apt update
  sudo apt install docker-ce docker-ce-cli containerd.io -y

  # Verifique a instalação do Docker
  sudo systemctl enable docker
  sudo systemctl start docker
  echo "Docker instalado na versão: $(docker --version | awk '{print $3}' | tr -d ',')"

  # Adicione o usuário ao grupo docker (opcional)
  sudo usermod -aG docker ${USER}

  # Instale ou atualize o Docker Compose
  sudo curl -L "https://github.com/docker/compose/releases/download/$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep -Po '"tag_name": "\K.*?(?=")')/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
  sudo chmod +x /usr/local/bin/docker-compose
  echo "Docker Compose instalado na versão: $(docker-compose --version | awk '{print $3}')"
else
  echo "### Docker e Docker Compose já estão atualizados ###"
fi

echo "Instalação do Docker e Docker Compose concluída!"

# Variáveis padrão para o PostgreSQL
DB_USER="evolution_user"
DB_PASSWORD="evolution_password"
DB_NAME="evolution_db"

# Solicita as informações do usuário apenas para variáveis essenciais
read -p "Digite a porta para expor a API Evolution (ex: 8080): " API_PORT
read -p "Digite o URL do servidor para a API Evolution (ex: http://localhost): " SERVER_URL
read -p "Digite a chave de autenticação da API (Senha para acessar a EvolutionAPI): " AUTHENTICATION_API_KEY

# Cria um arquivo docker-compose.yml com as informações fornecidas e as variáveis padrão
cat <<EOF > docker-compose.yml
version: "3.7"

services:
  evolution_v2:
    image: atendai/evolution-api:v2.1.1
    volumes:
      - evolution_instances:/evolution/instances
    networks:
      - network_public
    ports:
      - "${API_PORT}:8080"
    environment:
      - SERVER_URL=${SERVER_URL}:${API_PORT}
      - DEL_INSTANCE=true
      - DATABASE_ENABLED=true
      - DATABASE_PROVIDER=postgresql
      - DATABASE_CONNECTION_URI=postgresql://${DB_USER}:${DB_PASSWORD}@postgres:5432/${DB_NAME}
      - DATABASE_SAVE_DATA_INSTANCE=true
      - DATABASE_SAVE_DATA_NEW_MESSAGE=true
      - DATABASE_SAVE_MESSAGE_UPDATE=true
      - DATABASE_SAVE_DATA_CONTACTS=true
      - DATABASE_SAVE_DATA_CHATS=true
      - DATABASE_SAVE_DATA_LABELS=true
      - DATABASE_SAVE_DATA_HISTORIC=true
      - DATABASE_CONNECTION_CLIENT_NAME=evolution_v2
      - RABBITMQ_ENABLED=false
      - CACHE_REDIS_ENABLED=false
      - AUTHENTICATION_API_KEY=${AUTHENTICATION_API_KEY}
    deploy:
      mode: replicated
      replicas: 1
      placement:
        constraints:
          - node.hostname == evolution-manager

  postgres:
    image: postgres:latest
    environment:
      POSTGRES_USER: ${DB_USER}
      POSTGRES_PASSWORD: ${DB_PASSWORD}
      POSTGRES_DB: ${DB_NAME}
    networks:
      - network_public
    volumes:
      - postgres_data:/var/lib/postgresql/data

volumes:
  evolution_instances:
    external: true
    name: evolution_v2_data
  postgres_data:
    driver: local

networks:
  network_public:
    external: true
    name: network_public
EOF

# Inicia os containers usando Docker Compose
echo "### Iniciando os serviços com Docker Compose ###"
docker-compose up -d

# Verifica se os serviços estão rodando corretamente
if [ $? -eq 0 ]; then
  echo "### Serviços iniciados com sucesso ###"
  echo "Acesse a API Evolution em ${SERVER_URL}:${API_PORT}"
  echo "Sua API Key (Senha) é ${AUTHENTICATION_API_KEY}"
else
  echo "### Ocorreu um erro ao iniciar os serviços ###"
fi
