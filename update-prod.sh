#!/bin/bash

# Script para atualizar ambiente PRODUÇÃO com código do ambiente TEST
# Método: Container para Container (local)
# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Atualizando ambiente PRODUÇÃO com código do TEST${NC}"
echo "=================================================="

# ========================================
# FUNÇÃO: Fazer backup do PROD atual
# ========================================
backup_prod_current() {
    echo -e "${BLUE}💾 Fazendo backup do PROD atual...${NC}"
    
    TIMESTAMP=$(date +%Y%m%d_%H%M%S)
    BACKUP_DIR="backup_prod_${TIMESTAMP}"
    
    mkdir -p "$BACKUP_DIR"
    cp -r src/ "$BACKUP_DIR/" 2>/dev/null || true
    cp pom.xml "$BACKUP_DIR/" 2>/dev/null || true
    
    echo -e "${GREEN}✅ Backup PROD criado: $BACKUP_DIR${NC}"
}

# ========================================
# FUNÇÃO: Verificar saúde do PROD
# ========================================
check_prod_health() {
    echo -e "${BLUE}🔍 Verificando saúde do PROD...${NC}"
    
    sleep 20  # PROD pode demorar mais para inicializar
    
    if curl -f http://localhost:8087/api/status > /dev/null 2>&1; then
        echo -e "${GREEN}✅ PROD funcionando: http://localhost:8087${NC}"
        return 0
    else
        echo -e "${RED}❌ PROD com problemas!${NC}"
        echo -e "${YELLOW}💡 Verificar logs: sudo docker-compose logs app-prod${NC}"
        return 1
    fi
}

# ========================================
# FUNÇÃO: Mostrar diferenças entre ambientes
# ========================================
show_environments_diff() {
    echo -e "${BLUE}📊 Status dos ambientes após atualização:${NC}"
    echo "  🔧 DEV:  Código original"
    echo "  🧪 TEST: Código original"  
    echo "  🚀 PROD: Código atualizado do TEST ← ATUALIZADO"
    echo ""
    echo -e "${YELLOW}URLs para validar:${NC}"
    echo "  DEV:  http://localhost:8085"
    echo "  TEST: http://localhost:8086"
    echo "  PROD: http://localhost:8087 ← VALIDAR AQUI"
    echo ""
    echo -e "${RED}⚠️  IMPORTANTE: Teste bem antes de usar em produção real!${NC}"
}

# ========================================
# FUNÇÃO: Executar testes unitários no PROD
# ========================================
run_tests_on_prod() {
    echo -e "${BLUE}🧪 Executando testes unitários no ambiente PROD...${NC}"
    
    if sudo docker exec tarefa-app-prod ./mvnw test 2>/dev/null; then
        echo -e "${GREEN}✅ Todos os testes passaram no PROD!${NC}"
        return 0
    else
        echo -e "${RED}❌ Alguns testes falharam no PROD!${NC}"
        echo -e "${YELLOW}💡 Para ver detalhes: sudo docker exec -it tarefa-app-prod ./mvnw test${NC}"
        return 1
    fi
}

# ========================================
# FUNÇÃO: Smoke Tests em PROD
# ========================================
run_smoke_tests() {
    echo -e "${BLUE}💨 Executando Smoke Tests no PROD...${NC}"
    
    local failed=0
    
    # Teste 1: API Status
    echo -n "🔍 Testando API Status... "
    if curl -f http://localhost:8087/api/status > /dev/null 2>&1; then
        echo -e "${GREEN}✅${NC}"
    else
        echo -e "${RED}❌${NC}"
        failed=1
    fi
    
    # Teste 2: Listar Tarefas
    echo -n "🔍 Testando Lista de Tarefas... "
    if curl -f http://localhost:8087/api/tarefas > /dev/null 2>&1; then
        echo -e "${GREEN}✅${NC}"
    else
        echo -e "${RED}❌${NC}"
        failed=1
    fi
    
    # Teste 3: Teste de Banco
    echo -n "🔍 Testando Conexão com Banco... "
    if curl -f http://localhost:8087/api/test-db > /dev/null 2>&1; then
        echo -e "${GREEN}✅${NC}"
    else
        echo -e "${RED}❌${NC}"
        failed=1
    fi
    
    # Teste 4: Página Principal
    echo -n "🔍 Testando Página Principal... "
    if curl -f http://localhost:8087/ > /dev/null 2>&1; then
        echo -e "${GREEN}✅${NC}"
    else
        echo -e "${RED}❌${NC}"
        failed=1
    fi
    
    if [ $failed -eq 0 ]; then
        echo -e "${GREEN}🎉 Todos os Smoke Tests passaram!${NC}"
        return 0
    else
        echo -e "${RED}💥 Alguns Smoke Tests falharam!${NC}"
        return 1
    fi
}

# ========================================
# FUNÇÃO: Reverter PROD para backup
# ========================================
revert_prod() {
    echo -e "${RED}⚠️  ATENÇÃO: Você está revertendo PRODUÇÃO!${NC}"
    read -p "Tem certeza? Digite 'CONFIRMO' para continuar: " confirm
    
    if [ "$confirm" != "CONFIRMO" ]; then
        echo -e "${YELLOW}❌ Operação cancelada${NC}"
        return 1
    fi
    
    echo -e "${BLUE}🔄 Listando backups do PROD...${NC}"
    
    BACKUPS=($(ls -d backup_prod_* 2>/dev/null | sort -r))
    
    if [ ${#BACKUPS[@]} -eq 0 ]; then
        echo -e "${RED}❌ Nenhum backup do PROD encontrado!${NC}"
        return 1
    fi
    
    echo "Backups disponíveis:"
    for i in "${!BACKUPS[@]}"; do
        echo "$((i+1)). ${BACKUPS[$i]}"
    done
    
    read -p "Escolha o backup (número): " choice
    
    if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le "${#BACKUPS[@]}" ]; then
        SELECTED_BACKUP="${BACKUPS[$((choice-1))]}"
        
        echo -e "${BLUE}🔄 Revertendo PROD para: $SELECTED_BACKUP${NC}"
        
        # Restaurar arquivos
        cp -r "$SELECTED_BACKUP/src/" ./ 2>/dev/null || true
        cp "$SELECTED_BACKUP/pom.xml" ./ 2>/dev/null || true
        
        # Rebuild PROD
        echo -e "${BLUE}🏗️ Reconstruindo container PROD...${NC}"
        sudo docker-compose stop app-prod
        sudo docker-compose build --no-cache app-prod
        sudo docker-compose up -d app-prod
        
        echo -e "${GREEN}✅ PROD revertido com sucesso!${NC}"
        check_prod_health
    else
        echo -e "${RED}❌ Opção inválida!${NC}"
    fi
}

# ========================================
# FUNÇÃO: Aplicar migrações de banco no PROD
# ========================================
apply_database_migrations_prod() {
    echo -e "${BLUE}🗄️ Aplicando migrações de banco no PROD...${NC}"
    echo -e "${RED}⚠️ CUIDADO: Aplicando mudanças estruturais em PRODUÇÃO${NC}"
    
    # 1. Fazer backup adicional do banco PROD antes das migrações
    echo -e "${BLUE}💾 Backup adicional antes das migrações...${NC}"
    TIMESTAMP=$(date +%Y%m%d_%H%M%S)
    BACKUP_FILE="backup_prod_pre_migration_${TIMESTAMP}.sql"
    
    if sudo docker exec postgres-prod pg_dump -U prod_user tarefa_prod > "$BACKUP_FILE"; then
        echo -e "${GREEN}✅ Backup pré-migração criado: $BACKUP_FILE${NC}"
    else
        echo -e "${RED}❌ ERRO: Falha no backup pré-migração! Abortando...${NC}"
        return 1
    fi
    
    # 2. Copiar migrações do container TEST
    TEMP_MIGRATIONS="temp_migrations_prod_$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$TEMP_MIGRATIONS"
    
    # Extrair scripts de migração do TEST
    sudo docker cp tarefa-app-test:/app/database/migrations.sql "$TEMP_MIGRATIONS/" 2>/dev/null || echo -e "${YELLOW}ℹ️ Nenhuma migração padrão encontrada${NC}"
    sudo docker cp tarefa-app-test:/app/scripts "$TEMP_MIGRATIONS/" 2>/dev/null || echo -e "${YELLOW}ℹ️ Nenhum script customizado encontrado${NC}"
    
    # 3. Aplicar migrações no banco PROD
    if [ -f "$TEMP_MIGRATIONS/migrations.sql" ]; then
        echo -e "${BLUE}📝 Aplicando migrações estruturais no PROD...${NC}"
        
        # Copiar arquivo para container e executar
        sudo docker cp "$TEMP_MIGRATIONS/migrations.sql" postgres-prod:/tmp/migrations.sql
        
        if sudo docker exec postgres-prod psql -U prod_user -d tarefa_prod -f /tmp/migrations.sql; then
            echo -e "${GREEN}✅ Migrações aplicadas no banco PROD${NC}"
        else
            echo -e "${RED}❌ ERRO nas migrações do PROD!${NC}"
            echo -e "${YELLOW}💡 Considere restaurar backup: $BACKUP_FILE${NC}"
            # Limpar e sair
            sudo docker exec postgres-prod rm -f /tmp/migrations.sql 2>/dev/null || true
            rm -rf "$TEMP_MIGRATIONS"
            return 1
        fi
        
        # Limpar arquivo temporário do container
        sudo docker exec postgres-prod rm -f /tmp/migrations.sql 2>/dev/null || true
    fi
    
    # 4. Scripts customizados (com mais cuidado)
    if [ -d "$TEMP_MIGRATIONS/scripts" ]; then
        echo -e "${BLUE}📝 Aplicando scripts customizados no PROD...${NC}"
        
        for script in "$TEMP_MIGRATIONS/scripts"/*.sql; do
            if [ -f "$script" ]; then
                filename=$(basename "$script")
                echo -e "${YELLOW}🔄 Aplicando: $filename${NC}"
                
                sudo docker cp "$script" postgres-prod:/tmp/"$filename"
                
                if sudo docker exec postgres-prod psql -U prod_user -d tarefa_prod -f /tmp/"$filename"; then
                    echo -e "${GREEN}✅ Script aplicado: $filename${NC}"
                else
                    echo -e "${RED}❌ ERRO no script: $filename${NC}"
                    echo -e "${YELLOW}💡 Continuando com próximo script...${NC}"
                fi
                
                sudo docker exec postgres-prod rm -f /tmp/"$filename" 2>/dev/null || true
            fi
        done
    fi
    
    # Limpar arquivos temporários
    rm -rf "$TEMP_MIGRATIONS"
    
    echo -e "${GREEN}✅ Migrações de banco PROD concluídas${NC}"
}

# ========================================
# FUNÇÃO: Backup completo do banco PROD
# ========================================
backup_database_prod() {
    echo -e "${BLUE}💾 Fazendo backup completo do banco PROD...${NC}"
    
    TIMESTAMP=$(date +%Y%m%d_%H%M%S)
    BACKUP_FILE="backup_db_prod_${TIMESTAMP}.sql"
    
    # Fazer dump completo do banco PROD
    if sudo docker exec postgres-prod pg_dump -U prod_user tarefa_prod > "$BACKUP_FILE"; then
        echo -e "${GREEN}✅ Backup completo do PROD criado: $BACKUP_FILE${NC}"
        
        # Comprimir backup para economizar espaço
        gzip "$BACKUP_FILE" 2>/dev/null && echo -e "${GREEN}✅ Backup comprimido: ${BACKUP_FILE}.gz${NC}" || true
        
        return 0
    else
        echo -e "${RED}❌ ERRO CRÍTICO: Falha no backup do banco PROD${NC}"
        return 1
    fi
}

# ========================================
# FUNÇÃO: Verificar integridade do banco após migração
# ========================================
verify_database_integrity() {
    echo -e "${BLUE}🔍 Verificando integridade do banco PROD...${NC}"
    
    # 1. Verificar se tabelas principais existem
    echo -n "🔍 Verificando tabela principal... "
    if sudo docker exec postgres-prod psql -U prod_user -d tarefa_prod -c "SELECT COUNT(*) FROM tarefa;" > /dev/null 2>&1; then
        echo -e "${GREEN}✅${NC}"
    else
        echo -e "${RED}❌${NC}"
        return 1
    fi
    
    # 2. Verificar constraints e índices
    echo -n "🔍 Verificando constraints... "
    if sudo docker exec postgres-prod psql -U prod_user -d tarefa_prod -c "SELECT * FROM information_schema.table_constraints WHERE table_name='tarefa';" > /dev/null 2>&1; then
        echo -e "${GREEN}✅${NC}"
    else
        echo -e "${RED}❌${NC}"
        return 1
    fi
    
    # 3. Teste de inserção/seleção simples
    echo -n "🔍 Teste de operação básica... "
    if sudo docker exec postgres-prod psql -U prod_user -d tarefa_prod -c "SELECT 1;" > /dev/null 2>&1; then
        echo -e "${GREEN}✅${NC}"
    else
        echo -e "${RED}❌${NC}"
        return 1
    fi
    
    echo -e "${GREEN}✅ Integridade do banco verificada${NC}"
    return 0
}
transfer_test_to_prod() {
    echo -e "${RED}⚠️  ATENÇÃO: Você está atualizando PRODUÇÃO!${NC}"
    echo -e "${YELLOW}📋 Esta operação vai:${NC}"
    echo "   1. Fazer backup do PROD atual"
    echo "   2. Copiar código do TEST para PROD"
    echo "   3. Rebuild do container PROD"
    echo "   4. Executar testes de validação"
    echo ""
    
    read -p "Continuar? Digite 'SIM' para confirmar: " confirm
    
    if [ "$confirm" != "SIM" ]; then
        echo -e "${YELLOW}❌ Operação cancelada pelo usuário${NC}"
        return 1
    fi
    
    echo -e "${BLUE}📦 Transferindo código do container TEST para PROD...${NC}"
    
    # 1. Verificar se container TEST está rodando
    echo -e "${BLUE}1️⃣ Verificando container TEST...${NC}"
    if ! sudo docker ps --format "table {{.Names}}" | grep -q "tarefa-app-test"; then
        echo -e "${RED}❌ Container TEST não está rodando!${NC}"
        echo -e "${YELLOW}💡 Execute: ./start-pipeline.sh → Opção 2 (Iniciar TEST)${NC}"
        return 1
    fi
    echo -e "${GREEN}✅ Container TEST está rodando${NC}"
    
    # 2. Verificar se container PROD está rodando
    echo -e "${BLUE}2️⃣ Verificando container PROD...${NC}"
    if ! sudo docker ps --format "table {{.Names}}" | grep -q "tarefa-app-prod"; then
        echo -e "${YELLOW}⚠️  Container PROD não está rodando, iniciando...${NC}"
        sudo docker-compose up -d app-prod postgres-prod
        sleep 10
    fi
    echo -e "${GREEN}✅ Container PROD verificado${NC}"
    
    # 3. Criar diretório temporário
    TEMP_DIR="temp_test_to_prod_$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$TEMP_DIR"
    echo -e "${GREEN}✅ Diretório temporário criado: $TEMP_DIR${NC}"
    
    # 4. Extrair código do container TEST
    echo -e "${BLUE}3️⃣ Extraindo código do container TEST...${NC}"
    
    if sudo docker cp tarefa-app-test:/app/src "$TEMP_DIR/"; then
        echo -e "${GREEN}✅ Código fonte extraído do TEST${NC}"
    else
        echo -e "${RED}❌ Erro ao extrair código fonte do TEST${NC}"
        rm -rf "$TEMP_DIR"
        return 1
    fi
    
    if sudo docker cp tarefa-app-test:/app/pom.xml "$TEMP_DIR/"; then
        echo -e "${GREEN}✅ pom.xml extraído do TEST${NC}"
    else
        echo -e "${YELLOW}⚠️ pom.xml não encontrado no TEST${NC}"
    fi
    
    # 5. Fazer backup do PROD atual (código E banco)
    echo -e "${BLUE}4️⃣ Fazendo backup completo do PROD...${NC}"
    backup_prod_current
    
    # CRÍTICO: Backup do banco antes de qualquer alteração
    if ! backup_database_prod; then
        echo -e "${RED}❌ FALHA CRÍTICA: Não foi possível fazer backup do banco PROD${NC}"
        echo -e "${RED}🛑 OPERAÇÃO ABORTADA POR SEGURANÇA${NC}"
        rm -rf "$TEMP_DIR"
        return 1
    fi
    
    # 6. Aplicar migrações de banco PRIMEIRO (antes de rebuild)
    echo -e "${BLUE}5️⃣ Aplicando migrações de banco...${NC}"
    if ! apply_database_migrations_prod; then
        echo -e "${RED}❌ FALHA nas migrações de banco${NC}"
        echo -e "${YELLOW}💡 Banco pode estar inconsistente - considere restaurar backup${NC}"
        rm -rf "$TEMP_DIR"
        return 1
    fi
    
    # 7. Verificar integridade do banco após migrações
    echo -e "${BLUE}6️⃣ Verificando integridade do banco...${NC}"
    if ! verify_database_integrity; then
        echo -e "${RED}❌ FALHA na verificação de integridade${NC}"
        echo -e "${YELLOW}💡 Considere restaurar backup do banco${NC}"
        rm -rf "$TEMP_DIR"
        return 1
    fi
    
    # 8. Parar container PROD
    echo -e "${BLUE}7️⃣ Parando container PROD...${NC}"
    sudo docker-compose stop app-prod
    echo -e "${GREEN}✅ Container PROD parado${NC}"
    
    # 9. Atualizar código local
    echo -e "${BLUE}8️⃣ Atualizando código local...${NC}"
    
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
    
    # 10. Reconstruir container PROD
    echo -e "${BLUE}9️⃣ Reconstruindo container PROD...${NC}"
    if sudo docker-compose build --no-cache app-prod; then
        echo -e "${GREEN}✅ Container PROD reconstruído${NC}"
    else
        echo -e "${RED}❌ Erro ao reconstruir container PROD${NC}"
        rm -rf "$TEMP_DIR"
        return 1
    fi
    
    # 11. Iniciar container PROD
    echo -e "${BLUE}🔟 Iniciando container PROD...${NC}"
    if sudo docker-compose up -d app-prod; then
        echo -e "${GREEN}✅ Container PROD iniciado${NC}"
    else
        echo -e "${RED}❌ Erro ao iniciar container PROD${NC}"
        rm -rf "$TEMP_DIR"
        return 1
    fi
    
    # 10. Limpar arquivos temporários
    rm -rf "$TEMP_DIR"
    echo -e "${GREEN}✅ Arquivos temporários limpos${NC}"
    
    # 11. Verificar saúde e executar testes
    echo -e "${BLUE}9️⃣ Verificando saúde do PROD...${NC}"
    if check_prod_health; then
        echo -e "${BLUE}🔟 Executando Smoke Tests...${NC}"
        if run_smoke_tests; then
            echo -e "${GREEN}🎉 Deploy em PRODUÇÃO concluído com sucesso!${NC}"
            show_environments_diff
            return 0
        else
            echo -e "${RED}❌ Smoke Tests falharam!${NC}"
            echo -e "${YELLOW}💡 Considere reverter: ./update-prod.sh → Opção 5${NC}"
            return 1
        fi
    else
        echo -e "${RED}❌ PROD com problemas após deploy${NC}"
        echo -e "${YELLOW}💡 Considere reverter: ./update-prod.sh → Opção 5${NC}"
        return 1
    fi
}

# ========================================
# MENU SIMPLIFICADO
# ========================================
show_menu() {
    echo ""
    echo -e "${YELLOW}Escolha uma opção:${NC}"
    echo "1. 🚀 Transferir código TEST → PROD"
    echo "2. 💨 Executar Smoke Tests no PROD"
    echo "3. 🧪 Executar testes unitários no PROD"
    echo "4. 📊 Ver status dos ambientes"
    echo "5. 📝 Ver logs do PROD"
    echo "6. 🔄 Reverter PROD (usar backup)"
    echo "7. 🧹 Limpar backups antigos"
    echo "8. 🚪 Sair"
    echo ""
}

# ========================================
# FUNÇÃO: Limpar backups antigos
# ========================================
clean_old_backups() {
    echo -e "${BLUE}🧹 Limpando backups antigos do PROD...${NC}"
    
    BACKUPS=($(ls -d backup_prod_* 2>/dev/null | sort -r))
    
    if [ ${#BACKUPS[@]} -gt 3 ]; then
        echo -e "${YELLOW}📦 Mantendo apenas os 3 backups mais recentes de PROD...${NC}"
        for ((i=3; i<${#BACKUPS[@]}; i++)); do
            rm -rf "${BACKUPS[$i]}"
            echo -e "${GREEN}🗑️  Removido: ${BACKUPS[$i]}${NC}"
        done
        echo -e "${GREEN}✅ Limpeza concluída${NC}"
    else
        echo -e "${YELLOW}💡 Menos de 3 backups, nada para limpar${NC}"
    fi
}

# ========================================
# EXECUÇÃO PRINCIPAL
# ========================================
if [ $# -eq 0 ]; then
    # Menu interativo
    while true; do
        show_menu
        read -p "Digite sua opção (1-8): " option
        
        case $option in
            1) transfer_test_to_prod ;;
            2) run_smoke_tests ;;
            3) run_tests_on_prod ;;
            4) sudo docker-compose ps ;;
            5) sudo docker-compose logs -f app-prod ;;
            6) revert_prod ;;
            7) clean_old_backups ;;
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
    # Execução direta
    case $1 in
        "deploy") transfer_test_to_prod ;;
        "smoke") run_smoke_tests ;;
        "test") run_tests_on_prod ;;
        "revert") revert_prod ;;
        "clean") clean_old_backups ;;
        *) 
            echo -e "${YELLOW}Uso: $0 [deploy|smoke|test|revert|clean]${NC}"
            echo "Ou execute sem parâmetros para menu interativo"
            ;;
    esac
fi