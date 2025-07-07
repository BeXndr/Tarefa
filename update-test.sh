#!/bin/bash

# Script para atualizar ambiente TEST com código do ambiente DEV
# Método: Container para Container (local)
# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔄 Atualizando ambiente TEST com código do DEV${NC}"
echo "=================================================="

# ========================================
# FUNÇÃO: Fazer backup do TEST atual
# ========================================
backup_test_current() {
    echo -e "${BLUE}💾 Fazendo backup do TEST atual...${NC}"
    
    TIMESTAMP=$(date +%Y%m%d_%H%M%S)
    BACKUP_DIR="backup_test_${TIMESTAMP}"
    
    mkdir -p "$BACKUP_DIR"
    cp -r src/ "$BACKUP_DIR/" 2>/dev/null || true
    cp pom.xml "$BACKUP_DIR/" 2>/dev/null || true
    
    echo -e "${GREEN}✅ Backup TEST criado: $BACKUP_DIR${NC}"
}

# ========================================
# FUNÇÃO: Verificar saúde do TEST
# ========================================
check_test_health() {
    echo -e "${BLUE}🔍 Verificando saúde do TEST...${NC}"
    
    sleep 15  # Aguardar inicialização
    
    if curl -f http://localhost:8086/api/status > /dev/null 2>&1; then
        echo -e "${GREEN}✅ TEST funcionando: http://localhost:8086${NC}"
        return 0
    else
        echo -e "${RED}❌ TEST com problemas!${NC}"
        echo -e "${YELLOW}💡 Verificar logs: sudo docker-compose logs app-test${NC}"
        return 1
    fi
}

# ========================================
# FUNÇÃO: Mostrar diferenças entre ambientes
# ========================================
show_environments_diff() {
    echo -e "${BLUE}📊 Status dos ambientes após atualização:${NC}"
    echo "  🔧 DEV:  Código original (inalterado)"
    echo "  🧪 TEST: Código atualizado do DEV ← ATUALIZADO"  
    echo "  🚀 PROD: Código original (inalterado)"
    echo ""
    echo -e "${YELLOW}URLs para comparar:${NC}"
    echo "  DEV:  http://localhost:8085"
    echo "  TEST: http://localhost:8086 ← TESTE AQUI"
    echo "  PROD: http://localhost:8087"
}

# ========================================
# FUNÇÃO: Executar testes unitários no TEST
# ========================================
run_tests_on_test() {
    echo -e "${BLUE}🧪 Executando testes unitários no ambiente TEST...${NC}"
    
    if sudo docker exec tarefa-app-test ./mvnw test 2>/dev/null; then
        echo -e "${GREEN}✅ Todos os testes passaram no TEST!${NC}"
        return 0
    else
        echo -e "${RED}❌ Alguns testes falharam no TEST!${NC}"
        echo -e "${YELLOW}💡 Para ver detalhes: sudo docker exec -it tarefa-app-test ./mvnw test${NC}"
        return 1
    fi
}

# ========================================
# FUNÇÃO: Reverter TEST para backup
# ========================================
revert_test() {
    echo -e "${BLUE}🔄 Listando backups do TEST...${NC}"
    
    BACKUPS=($(ls -d backup_test_* 2>/dev/null | sort -r))
    
    if [ ${#BACKUPS[@]} -eq 0 ]; then
        echo -e "${RED}❌ Nenhum backup do TEST encontrado!${NC}"
        return 1
    fi
    
    echo "Backups disponíveis:"
    for i in "${!BACKUPS[@]}"; do
        echo "$((i+1)). ${BACKUPS[$i]}"
    done
    
    read -p "Escolha o backup (número): " choice
    
    if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le "${#BACKUPS[@]}" ]; then
        SELECTED_BACKUP="${BACKUPS[$((choice-1))]}"
        
        echo -e "${BLUE}🔄 Revertendo TEST para: $SELECTED_BACKUP${NC}"
        
        # Restaurar arquivos
        cp -r "$SELECTED_BACKUP/src/" ./ 2>/dev/null || true
        cp "$SELECTED_BACKUP/pom.xml" ./ 2>/dev/null || true
        
        # Rebuild TEST
        echo -e "${BLUE}🏗️ Reconstruindo container TEST...${NC}"
        sudo docker-compose stop app-test
        sudo docker-compose build --no-cache app-test
        sudo docker-compose up -d app-test
        
        echo -e "${GREEN}✅ TEST revertido com sucesso!${NC}"
        check_test_health
    else
        echo -e "${RED}❌ Opção inválida!${NC}"
    fi
}

# ========================================
# FUNÇÃO: Aplicar migrações de banco no TEST
# ========================================
apply_database_migrations_test() {
    echo -e "${BLUE}🗄️ Aplicando migrações de banco no TEST...${NC}"
    
    # 1. Copiar migrações do container DEV (se existirem)
    TEMP_MIGRATIONS="temp_migrations_$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$TEMP_MIGRATIONS"
    
    # Extrair scripts de migração do DEV
    sudo docker cp tarefa-app-dev:/app/database/migrations.sql "$TEMP_MIGRATIONS/" 2>/dev/null || echo -e "${YELLOW}ℹ️ Nenhuma migração padrão encontrada${NC}"
    sudo docker cp tarefa-app-dev:/app/scripts "$TEMP_MIGRATIONS/" 2>/dev/null || echo -e "${YELLOW}ℹ️ Nenhum script customizado encontrado${NC}"
    
    # 2. Aplicar migrações no banco TEST
    if [ -f "$TEMP_MIGRATIONS/migrations.sql" ]; then
        echo -e "${BLUE}📝 Aplicando migrações estruturais no TEST...${NC}"
        
        # Copiar arquivo para container e executar
        sudo docker cp "$TEMP_MIGRATIONS/migrations.sql" postgres-test:/tmp/migrations.sql
        
        if sudo docker exec postgres-test psql -U test_user -d tarefa_test -f /tmp/migrations.sql 2>/dev/null; then
            echo -e "${GREEN}✅ Migrações aplicadas no banco TEST${NC}"
        else
            echo -e "${YELLOW}⚠️ Migrações já aplicadas ou erro menor${NC}"
        fi
        
        # Limpar arquivo temporário do container
        sudo docker exec postgres-test rm -f /tmp/migrations.sql 2>/dev/null || true
    fi
    
    # 3. Scripts customizados
    if [ -d "$TEMP_MIGRATIONS/scripts" ]; then
        echo -e "${BLUE}📝 Aplicando scripts customizados no TEST...${NC}"
        
        for script in "$TEMP_MIGRATIONS/scripts"/*.sql; do
            if [ -f "$script" ]; then
                filename=$(basename "$script")
                sudo docker cp "$script" postgres-test:/tmp/"$filename"
                sudo docker exec postgres-test psql -U test_user -d tarefa_test -f /tmp/"$filename" 2>/dev/null || true
                sudo docker exec postgres-test rm -f /tmp/"$filename" 2>/dev/null || true
                echo -e "${GREEN}✅ Script aplicado: $filename${NC}"
            fi
        done
    fi
    
    # Limpar arquivos temporários
    rm -rf "$TEMP_MIGRATIONS"
}

# ========================================
# FUNÇÃO: Backup do banco TEST
# ========================================
backup_database_test() {
    echo -e "${BLUE}💾 Fazendo backup do banco TEST...${NC}"
    
    TIMESTAMP=$(date +%Y%m%d_%H%M%S)
    BACKUP_FILE="backup_db_test_${TIMESTAMP}.sql"
    
    # Fazer dump do banco TEST preservando dados
    if sudo docker exec postgres-test pg_dump -U test_user tarefa_test > "$BACKUP_FILE"; then
        echo -e "${GREEN}✅ Backup do banco TEST criado: $BACKUP_FILE${NC}"
        return 0
    else
        echo -e "${RED}❌ Erro ao fazer backup do banco TEST${NC}"
        return 1
    fi
}

# ========================================
# FUNÇÃO: Verificar diferenças estruturais entre DEV e TEST
# ========================================
check_database_differences() {
    echo -e "${BLUE}🔍 Verificando diferenças estruturais entre DEV e TEST...${NC}"
    
    # Obter estrutura das tabelas do DEV
    DEV_STRUCTURE=$(sudo docker exec postgres-dev psql -U dev_user -d tarefa_dev -c "\d+" -t 2>/dev/null | head -20)
    
    # Obter estrutura das tabelas do TEST  
    TEST_STRUCTURE=$(sudo docker exec postgres-test psql -U test_user -d tarefa_test -c "\d+" -t 2>/dev/null | head -20)
    
    if [ "$DEV_STRUCTURE" != "$TEST_STRUCTURE" ]; then
        echo -e "${YELLOW}⚠️ Estruturas diferentes detectadas entre DEV e TEST${NC}"
        echo -e "${BLUE}💡 Migrações serão aplicadas para sincronizar${NC}"
        return 1
    else
        echo -e "${GREEN}✅ Estruturas de banco sincronizadas${NC}"
        return 0
    fi
}
transfer_dev_to_test() {
    echo -e "${BLUE}📦 Transferindo código do container DEV para TEST...${NC}"
    
    # 1. Verificar se container DEV está rodando
    echo -e "${BLUE}1️⃣ Verificando container DEV...${NC}"
    if ! sudo docker ps --format "table {{.Names}}" | grep -q "tarefa-app-dev"; then
        echo -e "${RED}❌ Container DEV não está rodando!${NC}"
        echo -e "${YELLOW}💡 Execute: ./start-pipeline.sh → Opção 1 (Iniciar DEV)${NC}"
        return 1
    fi
    echo -e "${GREEN}✅ Container DEV está rodando${NC}"
    
    # 2. Criar diretório temporário
    TEMP_DIR="temp_transfer_$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$TEMP_DIR"
    echo -e "${GREEN}✅ Diretório temporário criado: $TEMP_DIR${NC}"
    
    # 3. Extrair código do container DEV
    echo -e "${BLUE}2️⃣ Extraindo código do container DEV...${NC}"
    
    if sudo docker cp tarefa-app-dev:/app/src "$TEMP_DIR/"; then
        echo -e "${GREEN}✅ Código fonte extraído${NC}"
    else
        echo -e "${RED}❌ Erro ao extrair código fonte${NC}"
        rm -rf "$TEMP_DIR"
        return 1
    fi
    
    if sudo docker cp tarefa-app-dev:/app/pom.xml "$TEMP_DIR/"; then
        echo -e "${GREEN}✅ pom.xml extraído${NC}"
    else
        echo -e "${YELLOW}⚠️ pom.xml não encontrado (continuando...)${NC}"
    fi
    
    # Tentar extrair target (compilado) - opcional
    sudo docker cp tarefa-app-dev:/app/target "$TEMP_DIR/" 2>/dev/null && echo -e "${GREEN}✅ Target extraído${NC}" || echo -e "${YELLOW}ℹ️ Target não extraído (será recompilado)${NC}"
    
    # 4. Fazer backup do TEST atual (código E banco)
    echo -e "${BLUE}3️⃣ Fazendo backup do TEST atual...${NC}"
    backup_test_current
    backup_database_test
    
    # 5. Verificar e aplicar migrações de banco
    echo -e "${BLUE}4️⃣ Verificando estrutura de banco...${NC}"
    check_database_differences
    apply_database_migrations_test
    
    # 6. Parar container TEST
    echo -e "${BLUE}5️⃣ Parando container TEST...${NC}"
    sudo docker-compose stop app-test
    echo -e "${GREEN}✅ Container TEST parado${NC}"
    
    # 7. Atualizar código local
    echo -e "${BLUE}6️⃣ Atualizando código local...${NC}"
    
    if [ -d "$TEMP_DIR/src" ]; then
        cp -r "$TEMP_DIR/src" ./
        echo -e "${GREEN}✅ Código fonte atualizado${NC}"
    else
        echo -e "${RED}❌ Código fonte não encontrado!${NC}"
        rm -rf "$TEMP_DIR"
        return 1
    fi
    
    if [ -f "$TEMP_DIR/pom.xml" ]; then
        cp "$TEMP_DIR/pom.xml" ./
        echo -e "${GREEN}✅ pom.xml atualizado${NC}"
    fi
    
    # 8. Reconstruir container TEST
    echo -e "${BLUE}7️⃣ Reconstruindo container TEST...${NC}"
    if sudo docker-compose build --no-cache app-test; then
        echo -e "${GREEN}✅ Container TEST reconstruído${NC}"
    else
        echo -e "${RED}❌ Erro ao reconstruir container TEST${NC}"
        rm -rf "$TEMP_DIR"
        return 1
    fi
    
    # 9. Iniciar container TEST
    echo -e "${BLUE}8️⃣ Iniciando container TEST...${NC}"
    if sudo docker-compose up -d app-test; then
        echo -e "${GREEN}✅ Container TEST iniciado${NC}"
    else
        echo -e "${RED}❌ Erro ao iniciar container TEST${NC}"
        rm -rf "$TEMP_DIR"
        return 1
    fi
    
    # 9. Limpar arquivos temporários
    rm -rf "$TEMP_DIR"
    echo -e "${GREEN}✅ Arquivos temporários limpos${NC}"
    
    # 11. Verificar saúde
    echo -e "${BLUE}9️⃣ Verificando saúde do TEST...${NC}"
    if check_test_health; then
        echo -e "${GREEN}🎉 Transferência concluída com sucesso!${NC}"
        show_environments_diff
        return 0
    else
        echo -e "${RED}❌ Transferência concluída, mas TEST com problemas${NC}"
        return 1
    fi
}

# ========================================
# MENU SIMPLIFICADO
# ========================================
show_menu() {
    echo ""
    echo -e "${YELLOW}Escolha uma opção:${NC}"
    echo "1. 🔄 Transferir código DEV → TEST"
    echo "2. 🧪 Executar testes no TEST"
    echo "3. 📊 Ver status dos ambientes"
    echo "4. 📝 Ver logs do TEST"
    echo "5. 🔄 Reverter TEST (usar backup)"
    echo "6. 🧹 Limpar backups antigos"
    echo "7. 🚪 Sair"
    echo ""
}

# ========================================
# FUNÇÃO: Limpar backups antigos
# ========================================
clean_old_backups() {
    echo -e "${BLUE}🧹 Limpando backups antigos do TEST...${NC}"
    
    BACKUPS=($(ls -d backup_test_* 2>/dev/null | sort -r))
    
    if [ ${#BACKUPS[@]} -gt 5 ]; then
        echo -e "${YELLOW}📦 Mantendo apenas os 5 backups mais recentes...${NC}"
        for ((i=5; i<${#BACKUPS[@]}; i++)); do
            rm -rf "${BACKUPS[$i]}"
            echo -e "${GREEN}🗑️  Removido: ${BACKUPS[$i]}${NC}"
        done
        echo -e "${GREEN}✅ Limpeza concluída${NC}"
    else
        echo -e "${YELLOW}💡 Menos de 5 backups, nada para limpar${NC}"
    fi
}

# ========================================
# EXECUÇÃO PRINCIPAL
# ========================================
if [ $# -eq 0 ]; then
    # Menu interativo
    while true; do
        show_menu
        read -p "Digite sua opção (1-7): " option
        
        case $option in
            1) transfer_dev_to_test ;;
            2) run_tests_on_test ;;
            3) sudo docker-compose ps ;;
            4) sudo docker-compose logs -f app-test ;;
            5) revert_test ;;
            6) clean_old_backups ;;
            7) 
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
        "transfer") transfer_dev_to_test ;;
        "test") run_tests_on_test ;;
        "revert") revert_test ;;
        "clean") clean_old_backups ;;
        *) 
            echo -e "${YELLOW}Uso: $0 [transfer|test|revert|clean]${NC}"
            echo "Ou execute sem parâmetros para menu interativo"
            ;;
    esac
fi