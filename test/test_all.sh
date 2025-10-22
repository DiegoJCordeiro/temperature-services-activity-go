#!/bin/bash

# Script de teste completo para o sistema

set -e

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

test_passed=0
test_failed=0

echo -e "${BLUE}======================================"
echo "Suite de Testes - Sistema de Temperatura"
echo -e "======================================${NC}"
echo ""

# Função para testar requisições
test_request() {
    local test_name=$1
    local expected_status=$2
    local cep=$3
    local expected_content=$4

    echo -n "[$((test_passed + test_failed + 1))] Testando: $test_name... "

    response=$(curl -s -w "\n%{http_code}" -X POST http://localhost:8080/cep \
        -H "Content-Type: application/json" \
        -d "{\"cep\":\"$cep\"}" 2>/dev/null)

    status=$(echo "$response" | tail -n1)
    body=$(echo "$response" | head -n-1)

    set +e
    if [ "$status" -eq "$expected_status" ]; then
        if [ -n "$expected_content" ]; then
            if echo "$body" | grep -q "$expected_content"; then
                echo -e "${GREEN}✓ PASSOU${NC}"
                ((test_passed++))
            else
                echo -e "${RED}✗ FALHOU${NC} (conteúdo incorreto)"
                echo "   Esperado: $expected_content"
                echo "   Recebido: $body"
                ((test_failed++))
            fi
        else
            echo -e "${GREEN}✓ PASSOU${NC}"
            ((test_passed++))
        fi
    else
        echo -e "${RED}✗ FALHOU${NC} (status incorreto)"
        echo "   Esperado: HTTP $expected_status"
        echo "   Recebido: HTTP $status"
        echo "   Body: $body"
        ((test_failed++))
    fi
  set -e
}

echo -e "${YELLOW}=== Testes de Validação ===${NC}"
echo ""

# Testes de CEP inválido
test_request "CEP com 3 dígitos" 422 "123" "invalid zipcode"
test_request "CEP com 7 dígitos" 422 "0123456" "invalid zipcode"
test_request "CEP com 9 dígitos" 422 "012345678" "invalid zipcode"
test_request "CEP com letras" 422 "0123456A" "invalid zipcode"
test_request "CEP com traço" 422 "01234-567" "invalid zipcode"
test_request "CEP com espaço" 422 "0123 4567" "invalid zipcode"
test_request "CEP vazio" 422 "" "invalid zipcode"

echo ""
echo -e "${YELLOW}=== Testes de CEP Não Encontrado ===${NC}"
echo ""

test_request "CEP inexistente (99999999)" 500 "99999999" '{"message":"internal server error"}'
test_request "CEP inexistente (00000000)" 500 "00000000" '{"message":"internal server error"}'

echo ""
echo -e "${YELLOW}=== Teste de Tracing ===${NC}"
echo ""

echo -n "Gerando trace... "
curl -s -X POST http://localhost:8080/cep \
    -H "Content-Type: application/json" \
    -d '{"cep":"01310100"}' > /dev/null
echo -e "${GREEN}✓${NC}"

echo -n "Aguardando propagação para Zipkin (10s)... "
sleep 10
echo -e "${GREEN}✓${NC}"

echo "Verifique traces em: http://localhost:9411"
echo ""

echo -e "${BLUE}======================================"
echo "Resultado dos Testes"
echo -e "======================================${NC}"
echo ""
echo -e "${GREEN}Testes aprovados: $test_passed${NC}"
echo -e "${RED}Testes falhados: $test_failed${NC}"
echo -e "Total: $((test_passed + test_failed))"
echo ""

if [ $test_failed -eq 0 ]; then
    echo -e "${GREEN}✓✓✓ TODOS OS TESTES PASSARAM! ✓✓✓${NC}"
    echo ""
    echo "Próximos passos:"
    echo "1. Acesse Zipkin: http://localhost:9411"
    echo "2. Clique em 'Run Query' para ver traces"
    echo "3. Explore os spans e latências"
    exit 0
else
    echo -e "${RED}✗✗✗ ALGUNS TESTES FALHARAM ✗✗✗${NC}"
    echo ""
    echo "Para debug:"
    echo "• Ver logs: docker-compose logs"
    echo "• Ver status: docker-compose ps"
    echo "• Troubleshooting: consulte TROUBLESHOOTING.md"
    exit 1
fi