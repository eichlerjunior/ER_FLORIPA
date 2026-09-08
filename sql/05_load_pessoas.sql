-- PF
INSERT INTO pessoa_fisica (
    cpf, nome, outro_nome, sexo, data_nasc, signo,
    nome_mae, nome_pai, escolaridade, rg, uf_rg, emissor_rg,
    flag_obito, data_obito, ano_obito, flag_ppe, cargo_ppe,
    flag_clt, empregador_cnpj, empregador_nome, empregador_cnae,
    empregador_cnae_descricao, empregador_porte, data_admissao,
    cbo, cbo_descricao, salario_valor, salario_faixa,
    salario_faixa_descricao, renda_estimada, renda_estimada_faixa,
    renda_estimada_faixa_descricao, flag_inss, numero_beneficio,
    especie_beneficio, beneficio_valor, beneficio_faixa,
    beneficio_faixa_descricao, flag_socio_empresa,
    source_system, priority
)
SELECT 
    clean_cpf("CPF"),
    trim("Nome"),
    trim("OutroNome"),
    upper(trim("Sexo")),
    clean_date("DataNasc"),
    trim("Signo"),
    trim("NomeMae"),
    trim("NomePai"),
    trim("Escolaridade"),
    trim("RG"),
    upper(trim("UFRG")),
    trim("EmissorRG"),
    clean_boolean("FlagObito"),
    clean_date("DataObito"),
    trim("AnoObito"),
    clean_boolean("FlagPPE"),
    trim("CargoPPE"),
    clean_boolean("FlagCLT"),
    clean_cpf("EmpregadorCNPJ"),
    trim("EmpregadorNome"),
    trim("EmpregadorCNAE"),
    trim("EmpregadorCNAEDescricao"),
    trim("EmpregadorPorte"),
    clean_date("DataAdmissao"),
    trim("CBO"),
    trim("CBODescricao"),
    clean_decimal("SalarioValor"),
    upper(trim("SalarioFaixa")),
    trim("SalarioFaixaDescricao"),
    clean_decimal("RendaEstimada"),
    upper(trim("RendaEstimadaFaixa")),
    trim("RendaEstimadaFaixaDescricao"),
    clean_boolean("FlagINSS"),
    trim("NumeroBeneficio"),
    trim("EspecieBeneficio"),
    clean_decimal("BeneficioValor"),
    upper(trim("BeneficioFaixa")),
    trim("BeneficioFaixaDescricao"),
    clean_boolean("FlagSocioEmpresa"),
    'FPOLIS_PF',
    1
FROM "FPOLIS_PF"
WHERE clean_cpf("CPF") IS NOT NULL
ON CONFLICT (cpf) DO UPDATE SET
    nome = EXCLUDED.nome,
    data_nasc = EXCLUDED.data_nasc,
    updated_at = NOW(),
    source_system = 'FPOLIS_PF',
    priority = GREATEST(pessoa_fisica.priority, EXCLUDED.priority);

-- PJ (análogo, com colunas PJ)
INSERT INTO pessoa_juridica (
    cnpj, razao_social, fantasia, situacao_cadastral, data_situacao_cadastral,
    situacao_especial, data_situacao_especial, cnae_principal, cnae_descricao,
    natureza_juridica, descricao_natureza_juridica, data_abertura,
    num_funcionarios, capital_social, porte_empresa, inscricao_estadual,
    regime_apuracao, faturamento_presumido, matriz, tem_filial,
    source_system, priority
)
SELECT 
    clean_cnpj("CNPJ"),
    trim("RazaoSocial"),
    trim("Fantasia"),
    trim("SituacaoCadastral"),
    clean_date("DataSituacaoCadastral"),
    trim("SituacaoEspecial"),
    clean_date("DataSituacaoEspecial"),
    trim("CNAE"),
    trim("CNAEDescricao"),
    trim("NaturezaJuridica"),
    trim("DescricaoNaturezaJuridica"),
    clean_date("DataAbertura"),
    NULLIF(trim("NumeroFuncionarios"), '')::INTEGER,
    clean_decimal("CapitalSocial"),
    trim("PorteEmpresa"),
    trim("InscricaoEstadual"),
    trim("RegimeApuracao"),
    clean_decimal("FaturamentoPresumido"),
    clean_boolean("Matriz"),
    clean_boolean("TemFilial"),
    'FPOLIS_PJ',
    1
FROM "FPOLIS_PJ"
WHERE clean_cnpj("CNPJ") IS NOT NULL
ON CONFLICT (cnpj) DO UPDATE SET
    razao_social = EXCLUDED.razao_social,
    updated_at = NOW(),
    source_system = 'FPOLIS_PJ',
    priority = GREATEST(pessoa_juridica.priority, EXCLUDED.priority);
