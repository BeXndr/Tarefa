#!/bin/bash

# Script para iniciar a pipeline de desenvolvimento com Docker
# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Iniciando Pipeline de Desenvolvimento${NC}"
echo "=================================================="

# Função para criar diretórios necessários
create_directories() {
    echo -e "${BLUE}📁 Criando diretórios necessários...${NC}"
    mkdir -p logs/dev logs/test logs/prod
    mkdir -p database
    echo -e "${GREEN}✅ Diretórios criados${NC}"
}

# Função para parar containers existentes
stop_existing() {
    echo -e "${BLUE}🛑 Parando containers existentes...${NC}"
    sudo docker-compose down --remove-orphans
}

# Função para construir e iniciar ambiente específico
start_environment() {
    local env=$1
    echo -e "${BLUE}🏗️  Construindo ambiente: $env${NC}"
    
    case $env in
        "dev")
            sudo docker-compose up --build app-dev postgres-dev -d
            PORT="8085"
            ;;
        "test")
            sudo docker-compose up --build app-test postgres-test -d
            PORT="8086"
            ;;
        "prod")
            sudo docker-compose up --build app-prod postgres-prod -d
            PORT="8087"
            ;;
        "all")
            sudo docker-compose up --build -d
            echo -e "${GREEN}🌐 Todos os ambientes iniciados:${NC}"
            echo -e "  🔧 Desenvolvimento: http://localhost:8085"
            echo -e "  🧪 Teste: http://localhost:8086" 
            echo -e "  🚀 Produção: http://localhost:8087"
            return
            ;;
        *)
            echo -e "${RED}❌ Ambiente inválido: $env${NC}"
            echo -e "${YELLOW}💡 Use: dev, test, prod ou all${NC}"
            exit 1
            ;;
    esac
    
    echo -e "${GREEN}✅ Ambiente $env iniciado em: http://localhost:$PORT${NC}"
}

# Função para mostrar status dos containers
show_status() {
    echo -e "${BLUE}📊 Status dos containers:${NC}"
    sudo docker-compose ps
}

# Função para mostrar logs
show_logs() {
    local env=${1:-"dev"}
    echo -e "${BLUE}📝 Logs do ambiente $env:${NC}"
    case $env in
        "dev") sudo docker-compose logs -f app-dev ;;
        "test") sudo docker-compose logs -f app-test ;;
        "prod") sudo docker-compose logs -f app-prod ;;
        *) sudo docker-compose logs -f ;;
    esac
}

# Menu principal
show_menu() {
    echo ""
    echo -e "${YELLOW}Escolha uma opção:${NC}"
    echo "1. Iniciar ambiente de Desenvolvimento"
    echo "2. Iniciar ambiente de Teste" 
    echo "3. Iniciar ambiente de Produção"
    echo "4. Iniciar TODOS os ambientes"
    echo "5. Ver status dos containers"
    echo "6. Ver logs (dev/test/prod/all)"
    echo "7. Parar todos os containers"
    echo "8. Sair"
    echo ""
}

# Verificações iniciais
create_directories

# Menu interativo
if [ $# -eq 0 ]; then
    while true; do
        show_menu
        read -p "Digite sua opção (1-8): " option
        
        case $option in
            1) start_environment "dev" ;;
            2) start_environment "test" ;;
            3) start_environment "prod" ;;
            4) start_environment "all" ;;
            5) show_status ;;
            6) 
                read -p "Qual ambiente? (dev/test/prod/all): " log_env
                show_logs $log_env
                ;;
            7) 
                echo -e "${BLUE}🛑 Parando todos os containers...${NC}"
                sudo docker-compose down
                echo -e "${GREEN}✅ Containers parados${NC}"
                ;;
            8) 
                echo -e "${GREEN}👋 Até logo!${NC}"
                exit 0
                ;;
            *) 
                echo -e "${RED}❌ Opção inválida!${NC}"
                ;;
        esac
        echo ""
        read -p "Pressione Enter para continuar..."
    done
else
    # Execução via parâmetro
    case $1 in
        "start")
            start_environment ${2:-"all"}
            ;;
        "stop")
            stop_existing
            ;;
        "status")
            show_status
            ;;
        "logs")
            show_logs ${2:-"dev"}
            ;;
        *)
            echo -e "${YELLOW}Uso: $0 [start|stop|status|logs] [dev|test|prod|all]${NC}"
            ;;
    esac
fi