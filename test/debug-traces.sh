#!/bin/bash

echo "======================================"
echo "Debug de Traces - Sistema de Temperatura"
echo "======================================"
echo ""

echo "1. Verificando containers..."
docker-compose ps
echo ""

echo "2. Verificando logs do OTEL Collector..."
echo "Últimas 20 linhas:"
docker-compose logs --tail=20 otel-collector
echo ""

echo "3. Verificando logs do Service A..."
docker-compose logs service-a | grep -i "otel\|trace\|span" | tail -10
echo ""

echo "4. Verificando logs do Service B..."
docker-compose logs service-b | grep -i "otel\|trace\|span" | tail -10
echo ""

echo "5. Testando conectividade OTEL Collector..."
docker-compose exec service-a ping -c 2 otel-collector 2>/dev/null || echo "Não foi possível pingar otel-collector"
echo ""

echo "6. Verificando endpoint OTEL nas variáveis de ambiente..."
echo "Service A:"
docker-compose exec service-a env | grep OTEL
echo ""
echo "Service B:"
docker-compose exec service-b env | grep OTEL
echo ""

echo "7. Fazendo uma requisição de teste..."
curl -s -X POST http://localhost:8080/cep \
  -H "Content-Type: application/json" \
  -d '{"cep":"01310100"}' | jq
echo ""

echo "8. Aguardando 5 segundos para traces propagarem..."
sleep 5

echo "9. Verificando logs do OTEL após requisição..."
docker-compose logs --tail=10 otel-collector | grep -i "trace\|span\|export"
echo ""

echo "10. Tentando acessar API do Zipkin..."
echo "Traces disponíveis:"
curl -s http://localhost:9411/api/v2/traces?limit=1 | jq '.[0].traceId' 2>/dev/null || echo "Nenhum trace encontrado"
echo ""

echo "11. Verificando serviços registrados no Zipkin..."
curl -s http://localhost:9411/api/v2/services | jq
echo ""

echo "======================================"
echo "Diagnóstico Completo"
echo "======================================"
echo ""
echo "Se não houver traces:"
echo "1. Verifique se OTEL_EXPORTER_OTLP_ENDPOINT está correto"
echo "2. Reconstrua as imagens: docker-compose up -d --build"
echo "3. Verifique logs: docker-compose logs otel-collector"
echo ""