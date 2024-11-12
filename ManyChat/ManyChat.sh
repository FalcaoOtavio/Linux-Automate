#######################################################

clear
echo -e "\e[32m\e[0m"
echo -e "\e[32m\e[0m"
echo -e "\e[32m\e[0m"
echo -e "\e[32m   _______                       _                   \e[0m"
echo -e "\e[32m  (_______)                     | |              _   \e[0m"
echo -e "\e[32m      _     _   _  ____   _____ | |__    ___   _| |_ \e[0m"
echo -e "\e[32m     | |   | | | ||  _ \ | ___ ||  _ \  / _ \ (_   _)\e[0m"
echo -e "\e[32m     | |   | |_| || |_| || ____|| |_) )| |_| |  | |_ \e[0m"
echo -e "\e[32m     |_|    \__  ||  __/ |_____)|____/  \___/    \__)\e[0m"
echo -e "\e[32m           (____/ |_|                                \e[0m"
echo -e "\e[32m\e[0m"
echo -e "\e[32m\e[0m"
echo -e "\e[32m\e[0m"
echo -e "\e[32m\e[0m"

sleep 3

#######################################################

# Perguntar os dados para o .env do Typebot
echo "Preencha as informações a seguir para criar o env do Typebot"
echo ""
read -p "Link do Builder (ex: typebot.seudominio.com): " builder
echo ""
read -p "Porta do Builder (padrão: 3001): " portabuilder
echo ""
read -p "Link do Viewer (ex: bot.seudominio.com): " viewer
echo ""
read -p "Porta do Viewer (padrão: 3002): " portaviewer
echo ""
read -p "Link do Storage (ex: storage.seudominio.com): " storage
echo ""
read -p "Porta do Storage (padrão: 9000): " portastorage
echo ""
read -p "Seu Email (ex: contato@dominio.com): " email
echo ""
read -p "Senha do seu Email (se for gmail, precisa ser a senha de aplicativo): " senha
echo ""
read -p "SMTP do seu email (ex: smtp.hostinger.com): " smtp
echo ""
read -p "Porta SMTP (ex: 465): " portasmtp
echo ""
read -p "SMTP_SECURE (Se a porta SMTP for 465, digite true, caso contrário, digite false): " SECURE
echo ""

# Gerar uma chave secreta de 32 caracteres
key=$(openssl rand -hex 16)
echo "Chave secreta gerada automaticamente: $key"

#######################################################

# Perguntar se deseja instalar ou atualizar o Docker
read -p "Deseja instalar ou atualizar o Docker? (instalar/atualizar): " docker_option
if [[ "$docker_option" == "instalar" ]]; then
    echo "Instalando o Docker"

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
    sudo apt install docker-ce docker-ce-cli containerd.io docker -y

    # Verifique a instalação do Docker
    sudo systemctl enable docker
    sudo docker --version

    # Adicione o usuário ao grupo docker (opcional)
    sudo usermod -aG docker ${USER}

    # Instale o Docker Compose
    sudo curl -L "https://github.com/docker/compose/releases/download/$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep -Po '"tag_name": \"\K.*?(?=\")')/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose

    # Verifique a instalação do Docker Compose
    docker-compose --version

    echo "Instalação concluída!"
elif [[ "$docker_option" == "atualizar" ]]; then
    echo "Atualizando o Docker e Docker Compose"

    # Remover versões antigas
    sudo apt remove docker docker-engine docker.io containerd runc -y

    # Atualizar dependências
    sudo apt update
    sudo apt upgrade -y

    # Reinstalar dependências e Docker
    sudo apt install apt-transport-https ca-certificates curl software-properties-common -y
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    sudo apt update
    sudo apt install docker-ce docker-ce-cli containerd.io docker -y

    # Verifique a instalação do Docker
    sudo systemctl enable docker
    sudo docker --version

    # Atualizar Docker Compose
    sudo curl -L "https://github.com/docker/compose/releases/download/$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep -Po '"tag_name": \"\K.*?(?=\")')/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose

    # Verifique a instalação do Docker Compose
    docker-compose --version

    echo "Atualização concluída!"
else
    echo "Opção inválida. Saindo..."
    exit 1
fi

#######################################################

clear

echo "Criando arquivo docker-compose.yml"

sleep 3

cat > docker-compose.yml << EOL
version: '3.3'
services:
  typebot-db:
    image: postgres:13
    restart: always
    volumes:
      - db_data:/var/lib/postgresql/data
    environment:
      - POSTGRES_DB=typebot
      - POSTGRES_PASSWORD=typebot
  typebot-builder:
    ports:
      - $portabuilder:3000
    image: baptistearno/typebot-builder:main
    restart: always
    depends_on:
      - typebot-db
    environment:
      - DATABASE_URL=postgresql://postgres:typebot@typebot-db:5432/typebot
      - NEXTAUTH_URL=https://$builder
      - NEXT_PUBLIC_VIEWER_URL=https://$viewer

      - ENCRYPTION_SECRET=$key

      - ADMIN_EMAIL=$email

      - SMTP_SECURE=$SECURE

      - SMTP_HOST=$smtp
      - SMTP_PORT=$portasmtp
      - SMTP_USERNAME=$email
      - SMTP_PASSWORD=$senha
      - NEXT_PUBLIC_SMTP_FROM='Suporte Typebot' <$email>

      #Google
      - GOOGLE_CLIENT_ID=28345025350-er0lj28pscfafplf83ubpcph9ctieunr.apps.googleusercontent.com #<<<<<#
      - GOOGLE_CLIENT_SECRET=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 #<<<<<#

      - S3_ACCESS_KEY=minio
      - S3_SECRET_KEY=minio123
      - S3_BUCKET=typebot
      - S3_ENDPOINT=$storage
  typebot-viewer:
    ports:
      - $portaviewer:3000
    image: baptistearno/typebot-viewer:main
    restart: always
    environment:
      - DATABASE_URL=postgresql://postgres:typebot@typebot-db:5432/typebot
      - NEXT_PUBLIC_VIEWER_URL=https://$viewer
      - ENCRYPTION_SECRET=$key

      - S3_ACCESS_KEY=minio
      - S3_SECRET_KEY=minio123
      - S3_BUCKET=typebot
      - S3_ENDPOINT=$storage
  mail:
    image: bytemark/smtp
    restart: always
  minio:
    labels:
      virtual.host: '$storage'
      virtual.port: '$portastorage'
      virtual.tls-email: '$email'
    image: minio/minio
    command: server /data
    ports:
      - '$portastorage:$portastorage'
    environment:
      MINIO_ROOT_USER: minio
      MINIO_ROOT_PASSWORD: minio123
    volumes:
      - s3_data:/data
  createbuckets:
    image: minio/mc
    depends_on:
      - minio
    entrypoint: >
      /bin/sh -c "
      sleep 10;
      /usr/bin/mc config host add minio http://minio:$portastorage minio minio123;
      /usr/bin/mc mb minio/typebot;
      /usr/bin/mc anonymous set public minio/typebot/public;
      exit 0;
      "
volumes:
  db_data:
  s3_data:
EOL

echo "Criado e configurado com sucesso"

sleep 3

clear

###############################################

echo "Iniciando Contêiner"

sleep 3

docker-compose up -d

echo "Typebot Instalado... Realizando Proxy Reverso"

sleep 3

clear

###############################################

cd

cat > typebot << EOL
server {

  server_name $builder;

  location / {

    proxy_pass http://127.0.0.1:$portabuilder;

    proxy_http_version 1.1;

    proxy_set_header Upgrade \$http_upgrade;

    proxy_set_header Connection 'upgrade';

    proxy_set_header Host \$host;

    proxy_set_header X-Real-IP \$remote_addr;

    proxy_set_header X-Forwarded-Proto \$scheme;

    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    
    proxy_cache_bypass \$http_upgrade;

    }

  }
EOL

###############################################

sudo mv typebot /etc/nginx/sites-available/

sudo ln -s /etc/nginx/sites-available/typebot /etc/nginx/sites-enabled

###############################################

cd

cat > bot << EOL
server {

  server_name $viewer;

  location / {

    proxy_pass http://127.0.0.1:$portaviewer;

    proxy_http_version 1.1;

    proxy_set_header Upgrade \$http_upgrade;

    proxy_set_header Connection 'upgrade';

    proxy_set_header Host \$host;

    proxy_set_header X-Real-IP \$remote_addr;

    proxy_set_header X-Forwarded-Proto \$scheme;

    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    
    proxy_cache_bypass \$http_upgrade;

    }

  }
EOL

###############################################

sudo mv bot /etc/nginx/sites-available/

sudo ln -s /etc/nginx/sites-available/bot /etc/nginx/sites-enabled

##################################################

cd

cat > storage << EOL
server {

  server_name $storage;

  location / {

    proxy_pass http://127.0.0.1:$portastorage;

    proxy_http_version 1.1;

    proxy_set_header Upgrade \$http_upgrade;

    proxy_set_header Connection 'upgrade';

    proxy_set_header Host \$host;

    proxy_set_header X-Real-IP \$remote_addr;

    proxy_set_header X-Forwarded-Proto \$scheme;

    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    
    proxy_cache_bypass \$http_upgrade;

    }

  }
EOL

###############################################

sudo mv storage /etc/nginx/sites-available/

sudo ln -s /etc/nginx/sites-available/storage /etc/nginx/sites-enabled

#######################################################

echo "proxy reverso do typebot"

sudo certbot --nginx --email $email --redirect --agree-tos -d $builder -d $viewer -d $storage

#######################################################
cd
cd
cd
echo -e "\e[32m\e[0m"
echo -e "\e[32m\e[0m"
echo -e "\e[32m\e[0m"
echo -e "\e[32m\e[0m"
echo -e "\e[32m\e[0m"
echo -e "\e[32m\e[0m"
echo -e "\e[32m _                             _              _        \e[0m"
echo -e "\e[32m| |                _          | |            | |       \e[0m"
echo -e "\e[32m| | ____    ___  _| |_  _____ | |  _____   __| |  ___  \e[0m"
echo -e "\e[32m| ||  _ \  /___)(_   _)(____ || | (____ | / _  | / _ \ \e[0m"
echo -e "\e[32m| || | | ||___ |  | |_ / ___ || | / ___ |( (_| || |_| |\e[0m"
echo -e "\e[32m|_||_| |_|(___/    \__)\_____| \_)\_____| \____| \___/ \e[0m"
echo -e "\e[32m                                                       \e[0m"              
echo -e "\e[32m\e[0m"
echo -e "\e[32m\e[0m"
echo -e "\e[32mAcesse o Builder do Typebot através do link: https://$builder\e[0m"
echo -e "\e[32m\e[0m"
echo -e "\e[32mEste script foi um fork do script shell do Canal da Astra Online\e[0m"
echo -e "\e[32m\e[0m"
echo -e "\e[32m\e[0m"
echo -e "\e[32m\e[0m"
echo -e "\e[32m\e[0m"
