# Decisiones técnicas — aws-java-platform

Registro de decisiones de arquitectura y su justificación.

---

## DT-001: Nombre del proyecto

- **Fecha**: 2026-10-10
- **Decisión**: El proyecto se llama `aws-java-platform`.
- **Justificación**: Nombre corto, profesional y descriptivo; comunica que es una plataforma Java desplegada en AWS. Se usa como tag de recursos (`Project=aws-java-platform`) para identificación y control de costes.

## DT-002: Estructura de carpetas

- **Fecha**: 2026-10-10
- **Decisión**: El proyecto vive en `java-aws-3tier/aws-java-platform/`, con separación clara entre documentación, infraestructura y código de la aplicación.
- **Justificación**: Separación de responsabilidades; facilita la revisión, el versionado y la localización de cada componente.

## DT-003: Manejo de credenciales

- **Fecha**: 2026-10-10
- **Decisión**: Ninguna credencial en el repositorio. El acceso a MySQL se parametriza mediante variables de entorno (`SPRING_DATASOURCE_URL`, `SPRING_DATASOURCE_USERNAME`, `SPRING_DATASOURCE_PASSWORD`). Los archivos de configuración con secretos (p. ej. `settings.xml`, `.env`) quedan excluidos por `.gitignore`.
- **Justificación**: Principio de mínimo privilegio y separación entre configuración y secretos. Las credenciales se gestionan en el entorno de despliegue, nunca en código.

## DT-004: Compilación con `-DskipTests` en desarrollo local

- **Fecha**: 2026-10-10
- **Decisión**: La compilación local del entorno de desarrollo usa `-DskipTests` porque el test de contexto (`contextLoads`) requiere una base de datos que no existe en local.
- **Riesgo aceptado**: No abusar de `-DskipTests` en CI; en pipeline se configurarán propiedades de test o se omitirá el test de contexto con justificación explícita.
- **Alternativa futura**: Arreglar el test con un datasource simulado (H2 o propiedades dummy).

## DT-005: Stack de la aplicación

- **Fecha**: 2026-10-10
- **Decisión**: Se trabaja sobre una aplicación Spring Boot 2.2.4 empaquetada como WAR, compilada con Java 8 como objetivo (compatible con JDK 11). No se reescribe la aplicación; se documentan sus limitaciones.
- **Limitación documentada**: Spring Boot 2.2.4 es una versión antigua (2020) con dependencias que pueden tener CVEs conocidos. Se documentará en el informe de seguridad; la modernización queda fuera del alcance del MVP.

## DT-006: Arquitectura de red MVP

- **Fecha**: 2026-10-10 (aprobada)
- **Decisión**: VPC `10.0.0.0/16` con 2 subredes públicas (`10.0.1.0/24`, `10.0.2.0/24`) y 2 privadas (`10.0.3.0/24`, `10.0.4.0/24`). 4 Security Groups encadenados: `sg-alb` → `sg-nginx` → `sg-tomcat` → `sg-rds`. **Sin NAT Gateway** (Opción B, MVP).
- **Justificación**: Cumple el presupuesto Free Tier + crédito de 100 $. El tráfico SSH se configura por Security Group (no por bastión). La app queda expuesta en subred pública con SG cerrado; se documenta como limitación.
- **Alternativas descartadas**:
  - NAT Gateway: descartado por coste (~32 $/mes).
  - ALB: pendiente para fase posterior.

## DT-007: Migración EC2 a Amazon Linux 2023

- **Fecha**: 2026-10-13
- **Decisión**: Migrar la EC2 de Amazon Linux 2 (EOL junio 2026) a Amazon Linux 2023 mediante **destruir y recrear** la instancia con Terraform (Opción B1).
- **Justificación**: Amazon Linux 2 ya no recibe parches de seguridad. El comando `modify-instance-attribute --image-id` NO cambia el sistema operativo de una instancia existente; solo afecta a futuros lanzamientos. La forma correcta es crear una instancia nueva desde la AMI AL2023.
- **Impacto**: IP pública cambiará; habrá que reinstalar Tomcat y la app en la nueva instancia.
- **Cambios en `ec2.tf`**:
  1. Data source: `amazon_linux_2` → `amazon_linux_2023` (filtro `al2023-ami-2023*-x86_64`)
  2. SSH: `0.0.0.0/0` → `81.40.66.107/32` (solo IP del usuario)
  3. user_data: `yum` → `dnf`, Java 8 → Java 17 Amazon Corretto
  4. Tomcat: 9.0.63 → 9.0.122
  5. Referencia AMI: `amazon_linux_2.id` → `amazon_linux_2023.id`

## DT-008: Eliminación de acceso SSH (reemplazado por DT-010)

- **Fecha**: 2026-10-13
- **Decisión**: Inicialmente se restringió SSH a la IP del usuario; posteriormente se eliminó completamente en favor de Session Manager (ver DT-010).
- **Estado**: **SUPERADO** por DT-010.

## DT-009: Upgrade de RDS MySQL

- **Fecha**: 2026-10-13
- **Decisión**: Upgrade a MySQL 8.4 LTS con snapshot de seguridad previo (`backup-before-upgrade`).
- **Justificación**: MySQL 8.0.46 es inseguro sin parches; 8.4 es la versión LTS actual. Se crea snapshot antes por seguridad.
- **Implementación**: Desde consola AWS (RDS → Modificar → 8.4 → Aplicar inmediatamente).
- **Estado**: EN CURSO (2026-10-13).

## DT-010: Session Manager en lugar de SSH

- **Fecha**: 2026-10-13
- **Decisión**: Acceso a instancias EC2 exclusivamente por AWS Session Manager (SSM). Se eliminaron: regla SSH del Security Group, recurso `aws_key_pair`, y parámetro `key_name`.
- **Justificación**:
  - Sin puertos abiertos (no hay puerto 22).
  - Sin claves SSH que gestionar.
  - Sin IPs públicas en el código (evita exponer IP en GitHub).
  - Audit trail completo via CloudTrail y CloudWatch Logs.
  - Práctica estándar en entornos de producción.
- **Implementación**:
  - IAM Role con política `AmazonSSMManagedInstanceCore`.
  - `aws_iam_instance_profile` asociado a la instancia.
  - Amazon Linux 2023 trae SSM Agent preinstalado.
- **Acceso**: `aws ssm start-session --target <instance-id> --region eu-west-1` o desde consola EC2 → Connect → Session Manager.

## DT-011: Estrategia Free Tier

- **Fecha**: 2026-10-13
- **Decisión**: Arquitectura 100% Free Tier durante los primeros 12 meses.
- **Servicios gratuitos (siempre)**: VPC, subredes, SGs, IAM, Session Manager, CloudWatch básico, SNS.
- **Servicios gratuitos (750 hrs/mes, 12 meses)**: EC2 t3.micro, RDS db.t3.micro, NLB.
- **Servicios gratuitos (5 GB, siempre)**: S3.
- **Servicios a evitar**: NAT Gateway (~32 $/mes), ALB (usar NLB), RDS Multi-AZ.
- **Justificación**: Preservar los créditos acumulados (~139 $) para otros proyectos. La infraestructura puede funcionar 24/7 durante 12 meses sin coste real.

## Pendiente de decisión

- ¿Mover Tomcat a subred privada? (requiere NLB + SSM)
- ¿NAT Gateway? (solo si la app necesita Internet desde privadas)
- SonarCloud / JFrog: ¿cuentas disponibles?
- CI/CD: ¿solo `plan` o también `apply` con aprobación manual?
