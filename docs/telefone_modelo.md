# Modelo de Telefones - ER_FLORIPA

## Diagrama do Núcleo de Telefones (texto simples)

Tabela: telefone
  - id_telefone (PK)
  - ddd
  - numero
  - tipo (Fixo/Celular)

Tabela: pessoa_telefone (ligação polimórfica)
  - id (PK)
  - pf_cpf (FK -> pessoa_fisica)
  - pj_cnpj (FK -> pessoa_juridica)
  - id_telefone (FK -> telefone)
  - ordem
  - tipo_uso
  - tipo_linha
  - id_tipo_relacao (FK -> tipo_relacao)
  - valid_from
  - valid_to
  - source_system
  - priority

Tabela: tipo_relacao
  - id_tipo_relacao (PK)
  - nome (Proprietario, Empresa, Parente, Recado, etc.)
  - descricao

Tabela: telefone_operadora
  - id (PK)
  - id_telefone (FK -> telefone)
  - id_operadora (FK -> operadora)
  - valid_from
  - valid_to

Tabela: operadora
  - id_operadora (PK)
  - nome
  - codigo_anatel

Tabela: telefone_midia
  - id (PK)
  - id_telefone (FK -> telefone)
  - id_midia (FK -> midia_social)
  - identificador
  - valid_from
  - valid_to

Tabela: midia_social
  - id_midia (PK)
  - nome (WhatsApp, Telegram, etc.)
  - descricao

## Como o modelo resolve variações

| Variação | Solução |
|----------|---------|
| Mesmo número com várias pessoas | Uma linha em telefone + várias em pessoa_telefone. |
| Mudança de titularidade | valid_to na linha antiga, valid_from na nova. |
| PF -> PJ ou vice-versa | Novo vínculo com o outro documento. |
| Mudança de operadora | telefone_operadora com validade temporal. |
| Redes sociais (WhatsApp, etc.) | telefone_midia com validade temporal. |
| Tipo de relação (recado, empresa...) | id_tipo_relacao em pessoa_telefone. |
| Origem/Conflito | source_system e priority. |
| Exclusão lógica | deleted_at em todas as tabelas. |

## Princípios

- O número (DDD+numero) é único em telefone e imutável.
- Tudo que varia (quem possui, operadora, mídias) fica nas ligações com validade temporal.
- O modelo é imutável no passado – nunca perde informação.
