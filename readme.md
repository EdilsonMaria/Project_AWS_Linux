# Projeto

Requisitos AWS:
•	Gerar uma chave pública para acesso ao ambiente;
•	Criar 1 instância EC2 com o sistema operacional Amazon Linux 2 (Família t3.small, 16 GB SSD);
•	Gerar 1 elastic IP e anexar à instância EC2;
•	Liberar as portas de comunicação para acesso público: (22/TCP, 111/TCP e UDP, 2049/TCP/UDP, 80/TCP, 443/TCP).

Requisitos no linux:
•	Configurar o NFS entregue;
•	Criar um diretório dentro do filesystem do NFS com seu nome;
•	Subir um apache no servidor - o apache deve estar online e rodando;
•	Criar um script que valide se o serviço esta online e envie o resultado da validação para o seu diretorio no nfs;
•	O script deve conter - Data HORA + nome do serviço + Status + mensagem personalizada de ONLINE ou offline;
•	O script deve gerar 2 arquivos de saida: 1 para o serviço online e 1 para o serviço OFFLINE;
•	Preparar a execução automatizada do script a cada 5 minutos.
•	Fazer o versionamento da atividade;
•	Fazer a documentação explicando o processo de instalação do Linux.

*Importante: Desligue a máquina quando não for utilizar, será descontado pontos de máquinas que permanecerem ligadas em períodos fora de uso.*


# Passos

## Parte 1: Configuração na AWS
•	Criar uma VPC (project1-vpc)
<img src="/imgs/image.png">
•	Criar e associar subnet pública (subnet-project1-public1);
![alt text](image1.png)
•	Criar um Internet Gateway (project1-igw01) e associar à VPC "project1-vpc";
![alt text](image2.png)
•	Criar uma Route Table e associar à VPC "project1-vpc";
	- Editar Route Table para permitir acesso público, através do Internet Gateway "project1-igw01";
	- Adicionar a subnet "subnet-project1-public1" à Route Table;
•	Criar uma instância EC2 com Amazon Linux 2 (description="Project1_linux"), família t3.small, storage SSD de 16 GB, par de chaves (aws-servem.pem);
	- Associar à VPC e Subnet criadas anteriormente;
	- Criar um Security Group (project1-security-group), liberando as portas especificadas no enunciado da atividade (22/TCP, 111/TCP e UDP, 2049/TCP/UDP, 80/TCP, 443/TCP), via Inbound Security Group Rules;
•	Rodar instância EC2 "project1-EFS";
•	Gerar um Elastic IP e anexar à instância EC2.

## Parte 2: Configuração no Linux
•	Acessar a Instância EC2 (via SSH: $ ssh -i ~/.ssh/aws-servem-KeyPair ec2-user@<Elastic_IP>);
•	Criar um Sistema de Arquivos EFS:
	- Acessar o serviço EFS (Elastic File System);
	- Clicar em Create file system;
	- Atribuir o nome "project1-EFS" ao File System;
	- Escolher a VPC onde está a instância EC2 "Project1_linux".
•   Certifique-se de que o pacote de utilitários NFS está instalado na instância do EC2
    - $ sudo yum install -y nfs-utils
•	Montar o filesystem NFS:
	- $ sudo mkdir /mnt/efs
	- $ sudo mount -t nfs4 -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport <IP_EFS>:/ /mnt/efs
	- Configurar o Montagem Automática: $ echo "<IP_EFS>:/ /mnt/efs nfs4 defaults,_netdev 0 0" | sudo tee -a /etc/fstab
•	Criar um diretório dentro do filesystem do NFS com meu nome: $ sudo mkdir /mnt/efs/<My_Name>
•	Instalar o Apache: sudo yum install -y httpd
•	Iniciar e habilitar o Apache: sudo systemctl start httpd && sudo systemctl enable httpd
•	Criar o script de verificação do estado do servidor Apache: 
	- $ sudo nano /usr/local/bin/project1_compass.sh
	- check_apache_status.sh:
		#!/bin/bash

        Configurações
        SERVICE_NAME="Apache"
        SERVICE_URL="http://localhost:80"
        EFS_DIR="/mnt/efs/status"
        ONLINE_STATUS_FILE="$EFS_DIR/online_status.txt"
        OFFLINE_STATUS_FILE="$EFS_DIR/offline_status.txt"

        - Cria o diretório no EFS se não existir
        if [ ! -d "$EFS_DIR" ]; then
           sudo mkdir -p "$EFS_DIR"
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

	- $ sudo chmod +x /usr/local/bin/project1_compass.sh
	- $ sudo chown ec2-user:ec2-user /mnt/efs/<My_Name>
	- $ sudo timedatectl set-timezone America/Recife
•	Automatizar a execução do script a cada 5 minutos:
	- $ sudo crontab -e
	- Adicionar ao crontab: */5 * * * * /usr/local/bin/project1_compass.sh



[def]: image.png