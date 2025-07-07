FROM openjdk:21-jdk-slim

# Instalar dependências essenciais
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    && rm -rf /var/lib/apt/lists/*

# Definir diretório de trabalho
WORKDIR /app

# Copiar arquivos Maven
COPY mvnw .
COPY .mvn .mvn
COPY pom.xml .

# Dar permissão de execução ao mvnw
RUN chmod +x mvnw

# Baixar dependências (para cache de camadas)
RUN ./mvnw dependency:go-offline

# Copiar código fonte
COPY src ./src

# Compilar a aplicação
RUN ./mvnw clean package -DskipTests

# Expor porta da aplicação
EXPOSE 8080

# Comando para executar a aplicação
CMD ["java", "-jar", "target/tarefa-0.0.1-SNAPSHOT.jar"]