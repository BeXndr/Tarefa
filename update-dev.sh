#!/bin/bash

# Script para atualizar apenas o ambiente DEV com código do GitHub
# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔄 Atualizando ambiente DEV com código do GitHub${NC}"
echo "=================================================="

# Função para verificar se git está disponível
check_git() {
    if ! command -v git &> /dev/null; then
        echo -e "${RED}❌ Git não está instalado!${NC}"
        exit 1
    fi
    echo -e "${GREEN}✅ Git disponível${NC}"
}

# Função para fazer backup do código atual
backup_current() {
    echo -e "${BLUE}💾 Fazendo backup do código atual...${NC}"
    
    TIMESTAMP=$(date +%Y%m%d_%H%M%S)
    BACKUP_DIR="backup_${TIMESTAMP}"
    
    mkdir -p "$BACKUP_DIR"
    cp -r src/ "$BACKUP_DIR/" 2>/dev/null || true
    cp pom.xml "$BACKUP_DIR/" 2>/dev/null || true
    
    echo -e "${GREEN}✅ Backup criado em: $BACKUP_DIR${NC}"
}

# Função para atualizar código do GitHub
update_from_github() {
    echo -e "${BLUE}🌐 Atualizando código do GitHub...${NC}"
    
    # Verificar se é um repositório git
    if [ ! -d ".git" ]; then
        echo -e "${RED}❌ Não é um repositório git!${NC}"
        echo -e "${YELLOW}💡 Execute: git init && git remote add origin https://github.com/BeXndr/Tarefa.git${NC}"
        exit 1
    fi
    
    # Verificar se há alterações locais importantes
    if git diff --quiet HEAD -- src/main/java/com/example/tarefa/ConexaoBD.java; then
        echo -e "${GREEN}✅ ConexaoBD sem alterações locais${NC}"
        # Fazer stash normal se houver outras alterações
        if ! git diff --quiet; then
            git stash push -m "Auto-stash antes de update DEV $(date)"
        fi
    else
        echo -e "${YELLOW}⚠️ ConexaoBD tem alterações locais importantes!${NC}"
        echo -e "${BLUE}💾 Fazendo commit automático das correções...${NC}"
        git add src/main/java/com/example/tarefa/ConexaoBD.java
        git commit -m "AUTO: Preservar correções ConexaoBD antes de update"
        git push origin master
    fi
    
    # Fazer pull do master
    git fetch origin
    git checkout master
    git pull origin master
    
    echo -e "${GREEN}✅ Código atualizado do GitHub${NC}"
}

# FUNÇÃO: Aplicar migrações de banco no DEV (só novas tabelas)
apply_database_migrations_dev() {
    echo -e "${BLUE}🗄️ Verificando novas tabelas no DEV...${NC}"
    
    if [ -f "database/migrations.sql" ]; then
        echo -e "${BLUE}📝 Criando novas tabelas no banco DEV...${NC}"
        
        #Copiar arquivo da VM para dentro do container
        sudo docker cp "database/migrations.sql" postgres-dev:/tmp/migrations.sql
        
        #Caminho correto dentro do container
        if sudo docker exec postgres-dev psql -U dev_user -d tarefa_dev -f /tmp/migrations.sql; then
            echo -e "${GREEN}✅ Novas tabelas criadas no DEV${NC}"
        else
            echo -e "${YELLOW}⚠️ Tabelas já existem ou erro menor${NC}"
        fi
        
        #Limpar arquivo temporário
        sudo docker exec postgres-dev rm -f /tmp/migrations.sql 2>/dev/null || true
    else
        echo -e "${YELLOW}ℹ️ Nenhum arquivo de migração encontrado${NC}"
    fi
}

# FUNÇÃO: Backup simples do banco DEV
backup_database_dev() {
    echo -e "${BLUE}💾 Fazendo backup do banco DEV...${NC}"
    
    TIMESTAMP=$(date +%Y%m%d_%H%M%S)
    BACKUP_FILE="backup_db_dev_${TIMESTAMP}.sql"
    
    # Fazer dump do banco DEV
    if sudo docker exec postgres-dev pg_dump -U dev_user tarefa_dev > "$BACKUP_FILE"; then
        echo -e "${GREEN}✅ Backup do banco DEV: $BACKUP_FILE${NC}"
    else
        echo -e "${YELLOW}⚠️ Erro no backup (continuando...)${NC}"
    fi
}

# Função para rebuild apenas do container DEV
rebuild_dev() {
    echo -e "${BLUE}🏗️ Reconstruindo container DEV...${NC}"
    
    # Parar apenas o container DEV
    sudo docker-compose stop app-dev
    
    # Rebuild apenas do DEV
    sudo docker-compose build --no-cache app-dev
    
    # Iniciar novamente
    sudo docker-compose up -d app-dev
    
    echo -e "${GREEN}✅ Container DEV atualizado!${NC}"
}

# Função para verificar se DEV está funcionando
check_dev_health() {
    echo -e "${BLUE}🔍 Verificando saúde do DEV...${NC}"
    
    sleep 10  # Aguardar inicialização
    
    # Testar conectividade
    if curl -f http://localhost:8085/api/status > /dev/null 2>&1; then
        echo -e "${GREEN}✅ DEV funcionando: http://localhost:8085${NC}"
    else
        echo -e "${RED}❌ DEV com problemas!${NC}"
        echo -e "${YELLOW}💡 Verificar logs: sudo docker-compose logs app-dev${NC}"
    fi
}

# Função para mostrar diferenças
show_diff() {
    echo -e "${BLUE}📊 Comparando ambientes:${NC}"
    echo "  🔧 DEV:  Código atualizado do GitHub"
    echo "  🧪 TEST: Código local (não alterado)"  
    echo "  🚀 PROD: Código local (não alterado)"
    echo ""
    echo -e "${YELLOW}URLs dos ambientes:${NC}"
    echo "  DEV:  http://localhost:8085"
    echo "  TEST: http://localhost:8086"
    echo "  PROD: http://localhost:8087"
}

# Menu principal
show_menu() {
    echo ""
    echo -e "${YELLOW}Escolha uma opção:${NC}"
    echo "1. 🔄 Atualizar DEV com código do GitHub"
    echo "2. 📊 Ver status dos ambientes"
    echo "3. 📝 Ver logs do DEV"
    echo "4. 🔄 Reverter DEV (usar backup)"
    echo "5. 🧹 Limpar backups antigos"
    echo "6. 🚪 Sair"
    echo ""
}

# Função principal
main_update() {
    check_git
    backup_current
    backup_database_dev
    update_from_github
    apply_database_migrations_dev
    rebuild_dev
    check_dev_health
    show_diff
}

# Função para reverter
revert_dev() {
    echo -e "${BLUE}🔄 Listando backups disponíveis...${NC}"
    
    BACKUPS=($(ls -d backup_* 2>/dev/null))
    
    if [ ${#BACKUPS[@]} -eq 0 ]; then
        echo -e "${RED}❌ Nenhum backup encontrado!${NC}"
        return
    fi
    
    echo "Backups disponíveis:"
    for i in "${!BACKUPS[@]}"; do
        echo "$((i+1)). ${BACKUPS[$i]}"
    done
    
    read -p "Escolha o backup (número): " choice
    
    if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le "${#BACKUPS[@]}" ]; then
        SELECTED_BACKUP="${BACKUPS[$((choice-1))]}"
        
        echo -e "${BLUE}🔄 Revertendo para: $SELECTED_BACKUP${NC}"
        
        # Restaurar arquivos
        cp -r "$SELECTED_BACKUP/src/" ./ 2>/dev/null || true
        cp "$SELECTED_BACKUP/pom.xml" ./ 2>/dev/null || true
        
        # Rebuild DEV
        rebuild_dev
        
        echo -e "${GREEN}✅ DEV revertido com sucesso!${NC}"
    else
        echo -e "${RED}❌ Opção inválida!${NC}"
    fi
}

# Limpar backups antigos
clean_backups() {
    echo -e "${BLUE}🧹 Limpando backups antigos...${NC}"
    
    # Manter apenas os 5 mais recentes
    BACKUPS=($(ls -d backup_* 2>/dev/null | sort -r))
    
    if [ ${#BACKUPS[@]} -gt 5 ]; then
        for ((i=5; i<${#BACKUPS[@]}; i++)); do
            rm -rf "${BACKUPS[$i]}"
            echo -e "${GREEN}🗑️  Removido: ${BACKUPS[$i]}${NC}"
        done
    else
        echo -e "${YELLOW}💡 Menos de 5 backups, nada para limpar${NC}"
    fi
}

# Menu interativo
if [ $# -eq 0 ]; then
    while true; do
        show_menu
        read -p "Digite sua opção (1-6): " option
        
        case $option in
            1) main_update ;;
            2) sudo docker-compose ps ;;
            3) sudo docker-compose logs -f app-dev ;;
            4) revert_dev ;;
            5) clean_backups ;;
            6) 
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
    # Execução direta
    case $1 in
        "update") main_update ;;
        "revert") revert_dev ;;
        "clean") clean_backups ;;
        *) echo -e "${YELLOW}Uso: $0 [update|revert|clean]${NC}" ;;
    esac
fi