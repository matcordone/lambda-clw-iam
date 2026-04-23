# Lambda + S3 + IAM + CloudWatch con Terraform

Proyecto del canal de YouTube. Desplegamos una arquitectura serverless en AWS usando Terraform donde una **Lambda en Python** se activa automáticamente cuando se sube un archivo a un bucket S3, lo copia a otro bucket y elimina el original.

## Arquitectura

```
S3 (bucket origen)
      │
      │  s3:ObjectCreated:Put
      ▼
AWS Lambda (Python 3.14)
      │
      ├──► S3 (bucket destino)  ← copia el archivo
      ├──► S3 (bucket origen)   ← elimina el original
      └──► CloudWatch Logs      ← registra la operación
```

## Recursos que crea Terraform

| Recurso | Nombre | Descripción |
|---|---|---|
| S3 Bucket | `lambda-clw-iam-old` | Bucket origen que dispara la Lambda |
| S3 Bucket | `lambda-clw-iam-new` | Bucket destino donde llega el archivo |
| Lambda Function | `lambda_clw_iam` | Función Python que mueve el archivo |
| IAM Role | `lambda-clw-iam-role` | Rol de ejecución de la Lambda |
| IAM Policy | `lambda-clw-iam-policy` | Permisos S3 + CloudWatch Logs |
| S3 Notification | - | Trigger que conecta el bucket con la Lambda |

## Prerrequisitos

- [Terraform](https://developer.hashicorp.com/terraform/install) >= 1.0
- [AWS CLI](https://aws.amazon.com/cli/) configurado con un perfil `default`
- Bucket S3 para el estado de Terraform (`terraform-statefiles-yt`) creado previamente

## Estructura del proyecto

```
lambda-clw-iam/
├── src/
│   └── main.py          # Código de la Lambda
├── main.tf              # Recursos principales (S3, Lambda, IAM)
├── provider.tf          # Provider AWS + backend S3
├── backend.tf           # Bucket para el state de Terraform
├── variables.tf         # Definición de variables
├── terraform.tfvars     # Valores de las variables
└── README.md
```

![alt text](image.png)

## Variables

| Variable | Descripción | Valor por defecto |
|---|---|---|
| `bucket_name_old` | Nombre del bucket origen | `lambda-clw-iam-old` |
| `bucket_name_new` | Nombre del bucket destino | `lambda-clw-iam-new` |
| `new_key` | Nombre con el que se guarda el archivo en el destino | `new.txt` |

Podés modificar estos valores en `terraform.tfvars`.

## Deploy

```bash
# 1. Inicializar Terraform
terraform init

# 2. Ver qué va a crear
terraform plan

# 3. Aplicar
terraform apply
```

## Probar

Una vez desplegado, subí cualquier archivo al bucket origen:

```bash
aws s3 cp archivo.txt s3://lambda-clw-iam-old/
```

La Lambda se dispara automáticamente, copia el archivo al bucket destino con el nombre configurado en `new_key`, y elimina el original.

Para ver los logs en CloudWatch:

```bash
aws logs tail /aws/lambda/lambda_clw_iam --follow
```

## Destruir

```bash
terraform destroy
```

> **Nota:** si los buckets tienen archivos adentro, Terraform no puede destruirlos. Vaciálos primero o habilitá `force_destroy` en los módulos S3.

## Permisos IAM de la Lambda

La policy otorga los permisos mínimos necesarios:

- **S3:** `GetObject`, `PutObject`, `DeleteObject` sobre ambos buckets
- **CloudWatch Logs:** `CreateLogGroup`, `CreateLogStream`, `PutLogEvents`

