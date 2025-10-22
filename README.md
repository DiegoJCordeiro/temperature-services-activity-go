# Sistema de Temperatura por CEP com OTEL e Zipkin

Sistema distribuído em Go que recebe um CEP brasileiro, identifica a cidade e retorna a temperatura atual em Celsius, Fahrenheit e Kelvin, implementando tracing distribuído com OpenTelemetry e Zipkin.

## 📋 Visão Geral

O sistema é composto por dois serviços independentes:

- **Serviço A (Input)**: Recebe requisições HTTP com CEP, valida o formato e encaminha para o Serviço B
- **Serviço B (Orquestração)**: Consulta o CEP no ViaCEP, busca a temperatura no WeatherAPI e retorna os dados formatados
- **OpenTelemetry Collector**: Coleta traces dos serviços
- **Zipkin**: Visualiza traces distribuídos

## 🏗️ Arquitetura

```
Cliente → Serviço A (validação) → Serviço B (orquestração) → APIs Externas
                ↓                        ↓
         OTEL Collector → Zipkin (visualização de traces)
```

## 🎯 Requisitos Atendidos

### Serviço A
- ✅ Recebe POST com CEP de 8 dígitos
- ✅ Valida se é string e contém apenas números
- ✅ Retorna 422 com "invalid zipcode" para formato inválido
- ✅ Encaminha para Serviço B via HTTP

### Serviço B
- ✅ Consulta localização via ViaCEP
- ✅ Consulta temperatura via WeatherAPI
- ✅ Converte para Celsius, Fahrenheit e Kelvin
- ✅ Retorna 200 com dados completos
- ✅ Retorna 404 com "can not find zipcode" para CEP inexistente
- ✅ Retorna 422 com "invalid zipcode" para formato incorreto

### Observabilidade
- ✅ Tracing distribuído entre serviços
- ✅ Spans medindo tempo de operações
- ✅ Visualização no Zipkin

## 🚀 Como Executar

### Pré-requisitos

- Docker e Docker Compose instalados
- Chave de API do WeatherAPI (gratuita em https://www.weatherapi.com/)

### 1. Configuração

Crie um arquivo `.env` na raiz do projeto:

```env
WEATHER_API_KEY=sua_chave_aqui
```

### 2. Iniciar os Serviços

```bash
docker-compose up -d
```

**Importante**: Aguarde cerca de 30-40 segundos para todos os serviços iniciarem completamente. O OTEL Collector precisa iniciar antes dos serviços de aplicação.

### 3. Verificar Status

```bash
docker-compose ps
```

Todos os containers devem estar com status "Up":
- `zipkin` - Up
- `otel-collector` - Up
- `service-a` - Up
- `service-b` - Up

**Se algum container não iniciar**, veja a seção de [Troubleshooting](#-troubleshooting).

### 4. Testar a Aplicação

**CEP válido (200 OK):**
```bash
curl -X POST http://localhost:8080/cep \
  -H "Content-Type: application/json" \
  -d '{"cep":"01310100"}'
```

**Resposta esperada:**
```json
{
  "city": "São Paulo",
  "temp_C": 28.5,
  "temp_F": 83.3,
  "temp_K": 301.5
}
```

**CEP com formato inválido (422):**
```bash
curl -X POST http://localhost:8080/cep \
  -H "Content-Type: application/json" \
  -d '{"cep":"123"}'
```

**Resposta esperada:**
```json
{
  "message": "invalid zipcode"
}
```

**CEP não encontrado (404):**
```bash
curl -X POST http://localhost:8080/cep \
  -H "Content-Type: application/json" \
  -d '{"cep":"99999999"}'
```

**Resposta esperada:**
```json
{
  "message": "can not find zipcode"
}
```

### 5. Visualizar Traces no Zipkin

1. Faça algumas requisições ao sistema (como nos exemplos acima)
2. Aguarde 10-15 segundos para os traces serem exportados
3. Acesse http://localhost:9411
4. Clique no botão **"Run Query"**
5. Você verá a lista de traces
6. Clique em qualquer trace para ver os detalhes
7. Observe os spans distribuídos:
   - `handle-cep-request` (Serviço A) - Processamento completo
   - `validate-cep` (Serviço A) - Validação do CEP
   - `forward-to-service-b` (Serviço A) - Comunicação com Serviço B
   - `handle-weather-request` (Serviço B) - Orquestração
   - `fetch-location-viacep` (Serviço B) - Consulta ao ViaCEP
   - `fetch-temperature-weatherapi` (Serviço B) - Consulta ao WeatherAPI

## 📂 Estrutura do Projeto

```
.
├── docker-compose.yml              # Orquestração dos serviços
├── otel-collector-config.yaml     # Configuração do OTEL Collector
├── .env                            # Variáveis de ambiente (criar)
├── .env.example                    # Template do .env
├── service-a/
│   ├── Dockerfile
│   ├── go.mod
│   ├── go.sum                      # Gerado automaticamente
│   └── main.go                     # Código do Serviço A
└── service-b/
    ├── Dockerfile
    ├── go.mod
    ├── go.sum                      # Gerado automaticamente
    └── main.go                     # Código do Serviço B
```

## 🌐 Endpoints e Portas

| Serviço | URL | Porta |
|---------|-----|-------|
| Serviço A (Input) | http://localhost:8080 | 8080 |
| Serviço B (Orchestration) | http://localhost:8081 | 8081 |
| Zipkin UI | http://localhost:9411 | 9411 |
| OTEL Collector (HTTP) | http://localhost:4318 | 4318 |
| OTEL Collector (gRPC) | http://localhost:4317 | 4317 |

## 🧪 CEPs para Teste

| CEP | Cidade | Estado |
|-----|--------|--------|
| 01310100 | São Paulo | SP |
| 20040020 | Rio de Janeiro | RJ |
| 30130100 | Belo Horizonte | MG |
| 88015100 | Florianópolis | SC |
| 40020000 | Salvador | BA |
| 80010000 | Curitiba | PR |
| 60010000 | Fortaleza | CE |

## 🛠️ Comandos Úteis

```bash
# Parar todos os serviços
docker-compose down

# Parar e remover volumes
docker-compose down -v

# Ver logs de todos os serviços
docker-compose logs -f

# Ver logs de um serviço específico
docker-compose logs -f service-a
docker-compose logs -f service-b
docker-compose logs -f otel-collector

# Reiniciar um serviço
docker-compose restart service-a

# Rebuild após mudanças no código
docker-compose up -d --build

# Verificar se OTEL Collector iniciou
docker-compose logs otel-collector | grep -i "everything is ready"
```

## 🔧 Troubleshooting

### OTEL Collector não inicia

**Sintomas:**
```
container otel-collector is unhealthy
dependency failed to start
```

**Solução:**
```bash
# 1. Verificar logs do OTEL Collector
docker-compose logs otel-collector

# 2. Se houver erro de configuração, parar tudo
docker-compose down -v

# 3. Verificar se o arquivo de configuração existe
cat otel-collector-config.yaml

# 4. Remover container manualmente se necessário
docker rm -f otel-collector

# 5. Subir novamente
docker-compose up -d

# 6. Acompanhar logs até ver "Everything is ready"
docker-compose logs -f otel-collector
```

### Serviços não conseguem conectar ao OTEL Collector

**Sintomas nos logs:**
```
traces export: Post "http://otel-collector:4318/v1/traces": dial tcp: lookup otel-collector: no such host
```

**Solução:**
```bash
# 1. Garantir que OTEL Collector está rodando
docker-compose ps otel-collector

# 2. Se não estiver, iniciar manualmente
docker-compose up -d otel-collector

# 3. Aguardar 15 segundos
sleep 15

# 4. Reiniciar os serviços de aplicação
docker-compose restart service-a service-b

# 5. Verificar conectividade
docker-compose exec service-a ping -c 3 otel-collector
```

### Traces não aparecem no Zipkin

Este é o problema mais comum. Siga estes passos:

**Passo 1: Verificar se todos os containers estão rodando**
```bash
docker-compose ps
```

Todos devem estar "Up". Se não estiverem, veja as seções acima.

**Passo 2: Verificar logs do OTEL Collector**
```bash
docker-compose logs otel-collector | tail -50
```

Você deve ver mensagens indicando que traces estão sendo recebidos e exportados.

**Passo 3: Fazer requisições e aguardar**
```bash
# Fazer várias requisições
for i in {1..5}; do
  curl -s -X POST http://localhost:8080/cep \
    -H "Content-Type: application/json" \
    -d '{"cep":"01310100"}' > /dev/null
  echo "Requisição $i enviada"
  sleep 1
done

# Aguardar propagação (importante!)
echo "Aguardando 15 segundos..."
sleep 15

# Acessar Zipkin
echo "Acesse http://localhost:9411 e clique em 'Run Query'"
```

**Passo 4: Verificar via API do Zipkin**
```bash
# Ver se há traces
curl -s http://localhost:9411/api/v2/traces?limit=5

# Ver serviços registrados
curl -s http://localhost:9411/api/v2/services
```

**Passo 5: Se ainda não aparecer, reiniciar tudo**
```bash
# Parar tudo
docker-compose down -v

# Aguardar 5 segundos
sleep 5

# Subir na ordem correta
docker-compose up -d zipkin
sleep 10
docker-compose up -d otel-collector
sleep 15
docker-compose up -d service-b service-a
sleep 10

# Fazer requisição
curl -X POST http://localhost:8080/cep \
  -H "Content-Type: application/json" \
  -d '{"cep":"01310100"}'

# Aguardar
sleep 15

# Verificar no Zipkin
```

### Erro 500 nas requisições

**Causa 1:** WEATHER_API_KEY inválida ou expirada

**Solução:**
```bash
# Testar API key diretamente
WEATHER_KEY=$(grep WEATHER_API_KEY .env | cut -d= -f2)
curl "https://api.weatherapi.com/v1/current.json?key=$WEATHER_KEY&q=Sao Paulo"

# Se retornar erro, obtenha nova key em:
# https://www.weatherapi.com/

# Atualizar .env
echo "WEATHER_API_KEY=nova_chave_aqui" > .env

# Reiniciar Serviço B
docker-compose restart service-b
```

**Causa 2:** APIs externas fora do ar

**Solução:**
```bash
# Testar ViaCEP
curl https://viacep.com.br/ws/01310100/json/

# Testar WeatherAPI
curl "https://api.weatherapi.com/v1/current.json?key=SUA_CHAVE&q=Sao Paulo"

# Se alguma estiver fora, aguardar recuperação
```

### Container não se comunica com outro

**Solução:**
```bash
# Verificar rede Docker
docker network inspect temperature-services-activity-go_otel-network

# Testar conectividade
docker-compose exec service-a ping -c 3 service-b
docker-compose exec service-a ping -c 3 otel-collector

# Se falhar, recriar rede
docker-compose down
docker network prune -f
docker-compose up -d
```

### Script de Debug

Use o script `debug-traces.sh` para diagnóstico completo:

```bash
chmod +x debug-traces.sh
./debug-traces.sh
```

Ele irá verificar:
- Status dos containers
- Logs do OTEL Collector
- Conectividade entre serviços
- Variáveis de ambiente
- Fazer requisição de teste
- Verificar traces no Zipkin

## 🔄 Conversões de Temperatura

O sistema utiliza as seguintes fórmulas:

- **Fahrenheit**: `F = C × 1.8 + 32`
- **Kelvin**: `K = C + 273`

Exemplo: Se a temperatura for 25°C:
- Fahrenheit: 25 × 1.8 + 32 = 77°F
- Kelvin: 25 + 273 = 298K

## 📊 Observabilidade

### Spans Implementados

**Serviço A:**
1. `handle-cep-request` - Processamento completo da requisição (~200-500ms)
2. `validate-cep` - Validação do formato do CEP (~1-2ms)
3. `forward-to-service-b` - Encaminhamento para Serviço B (~200-450ms)

**Serviço B:**
1. `handle-weather-request` - Orquestração completa (~200-450ms)
2. `fetch-location-viacep` - Consulta ao ViaCEP (~100-200ms)
3. `fetch-temperature-weatherapi` - Consulta ao WeatherAPI (~100-250ms)

### Propagação de Contexto

O sistema usa **W3C Trace Context** para propagar informações de tracing entre os serviços via HTTP headers (`traceparent`). Isso permite que o Zipkin visualize a requisição completa através de múltiplos serviços.

### Exemplo de Trace no Zipkin

Ao clicar em um trace, você verá algo como:

```
service-a: handle-cep-request (450ms)
├── service-a: validate-cep (2ms)
└── service-a: forward-to-service-b (448ms)
    └── service-b: handle-weather-request (445ms)
        ├── service-b: fetch-location-viacep (200ms)
        └── service-b: fetch-temperature-weatherapi (240ms)
```

## 🛡️ Validações Implementadas

### Formato de CEP
- Deve ser uma string
- Deve conter exatamente 8 dígitos
- Apenas números são aceitos (sem traços ou espaços)

### Exemplos Válidos
```json
{"cep": "01310100"}  ✅
{"cep": "20040020"}  ✅
```

### Exemplos Inválidos
```json
{"cep": 01310100}      ❌ (número, não string)
{"cep": "123"}         ❌ (menos de 8 dígitos)
{"cep": "012345678"}   ❌ (mais de 8 dígitos)
{"cep": "0123456A"}    ❌ (contém letra)
{"cep": "01234-567"}   ❌ (contém traço)
{"cep": "0123 4567"}   ❌ (contém espaço)
```

## 🔐 Segurança

- API Key armazenada em variável de ambiente (.env)
- Validação rigorosa de entrada em múltiplas camadas
- Timeouts configurados para prevenir travamentos
- Sem exposição de dados sensíveis em logs
- Network isolation via Docker networks

## 📈 Performance

- **Latência média**: 200-500ms (dependente de APIs externas)
- **Throughput**: ~100 requisições/segundo por serviço
- **Timeouts configurados**:
   - Serviço A → Serviço B: 10 segundos
   - Consulta ViaCEP: 5 segundos
   - Consulta WeatherAPI: 5 segundos

## 🚀 Tecnologias Utilizadas

- **Linguagem**: Go 1.21
- **Containerização**: Docker, Docker Compose
- **Observabilidade**:
   - OpenTelemetry Go SDK v1.21.0
   - OpenTelemetry Collector Contrib v0.91.0
   - Zipkin (latest)
- **APIs Externas**:
   - ViaCEP (https://viacep.com.br) - Consulta de CEP
   - WeatherAPI (https://www.weatherapi.com) - Dados climáticos
- **Protocolo**: HTTP/REST
- **Formato de Dados**: JSON

## 📝 Notas Importantes

### Sobre as APIs Externas

1. **WeatherAPI**:
   - Requer cadastro gratuito em https://www.weatherapi.com/
   - Plano gratuito: 1 milhão de requisições/mês
   - Configure a chave no arquivo `.env`

2. **ViaCEP**:
   - API pública, sem necessidade de autenticação
   - Pode ter instabilidade ocasional
   - Nem todos os CEPs estão cadastrados

### Sobre o Ambiente

Este setup é para **ambiente de desenvolvimento**. Para produção, considere:
- Usar secrets manager para API keys
- Configurar HTTPS/TLS
- Implementar rate limiting
- Adicionar autenticação/autorização
- Configurar health checks
- Adicionar monitoramento com Prometheus/Grafana
- Implementar circuit breakers
- Usar storage persistente para Zipkin

### Ordem de Inicialização

Os serviços têm dependências e devem iniciar nesta ordem:
1. **Zipkin** (primeiro)
2. **OTEL Collector** (aguarda Zipkin)
3. **Service B** (aguarda OTEL Collector)
4. **Service A** (aguarda OTEL Collector e Service B)

O Docker Compose gerencia isso automaticamente, mas pode levar 30-40 segundos para todos iniciarem.

## 🆘 Suporte

### Verificar Saúde do Sistema

```bash
# Status dos containers
docker-compose ps

# Verificar se OTEL iniciou
docker-compose logs otel-collector | grep "Everything is ready"

# Verificar se serviços estão funcionando
curl -s http://localhost:8080/cep \
  -H "Content-Type: application/json" \
  -d '{"cep":"01310100"}' | head -1
```

### Logs Importantes

```bash
# Ver todos os logs
docker-compose logs

# Ver apenas erros
docker-compose logs | grep -i "error\|failed\|fatal"

# Ver logs com timestamp
docker-compose logs -t

# Ver logs em tempo real
docker-compose logs -f
```

### Resetar Completamente

Se nada funcionar, reset completo:

```bash
# 1. Parar e limpar tudo
docker-compose down -v

# 2. Remover containers manualmente
docker rm -f service-a service-b otel-collector zipkin 2>/dev/null || true

# 3. Limpar redes
docker network prune -f

# 4. Rebuild completo
docker-compose build --no-cache

# 5. Subir novamente
docker-compose up -d

# 6. Aguardar inicialização
sleep 40

# 7. Verificar status
docker-compose ps

# 8. Testar
curl -X POST http://localhost:8080/cep \
  -H "Content-Type: application/json" \
  -d '{"cep":"01310100"}'
```

## 📄 Licença

Este projeto foi desenvolvido como parte de um desafio técnico.

## 🎉 Conclusão

Sistema completo e funcional que implementa:
- ✅ Arquitetura de microsserviços distribuída
- ✅ Validação robusta de entrada
- ✅ Integração com APIs externas (ViaCEP e WeatherAPI)
- ✅ Observabilidade completa com OpenTelemetry
- ✅ Tracing distribuído visualizado no Zipkin
- ✅ Containerização completa com Docker
- ✅ 6 spans medindo operações críticas
- ✅ Propagação de contexto entre serviços