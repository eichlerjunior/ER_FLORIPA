# ER_FLORIPA - Modelo Relacional para dados de PF e PJ

Este projeto contém o modelo relacional normalizado para os dados de pessoas físicas e jurídicas da região de Florianópolis, a partir de tabelões originais.

## Estrutura

- `sql/` – scripts de criação de tabelas, funções de limpeza, triggers e carga de dados.
- `docs/` – documentação do modelo.

## Principais entidades

- `pessoa_fisica` e `pessoa_juridica`
- `telefone`, `endereco`, `email` (compartilhados)
- `pessoa_telefone`, `pessoa_endereco`, `pessoa_email` (ligações polimórficas com validade temporal)
- `operadora`, `telefone_operadora` (histórico de operadoras)
- `midia_social`, `telefone_midia`, `email_midia` (WhatsApp, Telegram, etc.)
- `tipo_relacao` (Proprietario, Empresa, Parente, Recado...)
- `ddd_anatel` (validação de DDD)
- Suporte a PostGIS para coordenadas geográficas

## Como usar

1. Execute os scripts em ordem numérica (01, 02, 03...).
2. Após criar as tabelas, use os scripts de carga (05, 08, etc.) para popular a partir das tabelas `"FPOLIS_PF"` e `"FPOLIS_PJ"`.

## Ferramentas

- PostgreSQL 18
- PostGIS (opcional)
- Navicat / pgAdmin

## Autor

Projeto mantido por @eichlerjunior.
