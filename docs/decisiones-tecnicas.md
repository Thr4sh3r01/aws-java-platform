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

- **Fecha**: pendiente de diseño (Hito 3)
- **Decisión**: pendiente
- **Alternativas en evaluación**:
  - ¿NAT Gateway o alternativa sin NAT (endpoints VPC)?
  - ¿Una o dos zonas de disponibilidad en el MVP?
  - Tipo de balanceador (ALB vs NLB).

## Pendiente de decisión

- Región AWS y política de costes.
- ¿NAT Gateway o alternativa?
- ¿1 AZ (MVP) o 2 AZ?
- SonarCloud / JFrog: ¿cuentas disponibles?
