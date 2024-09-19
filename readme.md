# Projeto

Requisitos AWS:
-	Gerar uma chave pública para acesso ao ambiente;
-	Criar 1 instância EC2 com o sistema operacional Amazon Linux 2 (Família t3.small, 16 GB SSD);
-	Gerar 1 elastic IP e anexar à instância EC2;
-	Liberar as portas de comunicação para acesso público: (22/TCP, 111/TCP e UDP, 2049/TCP/UDP, 80/TCP, 443/TCP).

Requisitos no linux:
-	Configurar o NFS entregue;
-	Criar um diretório dentro do filesystem do NFS com seu nome;
-	Subir um apache no servidor - o apache deve estar online e rodando;
-	Criar um script que valide se o serviço esta online e envie o resultado da validação para o seu diretorio no nfs;
-	O script deve conter - Data HORA + nome do serviço + Status + mensagem personalizada de ONLINE ou offline;
-	O script deve gerar 2 arquivos de saida: 1 para o serviço online e 1 para o serviço OFFLINE;
-	Preparar a execução automatizada do script a cada 5 minutos.
-	Fazer o versionamento da atividade;
-	Fazer a documentação explicando o processo de instalação do Linux.

*Importante: Desligue a máquina quando não for utilizar, será descontado pontos de máquinas que permanecerem ligadas em períodos fora de uso.*


# Passos

## Parte 1: Configuração na AWS
•	*Criar uma VPC (project1-vpc)*
<img src="/imgs/image.png">

•	*Criar e associar subnet pública (subnet-project1-public1);*
<img src="/imgs/image1.png">

•	*Criar um Internet Gateway (project1-igw01) e associar à VPC "project1-vpc";*
<img src="/imgs/image2.png">

•	*Criar uma Route Table e associar à VPC "project1-vpc";*
<img src="/imgs/image3.png">
- Editar Route Table para permitir acesso público, através do Internet Gateway "project1-igw01";
- Adicionar a subnet "subnet-project1-public1" à Route Table;

•	*Criar uma instância EC2 com Amazon Linux 2 (description="Project1_linux"), família t3.small, storage SSD de 16 GB, par de chaves (aws-servem.pem);*
<img src="/imgs/image4.png">
- Associar à VPC e Subnet criadas anteriormente;
- Criar um Security Group (project1-security-group), liberando as portas especificadas no enunciado da atividade (22/TCP, 111/TCP e UDP, 2049/TCP/UDP, 80/TCP, 443/TCP), via Inbound Security Group Rules;
<img src="/imgs/image5.png">
- Criar um par de chaves do tipo .pem "Project1_compass.pem" para acesso via SSH da instancia EC2

•	*Rodar instância EC2 "Project1_linux";*

•	*Gerar um Elastic IP e anexar à instância EC2.*
<img src="/imgs/image6.png">

## Parte 2: Configuração no Linux
•	*Acessar a Instância EC2 (via SSH: $ ssh -i "Project1_compass.pem" ec2-user@<Elastic_IP>);*
<img src="/imgs/image7.png">

•	*Criar um Sistema de compartilhamento de Arquivos NFS:*
 - Instalar o pacotes nescessarios do NFS server: $ sudo yum install nfs-utils
 - Ativando o servidor NFS: $ sudo systemctl enable nfs-server
 - Iniciando o serviço de NFS: $ sudo systemctl start nfs-server
 - Verificando o Status do NFS: $ sudo systemctl status nfs-server
 - Criando um diretorio <my_name> dentro o /mnt/nfs: $ sudo mkdir -p /mnt/nfs/edilson_maria
<img src="/imgs/image8.png">

•	*Configure o Sistema de compartilhamento de Arquivos NFS:*
 - Defina as permissões dos ranges de IP que teram acessos ao diretorio NFS:
  $ sudo vi /etc/exports
 - Adicione o a linha abaixo afirmanado os ranges de IP no diretorio /etc/exports:
  $ /mnt/nfs_share 192.168.1.0/24(rw,sync,no_root_squash,no_subtree_check)


•	*Criar um Sistema de compartilhamento de Arquivos EFS na AWS:*
 - Acessar o serviço EFS (Elastic File System);
 - Clicar em Create file system;
 - Atribuir o nome "project1_compass-EFS" ao File System;
 - Escolher a VPC onde está a instância EC2 "Project1_linux".

• *Instalando o facilitado da Amazon-efs-utils para auxiliar na montagem dos EFS:*
 - $ sudo yum install -y amazon-efs-utils

•	*Montar o filesystem EFS:*
 - $ sudo mkdir /mnt/efs
 - $ sudo mount -t nfs4 -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport <IP_EFS>:/ mnt/efs 
 - Configurar o Montagem Automática: $ echo "<IP_EFS>:/ /mnt/efs nfs4 defaults,_netdev 0 0" | sudo tee -a /etc/fstab

•	*Criar um diretório dentro do filesystem do NFS com meu nome:* 
 - $ sudo mkdir /mnt/efs/<My_Name>

## Parte 3: Instalar e Configurar o Apache
•	*Instalar o Apache:* 
 - $ sudo yum install -y httpd

•	*Iniciar e habilitar o Apache:* 
 - $ sudo systemctl start httpd 
 - $ sudo systemctl enable httpd
<img src="/imgs/image9.png">

•	*Criar o script de verificação do estado do servidor Apache:*

	- $ sudo nano /usr/local/bin/status_apache.sh

	- status_apache.sh:
		#!/bin/bash

        Configurações
        SERVICE_NAME="Apache"
        SERVICE_URL="http://localhost:80"
        NFS_DIR="/mnt/nfs/status"
        ONLINE_STATUS_FILE="$NFS_DIR/online_status.txt"
        OFFLINE_STATUS_FILE="$NFS_DIR/offline_status.txt"

        - Cria o diretório no NFS se não existir
        if [ ! -d "$NFS_DIR" ]; then
           sudo mkdir -p "$NFS_DIR"
        fi

        - Verifica se o serviço Apache está online
        HTTP_STATUS=$(curl -o /dev/null -s -w "%{http_code}\n" $SERVICE_URL)

        - Pega a data e hora atual
        CURRENT_DATETIME=$(date "+%Y-%m-%d %H:%M:%S")

        if [ "$HTTP_STATUS" -eq 200 ]; then
          STATUS="ONLINE"
          MESSAGE="O serviço Apache está funcionando corretamente."
          echo "$CURRENT_DATETIME - Serviço: $SERVICE_NAME - Status: $STATUS - Mensagem: $MESSAGE" >> $ONLINE_STATUS_FILE
        else
        STATUS="OFFLINE"
        MESSAGE="O serviço Apache está inacessível ou ocorreu um problema."
        echo "$CURRENT_DATETIME - Serviço: $SERVICE_NAME - Status: $STATUS - Mensagem: $MESSAGE" >> $OFFLINE_STATUS_FILE
        fi
<img src="/imgs/image10.png">

•	*Atribuir as permissões de execução do script:*
 - $ sudo chmod +x /usr/local/bin/status_apache.sh
 - $ sudo chown ec2-user:ec2-user /mnt/nfs/<My_Name>

•	*Definindo que a data e a hora seja o de Recife/BR:*
 - $ sudo timedatectl set-timezone America/Recife
  
•	*Automatizar a execução do script a cada 5 minutos:*
 - $ sudo crontab -e
 - Adicionar ao crontab: */5 * * * * /usr/local/bin/status_apache.sh
<img src="/imgs/image11.png">

## Parte 4: Colocar uma pagina WEB no servidor Apache

•	*Acessando o diretorio apache para colocar os arquivos HTML e CSS:*
 - $ cd /var/www/html

•	*Crie o rquivo HTML no diretorio /var/www/html:*
 - $ sudo nano index.html
<img src="/imgs/image12.png">

•	*Crie o rquivo CSS no diretorio /var/www/html:*
 - $ sudo nano styles.html
<img src="/imgs/image13.png">

•	*Acessando o sit WEB no servidor apache:*
 - No navegador coloque o IP Publico da instacia EC2 da AWS
<img src="/imgs/image14.png">





[def]: image.png