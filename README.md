# iac-terraform-mackenzie-cloud
Repo para atividade de terraform para disciplina de cloud computing 

# 🚀 Infraestrutura HA WebApp – Terraform

Este projeto provisiona uma arquitetura altamente disponível na AWS utilizando **VPC**, **sub-redes públicas**, **Load Balancer (ALB)**, **Auto Scaling Group (ASG)**, **EC2 Launch Template**, **Security Groups**, e integração com **Route 53**.

A solução foi pensada para cenários de **alta disponibilidade**, **escalabilidade automática** e **deploy simples** para aplicações web.

---

## 📌 Arquitetura (Resumo)

A infraestrutura criada segue esta estrutura:

- **VPC**
  - Sub-redes públicas em **2 AZs**
  - Internet Gateway
  - Route Table pública
- **Security Groups**
  - ALB: libera portas 80/443
  - EC2: permite tráfego do ALB e SSH opcional
- **Load Balancer (ALB)**
  - Listener HTTP (80)
  - (Opcional) Listener HTTPS (443)
  - Target Group (EC2 Instances)
- **Auto Scaling Group**
  - Launch Template com user_data
  - Escalonamento baseado em CPU
- **Route 53**
  - Registro A (Alias → ALB)

---

## 📁 Estrutura dos Arquivos

```

.
├── main.tf
├── variables.tf
├── outputs.tf
├── user_data.sh
└── README.md

````

---

## 🧩 Pré-requisitos

- Terraform **>= 1.5**
- AWS CLI configurado (`aws configure`)
- Um domínio registrado no Route 53 (caso utilize o recurso de alias)
- Uma AMI válida (ex: Amazon Linux 2 ou 2023)

---

## ⚙️ Variáveis Principais

| Variável | Descrição | Default |
|---------|-----------|---------|
| `region` | Região AWS | `us-east-1` |
| `vpc_cidr` | CIDR da VPC | `10.0.0.0/16` |
| `public_subnet_a_cidr` | Sub-rede pública A | `10.0.1.0/24` |
| `public_subnet_b_cidr` | Sub-rede pública B | `10.0.2.0/24` |
| `ami_id` | ID da AMI | **obrigatória** |
| `instance_type` | Tipo da EC2 | `t3.micro` |
| `key_name` | Key Pair (SSH) | `null` |
| `asg_min` | ASG mínimo | `2` |
| `asg_max` | ASG máximo | `6` |
| `asg_desired` | ASG desejado | `2` |
| `cpu_target` | Target de CPU (%) | `50` |
| `route53_zone_id` | Hosted Zone ID | **obrigatória** |
| `route53_record_name` | Nome do domínio | **obrigatória** |

---

## 🚀 Como Usar

### 1. Inicializar o Terraform
```sh
terraform init
````

### 2. Validar o código

```sh
terraform validate
```

### 3. Visualizar o plano de execução

```sh
terraform plan
```

### 4. Aplicar a infraestrutura

```sh
terraform apply
```

---

## 🌐 Outputs

| Output         | Descrição                                         |
| -------------- | ------------------------------------------------- |
| `alb_dns_name` | DNS público do Load Balancer                      |
| `route53_fqdn` | FQDN configurado no Route 53 apontando para o ALB |

---

## 🔐 User Data

O arquivo **user_data.sh** deve conter o script de inicialização da instância.

Exemplo:

```bash
#!/bin/bash
yum update -y
yum install -y httpd
systemctl enable httpd
systemctl start httpd

echo "<h1>Aplicação no ar!</h1>" > /var/www/html/index.html
```

---

## 🔧 HTTPS (Opcional)

Para habilitar HTTPS:

1. Obtenha um certificado no ACM
2. Preencha `acm_certificate_arn`
3. Descomente o listener HTTPS no arquivo `main.tf`

---

## 🧨 Remover a infraestrutura

```sh
terraform destroy
```

---

## 📜 Licença

Código livre para uso em estudos, testes e produção. Ajuste conforme sua necessidade.

---

```

---

Se quiser, também posso gerar:

✅ Uma versão reduzida  
✅ Uma versão em inglês  
✅ Um diagrama Mermaid para colocar dentro do README  

É só pedir!
```
