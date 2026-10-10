# Arquitectura — aws-java-platform

## Visión general

Aplicación web Java (Spring Boot, WAR) de 3 capas desplegada en AWS:

- **Capa de presentación**: Nginx (frontend estático y proxy).
- **Capa de aplicación**: Apache Tomcat con la aplicación WAR.
- **Capa de datos**: MySQL en Amazon RDS.

## Topología de red (propuesta MVP)

*Por completar en la fase de diseño (Hito 3+):*

- VPC única con CIDR RFC 1918 válido (p. ej. `10.0.0.0/16`).
- Subredes públicas y privadas distribuidas en 2 AZ (o 1 AZ en MVP con limitación documentada).
- Internet Gateway y rutas.
- Security Groups por capa.

## Flujos de tráfico

1. Usuario → ALB (puerto 80) → Nginx
2. Nginx → Tomcat (puerto 8080)
3. Tomcat → RDS MySQL (puerto 3306)

## Decisiones pendientes

- ¿NAT Gateway o alternativa sin NAT para la capa privada?
- ¿Una o dos zonas de disponibilidad en el MVP?
- Tipo de balanceador (ALB vs NLB).

## Fuentes

- Compilación local verificada: `dptweb-1.0.war` con Maven y JDK 11.
