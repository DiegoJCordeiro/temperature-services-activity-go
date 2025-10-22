.PHONY: up down build logs test clean

# Subir todos os serviços
up:
	docker-compose up -d

# Parar todos os serviços
down:
	docker-compose down

# Parar e remover volumes
clean:
	docker-compose down -v

# Build dos serviços
build:
	docker-compose build

# Ver logs de todos os serviços
logs:
	docker-compose logs -f

# Ver logs do Serviço A
logs-a:
	docker-compose logs -f service-a

# Ver logs do Serviço B
logs-b:
	docker-compose logs -f service-b

# Ver logs do OTEL Collector
logs-otel:
	docker-compose logs -f otel-collector

# Ver logs do Zipkin
logs-zipkin:
	docker-compose logs -f zipkin

# Status dos serviços
status:
	docker-compose ps

# Teste de CEP válido
test-valid:
	curl -X POST http://localhost:8080/cep \
		-H "Content-Type: application/json" \
		-d '{"cep":"01310100"}'

# Teste de CEP inválido (formato incorreto)
test-invalid-format:
	curl -X POST http://localhost:8080/cep \
		-H "Content-Type: application/json" \
		-d '{"cep":"123"}'

# Teste de CEP não encontrado
test-not-found:
	curl -X POST http://localhost:8080/cep \
		-H "Content-Type: application/json" \
		-d '{"cep":"99999999"}'

# Rodar todos os testes
test-all: test-valid test-invalid-format test-not-found

# Abrir Zipkin no navegador (macOS/Linux)
zipkin:
	@echo "Abrindo Zipkin em http://localhost:9411"
	@command -v open >/dev/null 2>&1 && open http://localhost:9411 || \
	 command -v xdg-open >/dev/null 2>&1 && xdg-open http://localhost:9411 || \
	 echo "Acesse manualmente: http://localhost:9411"

# Restart de todos os serviços
restart: down up

# Rebuild e restart
rebuild: down build up