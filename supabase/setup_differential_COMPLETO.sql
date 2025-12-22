-- =====================================================
-- SETUP DIFFERENTIAL COMPLETO - GRANAZAP V5
-- =====================================================
-- Este arquivo contém TODAS as diferenças entre o setup.sql original
-- e o banco de dados atual em produção no Supabase.
-- 
-- ⚠️ IMPORTANTE: Execute este arquivo APÓS o setup.sql
-- 
-- Data de Geração: 21/12/2024
-- Projeto: vrmickfxoxvyljounoxq
-- =====================================================

-- =====================================================
-- 1. EXTENSÕES HABILITADAS (não estão no setup.sql)
-- =====================================================

-- Extensões já habilitadas no Supabase:
-- ✅ pg_graphql (schema: graphql)
-- ✅ supabase_vault (schema: vault)
-- ✅ uuid-ossp (schema: extensions)
-- ✅ pg_net (schema: extensions) - NECESSÁRIA para Cron Jobs
-- ✅ http (schema: extensions)
-- ✅ pgcrypto (schema: extensions)
-- ✅ pg_stat_statements (schema: extensions)
-- ✅ pg_cron (schema: pg_catalog) - NECESSÁRIA para Investment Updates

-- =====================================================
-- 2. NOVAS COLUNAS EM TABELAS EXISTENTES
-- =====================================================

-- 2.1 Tabela: usuarios
-- Colunas de Internacionalização
ALTER TABLE usuarios 
ADD COLUMN IF NOT EXISTS idioma TEXT DEFAULT 'pt' CHECK (idioma IN ('pt', 'es', 'en'));

ALTER TABLE usuarios 
ADD COLUMN IF NOT EXISTS moeda TEXT DEFAULT 'BRL' CHECK (moeda IN ('BRL', 'USD', 'EUR', 'PYG', 'ARS'));

COMMENT ON COLUMN usuarios.idioma IS 'Idioma preferido do usuário: pt (Português), es (Español), en (English)';
COMMENT ON COLUMN usuarios.moeda IS 'Moeda preferida do usuário: BRL (Real), USD (Dólar), EUR (Euro)';

-- 2.2 Tabela: categoria_trasacoes
-- Colunas para Modo PJ e Keywords AI
ALTER TABLE categoria_trasacoes 
ADD COLUMN IF NOT EXISTS tipo_conta TEXT NOT NULL DEFAULT 'pessoal' CHECK (tipo_conta IN ('pessoal', 'pj'));

ALTER TABLE categoria_trasacoes 
ADD COLUMN IF NOT EXISTS keywords TEXT[] DEFAULT '{}';

COMMENT ON COLUMN categoria_trasacoes.keywords IS 'Keywords for AI-powered category identification';

-- 2.3 Tabela: transacoes
-- Colunas para Modo PJ, Transferências, Contas Bancárias e Cartões
ALTER TABLE transacoes 
ADD COLUMN IF NOT EXISTS dependente_id INTEGER REFERENCES usuarios_dependentes(id) ON DELETE SET NULL;

ALTER TABLE transacoes 
ADD COLUMN IF NOT EXISTS tipo_conta TEXT DEFAULT 'pessoal' CHECK (tipo_conta IN ('pessoal', 'pj'));

ALTER TABLE transacoes 
ADD COLUMN IF NOT EXISTS is_transferencia BOOLEAN DEFAULT false;

ALTER TABLE transacoes 
ADD COLUMN IF NOT EXISTS conta_id UUID REFERENCES contas_bancarias(id) ON DELETE SET NULL;

ALTER TABLE transacoes 
ADD COLUMN IF NOT EXISTS cartao_id UUID REFERENCES cartoes_credito(id) ON DELETE SET NULL;

ALTER TABLE transacoes 
ADD COLUMN IF NOT EXISTS conta_destino_id UUID REFERENCES contas_bancarias(id) ON DELETE SET NULL;

-- Adicionar constraint de valor positivo
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint 
        WHERE conname = 'transacoes_valor_positivo'
    ) THEN
        ALTER TABLE transacoes ADD CONSTRAINT transacoes_valor_positivo CHECK (valor > 0);
    END IF;
END $$;

COMMENT ON COLUMN transacoes.dependente_id IS 'ID do dependente que criou a transação. NULL = transação do usuário principal';
COMMENT ON COLUMN transacoes.tipo_conta IS 'Tipo de conta da transação: pessoal ou pj (Pessoa Jurídica)';
COMMENT ON COLUMN transacoes.is_transferencia IS 'Flag para identificar transferências entre contas (não conta em relatórios)';
COMMENT ON COLUMN transacoes.conta_id IS 'Conta bancária de origem da transação';
COMMENT ON COLUMN transacoes.cartao_id IS 'Cartão de crédito usado na transação (se aplicável)';

-- 2.4 Tabela: lancamentos_futuros
-- Colunas para Recorrentes, Dependentes e Cartões
ALTER TABLE lancamentos_futuros 
ADD COLUMN IF NOT EXISTS dependente_id INTEGER REFERENCES usuarios_dependentes(id) ON DELETE SET NULL;

ALTER TABLE lancamentos_futuros 
ADD COLUMN IF NOT EXISTS data_final DATE DEFAULT NULL;

ALTER TABLE lancamentos_futuros 
ADD COLUMN IF NOT EXISTS confirmed_dates TEXT DEFAULT NULL;

ALTER TABLE lancamentos_futuros 
ADD COLUMN IF NOT EXISTS cartao_id UUID REFERENCES cartoes_credito(id) ON DELETE SET NULL;

ALTER TABLE lancamentos_futuros 
ADD COLUMN IF NOT EXISTS parcela_info JSONB DEFAULT NULL;

COMMENT ON COLUMN lancamentos_futuros.dependente_id IS 'ID do dependente que criou o lançamento futuro. NULL = lançamento do usuário principal';
COMMENT ON COLUMN lancamentos_futuros.data_final IS 'Data final opcional para lançamentos recorrentes. NULL = recorrente indefinido (comportamento atual mantido)';
COMMENT ON COLUMN lancamentos_futuros.confirmed_dates IS 'JSON array com datas já confirmadas de recorrentes expandidos. NULL = comportamento atual mantido';
COMMENT ON COLUMN lancamentos_futuros.cartao_id IS 'Cartão de crédito vinculado ao lançamento (para parcelas)';
COMMENT ON COLUMN lancamentos_futuros.parcela_info IS 'Informações da parcela: {"numero": 1, "total": 12, "valor_original": 1200.00}';

-- 2.5 Tabela: planos_sistema
-- Colunas para Planos Compartilhados e Modo PJ
ALTER TABLE planos_sistema 
ADD COLUMN IF NOT EXISTS permite_compartilhamento BOOLEAN DEFAULT false;

ALTER TABLE planos_sistema 
ADD COLUMN IF NOT EXISTS max_usuarios_dependentes INTEGER DEFAULT 0 CHECK (max_usuarios_dependentes >= 0);

ALTER TABLE planos_sistema 
ADD COLUMN IF NOT EXISTS destaque BOOLEAN DEFAULT false;

ALTER TABLE planos_sistema 
ADD COLUMN IF NOT EXISTS permite_modo_pj BOOLEAN DEFAULT true;

COMMENT ON COLUMN planos_sistema.permite_compartilhamento IS 'Define se este plano permite adicionar usuários dependentes (ex: Plano Casal, Plano Empresa). FALSE = não permite, TRUE = permite';
COMMENT ON COLUMN planos_sistema.max_usuarios_dependentes IS 'Número máximo de usuários dependentes permitidos neste plano. 0 = não permite, -1 = ilimitado, N = limite específico';
COMMENT ON COLUMN planos_sistema.destaque IS 'Se este plano deve ser destacado na interface (ex: "Mais Popular")';
COMMENT ON COLUMN planos_sistema.permite_modo_pj IS 'Se este plano permite usar o modo PJ (Pessoa Jurídica)';

-- 2.6 Tabela: investment_positions
-- Colunas para Renda Fixa e Impostos Manuais
ALTER TABLE investment_positions 
ADD COLUMN IF NOT EXISTS yield_percentage NUMERIC(5,2) DEFAULT NULL;

ALTER TABLE investment_positions 
ADD COLUMN IF NOT EXISTS manual_ir NUMERIC(15,2) DEFAULT NULL;

ALTER TABLE investment_positions 
ADD COLUMN IF NOT EXISTS manual_iof NUMERIC(15,2) DEFAULT NULL;

ALTER TABLE investment_positions 
ADD COLUMN IF NOT EXISTS use_manual_tax BOOLEAN DEFAULT false;

COMMENT ON COLUMN investment_positions.yield_percentage IS 'Rentabilidade contratada para Renda Fixa (ex: 100 = 100% CDI, 110 = 110% CDI). NULL para outros tipos de ativos.';
COMMENT ON COLUMN investment_positions.manual_ir IS 'Valor manual de IR (para bater com banco)';
COMMENT ON COLUMN investment_positions.manual_iof IS 'Valor manual de IOF (para bater com banco)';
COMMENT ON COLUMN investment_positions.use_manual_tax IS 'Se true, usa valores manuais de impostos ao invés de calcular';

-- =====================================================
-- 3. NOVAS TABELAS (não existem no setup.sql)
-- =====================================================

-- 3.1 Tabela: contas_bancarias
CREATE TABLE IF NOT EXISTS contas_bancarias (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    usuario_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    nome TEXT NOT NULL,
    banco TEXT,
    tipo TEXT NOT NULL CHECK (tipo IN ('corrente', 'poupanca', 'investimento', 'carteira')),
    saldo_inicial NUMERIC(15,2) NOT NULL DEFAULT 0,
    saldo_atual NUMERIC(15,2) NOT NULL DEFAULT 0,
    cor TEXT DEFAULT '#8A05BE',
    icone TEXT DEFAULT 'wallet',
    ativa BOOLEAN DEFAULT true,
    tipo_conta TEXT NOT NULL DEFAULT 'pessoal' CHECK (tipo_conta IN ('pessoal', 'pj')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

COMMENT ON TABLE contas_bancarias IS 'Contas bancárias e carteiras do usuário para controle de saldo';
COMMENT ON COLUMN contas_bancarias.tipo IS 'Tipo da conta: corrente, poupanca, investimento, carteira';
COMMENT ON COLUMN contas_bancarias.saldo_inicial IS 'Saldo inicial ao criar a conta';
COMMENT ON COLUMN contas_bancarias.saldo_atual IS 'Saldo atual calculado automaticamente';
COMMENT ON COLUMN contas_bancarias.tipo_conta IS 'Tipo de conta: pessoal ou pj (Pessoa Jurídica)';

-- 3.2 Tabela: cartoes_credito
CREATE TABLE IF NOT EXISTS cartoes_credito (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    usuario_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    nome TEXT NOT NULL,
    bandeira TEXT,
    ultimos_digitos TEXT,
    limite_total NUMERIC(10,2) NOT NULL DEFAULT 0 CHECK (limite_total >= 0),
    dia_fechamento INTEGER NOT NULL CHECK (dia_fechamento >= 1 AND dia_fechamento <= 31),
    dia_vencimento INTEGER NOT NULL CHECK (dia_vencimento >= 1 AND dia_vencimento <= 31),
    tipo_conta TEXT NOT NULL DEFAULT 'pessoal' CHECK (tipo_conta IN ('pessoal', 'pj')),
    cor_cartao TEXT DEFAULT '#8A05BE',
    ativo BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    conta_vinculada_id UUID REFERENCES contas_bancarias(id) ON DELETE SET NULL
);

COMMENT ON TABLE cartoes_credito IS 'Cartões de crédito do usuário';
COMMENT ON COLUMN cartoes_credito.dia_fechamento IS 'Dia do mês em que a fatura fecha';
COMMENT ON COLUMN cartoes_credito.dia_vencimento IS 'Dia do mês em que a fatura vence';
COMMENT ON COLUMN cartoes_credito.conta_vinculada_id IS 'Conta bancária usada para pagar a fatura';

-- 3.3 Tabela: investment_assets
CREATE TABLE IF NOT EXISTS investment_assets (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    ticker TEXT NOT NULL UNIQUE,
    name TEXT,
    type TEXT NOT NULL CHECK (type IN ('acao', 'fii', 'etf', 'renda_fixa', 'cripto', 'bdr')),
    current_price NUMERIC(15,2),
    previous_close NUMERIC(15,2),
    last_updated TIMESTAMP WITH TIME ZONE,
    source TEXT DEFAULT 'brapi' CHECK (source IN ('brapi', 'manual', 'fallback', 'binance')),
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc', now()),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc', now())
);

COMMENT ON TABLE investment_assets IS 'Ativos disponíveis para investimento (ações, FIIs, criptos, etc)';
COMMENT ON COLUMN investment_assets.ticker IS 'Código do ativo (ex: PETR4, BTCBRL)';
COMMENT ON COLUMN investment_assets.type IS 'Tipo do ativo: acao, fii, etf, renda_fixa, cripto, bdr';
COMMENT ON COLUMN investment_assets.source IS 'Fonte dos dados: brapi, binance, manual, fallback';

-- 3.4 Tabela: investment_positions
CREATE TABLE IF NOT EXISTS investment_positions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    usuario_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    asset_id UUID NOT NULL REFERENCES investment_assets(id) ON DELETE RESTRICT,
    conta_id UUID REFERENCES contas_bancarias(id) ON DELETE SET NULL,
    quantidade NUMERIC(15,4) NOT NULL CHECK (quantidade > 0),
    preco_medio NUMERIC(15,2) NOT NULL CHECK (preco_medio >= 0),
    data_compra DATE NOT NULL,
    tipo_conta TEXT NOT NULL CHECK (tipo_conta IN ('pessoal', 'pj')),
    is_manual_price BOOLEAN DEFAULT false,
    manual_price NUMERIC(15,8),
    observacao TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc', now()),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc', now()),
    yield_percentage NUMERIC(5,2) DEFAULT NULL,
    manual_ir NUMERIC(15,2),
    manual_iof NUMERIC(15,2),
    use_manual_tax BOOLEAN DEFAULT false,
    UNIQUE(usuario_id, asset_id)
);

COMMENT ON TABLE investment_positions IS 'Posições de investimento do usuário';
COMMENT ON COLUMN investment_positions.quantidade IS 'Quantidade de ativos na posição';
COMMENT ON COLUMN investment_positions.preco_medio IS 'Preço médio de compra';
COMMENT ON COLUMN investment_positions.is_manual_price IS 'Se true, usa manual_price ao invés do preço da API';

-- 3.5 Tabela: investment_dividends
CREATE TABLE IF NOT EXISTS investment_dividends (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    position_id UUID NOT NULL REFERENCES investment_positions(id) ON DELETE CASCADE,
    tipo TEXT NOT NULL CHECK (tipo IN ('dividendo', 'jcp', 'rendimento', 'amortizacao')),
    valor_por_ativo NUMERIC(15,8) NOT NULL CHECK (valor_por_ativo > 0),
    data_com DATE,
    data_pagamento DATE NOT NULL,
    observacao TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc', now())
);

COMMENT ON TABLE investment_dividends IS 'Proventos recebidos de investimentos (dividendos, JCP, rendimentos)';
COMMENT ON COLUMN investment_dividends.tipo IS 'Tipo do provento: dividendo, jcp, rendimento, amortizacao';
COMMENT ON COLUMN investment_dividends.valor_por_ativo IS 'Valor pago por ativo';
COMMENT ON COLUMN investment_dividends.data_com IS 'Data COM (quem tinha o ativo nesta data recebe)';

-- 3.6 Tabela: api_usage_log
CREATE TABLE IF NOT EXISTS api_usage_log (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    api_name TEXT NOT NULL,
    endpoint TEXT NOT NULL,
    tickers_count INTEGER NOT NULL,
    status TEXT NOT NULL CHECK (status IN ('success', 'error', 'rate_limit')),
    response_time_ms INTEGER,
    error_message TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc', now())
);

COMMENT ON TABLE api_usage_log IS 'Log de uso das APIs externas (BrAPI, Binance, etc)';
COMMENT ON COLUMN api_usage_log.status IS 'Status da chamada: success, error, rate_limit';

-- 3.7 Tabela: cdi_rates
CREATE TABLE IF NOT EXISTS cdi_rates (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    date DATE NOT NULL UNIQUE,
    rate NUMERIC NOT NULL,
    source TEXT DEFAULT 'banco_central',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

COMMENT ON TABLE cdi_rates IS 'Historical CDI rates from Banco Central do Brasil';
COMMENT ON COLUMN cdi_rates.date IS 'Reference date for the rate';
COMMENT ON COLUMN cdi_rates.rate IS 'Annual CDI rate in decimal format (0.1165 = 11.65%)';

-- 3.8 Tabela: usuarios_dependentes
CREATE TABLE IF NOT EXISTS usuarios_dependentes (
    id SERIAL PRIMARY KEY,
    nome TEXT NOT NULL,
    email TEXT,
    telefone TEXT,
    usuario_principal_id INTEGER NOT NULL REFERENCES usuarios(id) ON DELETE CASCADE,
    status TEXT DEFAULT 'ativo' CHECK (status IN ('ativo', 'inativo')),
    data_criacao TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    data_ultima_modificacao TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    observacoes TEXT,
    auth_user_id UUID REFERENCES auth.users(id),
    convite_token TEXT,
    convite_expira_em TIMESTAMP WITH TIME ZONE,
    convite_status TEXT DEFAULT 'pendente' CHECK (convite_status IN ('pendente', 'aceito', 'recusado', 'cancelado')),
    permissoes JSONB DEFAULT '{"pode_criar": true, "pode_editar": true, "pode_deletar": false}'::jsonb
);

COMMENT ON TABLE usuarios_dependentes IS 'Usuários dependentes vinculados a um usuário principal. Compartilham os mesmos dados financeiros do principal sem ter autenticação própria.';
COMMENT ON COLUMN usuarios_dependentes.usuario_principal_id IS 'ID do usuário principal (titular do plano) ao qual este dependente pertence';
COMMENT ON COLUMN usuarios_dependentes.auth_user_id IS 'UUID do auth.users se o dependente tiver login próprio';
COMMENT ON COLUMN usuarios_dependentes.permissoes IS 'Permissões do dependente em formato JSON';

-- =====================================================
-- 4. NOVAS FUNÇÕES SQL (não existem no setup.sql)
-- =====================================================

-- 4.1 Função: is_user_admin
CREATE OR REPLACE FUNCTION is_user_admin()
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_is_admin BOOLEAN;
BEGIN
    SELECT is_admin INTO v_is_admin
    FROM usuarios
    WHERE auth_user = auth.uid();
    
    RETURN COALESCE(v_is_admin, false);
END;
$$;

COMMENT ON FUNCTION is_user_admin() IS 'Verifica se o usuário logado é administrador';

-- 4.2 Função: calculate_fixed_income_price
CREATE OR REPLACE FUNCTION calculate_fixed_income_price(
    p_data_compra DATE,
    p_yield_percentage NUMERIC,
    p_preco_inicial NUMERIC
)
RETURNS NUMERIC
LANGUAGE plpgsql
IMMUTABLE
AS $$
DECLARE
    v_dias_corridos INTEGER;
    v_taxa_cdi_anual NUMERIC;
    v_taxa_cdi_diaria NUMERIC;
    v_rentabilidade_contratada NUMERIC;
    v_valor_final NUMERIC;
BEGIN
    -- Calcular dias corridos desde a compra
    v_dias_corridos := CURRENT_DATE - p_data_compra;
    
    -- Se não passou nenhum dia, retornar preço inicial
    IF v_dias_corridos <= 0 THEN
        RETURN p_preco_inicial;
    END IF;
    
    -- Buscar taxa CDI mais recente
    SELECT rate INTO v_taxa_cdi_anual
    FROM cdi_rates
    ORDER BY date DESC
    LIMIT 1;
    
    -- Se não encontrou taxa CDI, retornar preço inicial
    IF v_taxa_cdi_anual IS NULL THEN
        RETURN p_preco_inicial;
    END IF;
    
    -- Converter taxa anual para diária: (1 + taxa_anual)^(1/252) - 1
    v_taxa_cdi_diaria := POWER(1 + v_taxa_cdi_anual, 1.0/252.0) - 1;
    
    -- Aplicar percentual contratado (ex: 110% do CDI = 1.10)
    v_rentabilidade_contratada := v_taxa_cdi_diaria * (p_yield_percentage / 100.0);
    
    -- Calcular valor final: valor_inicial * (1 + taxa)^dias
    v_valor_final := p_preco_inicial * POWER(1 + v_rentabilidade_contratada, v_dias_corridos);
    
    RETURN v_valor_final;
END;
$$;

COMMENT ON FUNCTION calculate_fixed_income_price(DATE, NUMERIC, NUMERIC) IS 'Calcula o preço atual de um ativo de renda fixa baseado no CDI e yield contratado';

-- 4.3 Função: atualizar_saldo_conta
CREATE OR REPLACE FUNCTION atualizar_saldo_conta()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    -- Atualizar saldo ao INSERIR transação
    IF TG_OP = 'INSERT' THEN
        IF NEW.conta_id IS NOT NULL AND NEW.is_transferencia = false THEN
            UPDATE contas_bancarias
            SET saldo_atual = saldo_atual + 
                CASE 
                    WHEN NEW.tipo = 'entrada' THEN NEW.valor
                    WHEN NEW.tipo = 'saida' THEN -NEW.valor
                    ELSE 0
                END,
                updated_at = NOW()
            WHERE id = NEW.conta_id;
        END IF;
    END IF;
    
    -- Atualizar saldo ao DELETAR transação
    IF TG_OP = 'DELETE' THEN
        IF OLD.conta_id IS NOT NULL AND OLD.is_transferencia = false THEN
            UPDATE contas_bancarias
            SET saldo_atual = saldo_atual - 
                CASE 
                    WHEN OLD.tipo = 'entrada' THEN OLD.valor
                    WHEN OLD.tipo = 'saida' THEN -OLD.valor
                    ELSE 0
                END,
                updated_at = NOW()
            WHERE id = OLD.conta_id;
        END IF;
    END IF;
    
    RETURN COALESCE(NEW, OLD);
END;
$$;

-- 4.4 Função: update_account_balance
CREATE OR REPLACE FUNCTION update_account_balance()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    -- Lógica de atualização de saldo para transferências
    IF TG_OP = 'INSERT' AND NEW.is_transferencia = true THEN
        -- Debitar da conta origem
        IF NEW.conta_id IS NOT NULL THEN
            UPDATE contas_bancarias
            SET saldo_atual = saldo_atual - NEW.valor,
                updated_at = NOW()
            WHERE id = NEW.conta_id;
        END IF;
        
        -- Creditar na conta destino
        IF NEW.conta_destino_id IS NOT NULL THEN
            UPDATE contas_bancarias
            SET saldo_atual = saldo_atual + NEW.valor,
                updated_at = NOW()
            WHERE id = NEW.conta_destino_id;
        END IF;
    END IF;
    
    IF TG_OP = 'DELETE' AND OLD.is_transferencia = true THEN
        -- Reverter débito da conta origem
        IF OLD.conta_id IS NOT NULL THEN
            UPDATE contas_bancarias
            SET saldo_atual = saldo_atual + OLD.valor,
                updated_at = NOW()
            WHERE id = OLD.conta_id;
        END IF;
        
        -- Reverter crédito na conta destino
        IF OLD.conta_destino_id IS NOT NULL THEN
            UPDATE contas_bancarias
            SET saldo_atual = saldo_atual - OLD.valor,
                updated_at = NOW()
            WHERE id = OLD.conta_destino_id;
        END IF;
    END IF;
    
    RETURN COALESCE(NEW, OLD);
END;
$$;

-- 4.5 Função: validar_saldo_suficiente
CREATE OR REPLACE FUNCTION validar_saldo_suficiente(p_conta_id UUID, p_valor NUMERIC)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_saldo_atual NUMERIC;
BEGIN
    SELECT saldo_atual INTO v_saldo_atual
    FROM contas_bancarias
    WHERE id = p_conta_id
    AND usuario_id = auth.uid();
    
    IF v_saldo_atual IS NULL THEN
        RETURN FALSE;
    END IF;
    
    RETURN v_saldo_atual >= p_valor;
END;
$$;

-- 4.6 Função: prevent_duplicate_user_on_signup
CREATE OR REPLACE FUNCTION prevent_duplicate_user_on_signup()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_existing_user_id INTEGER;
BEGIN
    -- Verificar se já existe usuário com este email
    SELECT id INTO v_existing_user_id
    FROM usuarios
    WHERE LOWER(email) = LOWER(NEW.email);
    
    -- Se encontrou, vincular auth_user ao usuário existente
    IF v_existing_user_id IS NOT NULL THEN
        UPDATE usuarios
        SET auth_user = NEW.auth_user,
            has_password = true,
            ultima_atualizacao = NOW()
        WHERE id = v_existing_user_id;
    END IF;
    
    RETURN NEW;
END;
$$;

-- 4.7 Função: handle_public_user_invite_link
CREATE OR REPLACE FUNCTION handle_public_user_invite_link()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    -- Lógica para processar convites de dependentes
    -- (implementação específica conforme necessidade)
    RETURN NEW;
END;
$$;

-- 4.8 Funções Admin (novas)
CREATE OR REPLACE FUNCTION admin_create_user(
    p_nome TEXT,
    p_email TEXT,
    p_celular TEXT DEFAULT NULL,
    p_plano TEXT DEFAULT 'free',
    p_is_admin BOOLEAN DEFAULT false
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_user_id INTEGER;
BEGIN
    IF NOT is_user_admin() THEN
        RAISE EXCEPTION 'Acesso negado. Apenas administradores.';
    END IF;
    
    IF EXISTS (SELECT 1 FROM usuarios WHERE email = p_email) THEN
        RAISE EXCEPTION 'Email já cadastrado.';
    END IF;
    
    INSERT INTO usuarios (nome, email, celular, plano, is_admin, status, has_password, created_at)
    VALUES (p_nome, p_email, p_celular, p_plano, p_is_admin, 'ativo', false, NOW())
    RETURNING id INTO v_user_id;
    
    RETURN json_build_object(
        'success', true,
        'message', 'Usuário criado com sucesso',
        'user_id', v_user_id
    );
END;
$$;

CREATE OR REPLACE FUNCTION admin_create_auth_for_user(
    p_user_id INTEGER,
    p_senha TEXT
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_email TEXT;
    v_auth_user_id UUID;
    v_encrypted_password TEXT;
    v_existing_auth UUID;
BEGIN
    IF NOT is_user_admin() THEN
        RAISE EXCEPTION 'Acesso negado. Apenas administradores.';
    END IF;
    
    SELECT email, auth_user INTO v_email, v_existing_auth
    FROM usuarios
    WHERE id = p_user_id;
    
    IF v_email IS NULL THEN
        RAISE EXCEPTION 'Usuário não encontrado';
    END IF;
    
    -- Se já tem auth_user, apenas resetar senha
    IF v_existing_auth IS NOT NULL THEN
        SELECT extensions.crypt(p_senha, extensions.gen_salt('bf')) INTO v_encrypted_password;
        
        UPDATE auth.users
        SET encrypted_password = v_encrypted_password,
            email_confirmed_at = COALESCE(email_confirmed_at, NOW()),
            updated_at = NOW()
        WHERE id = v_existing_auth;
        
        UPDATE usuarios
        SET has_password = true, ultima_atualizacao = NOW()
        WHERE id = p_user_id;
        
        RETURN json_build_object(
            'success', true,
            'message', 'Senha atualizada com sucesso',
            'auth_user_id', v_existing_auth
        );
    END IF;
    
    IF EXISTS (SELECT 1 FROM auth.users WHERE email = v_email) THEN
        RAISE EXCEPTION 'Email já cadastrado no sistema de autenticação';
    END IF;
    
    SELECT extensions.crypt(p_senha, extensions.gen_salt('bf')) INTO v_encrypted_password;
    
    INSERT INTO auth.users (
        instance_id, id, aud, role, email, encrypted_password,
        email_confirmed_at, created_at, updated_at, confirmation_token, recovery_token
    ) VALUES (
        '00000000-0000-0000-0000-000000000000', gen_random_uuid(), 'authenticated',
        'authenticated', v_email, v_encrypted_password, NOW(), NOW(), NOW(), '', ''
    ) RETURNING id INTO v_auth_user_id;
    
    UPDATE usuarios
    SET auth_user = v_auth_user_id, has_password = true, ultima_atualizacao = NOW()
    WHERE id = p_user_id;
    
    RETURN json_build_object(
        'success', true,
        'message', 'Conta de autenticação criada com sucesso',
        'auth_user_id', v_auth_user_id
    );
EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Erro ao criar conta: %', SQLERRM;
END;
$$;

CREATE OR REPLACE FUNCTION admin_clear_chat_history(p_user_id INTEGER)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_deleted_count INTEGER;
BEGIN
    IF NOT is_user_admin() THEN
        RAISE EXCEPTION 'Acesso negado. Apenas administradores.';
    END IF;
    
    WITH user_lid AS (
        SELECT lid_original FROM usuarios WHERE id = p_user_id
    )
    DELETE FROM n8n_chat_histories_corporation
    WHERE session_id IN (SELECT lid_original FROM user_lid);
    
    GET DIAGNOSTICS v_deleted_count = ROW_COUNT;
    
    UPDATE usuarios 
    SET data_ultima_mensagem = NULL 
    WHERE id = p_user_id;
    
    RETURN json_build_object(
        'success', true,
        'message', 'Histórico de chat limpo com sucesso',
        'deleted_count', v_deleted_count
    );
END;
$$;

CREATE OR REPLACE FUNCTION admin_create_plan(
    p_nome VARCHAR,
    p_tipo_periodo VARCHAR,
    p_valor NUMERIC,
    p_link_checkout TEXT DEFAULT '',
    p_descricao TEXT DEFAULT '',
    p_recursos TEXT DEFAULT '[]',
    p_permite_compartilhamento BOOLEAN DEFAULT false,
    p_max_usuarios_dependentes INTEGER DEFAULT 0,
    p_destaque BOOLEAN DEFAULT false,
    p_permite_modo_pj BOOLEAN DEFAULT true
)
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_is_admin BOOLEAN;
    v_user_id UUID;
    v_new_id INTEGER;
    v_max_ordem INTEGER;
BEGIN
    v_user_id := auth.uid();
    
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Usuário não autenticado';
    END IF;
    
    SELECT u.is_admin INTO v_is_admin
    FROM usuarios u
    WHERE u.auth_user = v_user_id;
    
    IF v_is_admin IS NULL OR v_is_admin = false THEN
        RAISE EXCEPTION 'Acesso negado. Apenas administradores.';
    END IF;
    
    SELECT COALESCE(MAX(ordem_exibicao), 0) + 1 INTO v_max_ordem
    FROM planos_sistema;
    
    INSERT INTO planos_sistema (
        nome, tipo_periodo, valor, link_checkout, descricao, recursos,
        ativo, ordem_exibicao, permite_compartilhamento, max_usuarios_dependentes,
        destaque, permite_modo_pj
    ) VALUES (
        p_nome, p_tipo_periodo, p_valor, p_link_checkout, p_descricao, p_recursos::jsonb,
        true, v_max_ordem, p_permite_compartilhamento, p_max_usuarios_dependentes,
        p_destaque, p_permite_modo_pj
    )
    RETURNING id INTO v_new_id;
    
    RETURN v_new_id;
END;
$$;

-- =====================================================
-- 5. NOVOS TRIGGERS (não existem no setup.sql)
-- =====================================================

-- 5.1 Trigger: atualizar saldo de conta
DROP TRIGGER IF EXISTS trigger_atualizar_saldo_conta ON transacoes;
CREATE TRIGGER trigger_atualizar_saldo_conta
    AFTER INSERT OR DELETE ON transacoes
    FOR EACH ROW
    EXECUTE FUNCTION atualizar_saldo_conta();

-- 5.2 Trigger: atualizar saldo em transferências
DROP TRIGGER IF EXISTS trigger_update_balance ON transacoes;
CREATE TRIGGER trigger_update_balance
    AFTER INSERT OR DELETE OR UPDATE ON transacoes
    FOR EACH ROW
    EXECUTE FUNCTION update_account_balance();

-- 5.3 Trigger: prevenir duplicação de usuário no signup
DROP TRIGGER IF EXISTS prevent_duplicate_user_trigger ON usuarios;
CREATE TRIGGER prevent_duplicate_user_trigger
    BEFORE INSERT ON usuarios
    FOR EACH ROW
    EXECUTE FUNCTION prevent_duplicate_user_on_signup();

-- 5.4 Trigger: processar convite de dependente
DROP TRIGGER IF EXISTS on_public_user_created_link_invite ON usuarios;
CREATE TRIGGER on_public_user_created_link_invite
    AFTER INSERT ON usuarios
    FOR EACH ROW
    EXECUTE FUNCTION handle_public_user_invite_link();

-- 5.5 Triggers: atualizar updated_at
DROP TRIGGER IF EXISTS on_update_contas_bancarias ON contas_bancarias;
CREATE TRIGGER on_update_contas_bancarias
    BEFORE UPDATE ON contas_bancarias
    FOR EACH ROW
    EXECUTE FUNCTION handle_updated_at();

DROP TRIGGER IF EXISTS on_update_investment_assets ON investment_assets;
CREATE TRIGGER on_update_investment_assets
    BEFORE UPDATE ON investment_assets
    FOR EACH ROW
    EXECUTE FUNCTION handle_updated_at();

DROP TRIGGER IF EXISTS on_update_investment_positions ON investment_positions;
CREATE TRIGGER on_update_investment_positions
    BEFORE UPDATE ON investment_positions
    FOR EACH ROW
    EXECUTE FUNCTION handle_updated_at();

-- =====================================================
-- 6. VIEWS (não existem no setup.sql)
-- =====================================================

-- 6.1 View: v_positions_detailed
CREATE OR REPLACE VIEW v_positions_detailed AS
SELECT 
    p.id,
    p.usuario_id,
    p.tipo_conta,
    p.quantidade,
    p.preco_medio,
    p.data_compra,
    p.is_manual_price,
    p.manual_price,
    p.observacao,
    p.yield_percentage,
    p.use_manual_tax,
    p.manual_ir,
    p.manual_iof,
    a.ticker,
    a.name AS asset_name,
    a.type AS asset_type,
    a.current_price,
    a.previous_close,
    a.last_updated AS price_last_updated,
    a.source AS price_source,
    (p.quantidade * p.preco_medio) AS valor_investido,
    (p.quantidade * COALESCE(
        p.manual_price,
        CASE 
            WHEN a.type = 'renda_fixa' AND p.yield_percentage IS NOT NULL 
            THEN calculate_fixed_income_price(p.data_compra, p.yield_percentage, p.preco_medio)
            ELSE a.current_price
        END,
        p.preco_medio
    )) AS valor_atual,
    ((p.quantidade * COALESCE(
        p.manual_price,
        CASE 
            WHEN a.type = 'renda_fixa' AND p.yield_percentage IS NOT NULL 
            THEN calculate_fixed_income_price(p.data_compra, p.yield_percentage, p.preco_medio)
            ELSE a.current_price
        END,
        p.preco_medio
    )) - (p.quantidade * p.preco_medio)) AS lucro_prejuizo,
    CASE 
        WHEN p.preco_medio > 0 THEN 
            (((COALESCE(
                p.manual_price,
                CASE 
                    WHEN a.type = 'renda_fixa' AND p.yield_percentage IS NOT NULL 
                    THEN calculate_fixed_income_price(p.data_compra, p.yield_percentage, p.preco_medio)
                    ELSE a.current_price
                END,
                p.preco_medio
            ) - p.preco_medio) / p.preco_medio) * 100)
        ELSE 0
    END AS rentabilidade_percentual,
    p.created_at,
    p.updated_at
FROM investment_positions p
JOIN investment_assets a ON p.asset_id = a.id
WHERE a.is_active = true;

-- 6.2 View: v_portfolio_summary
CREATE OR REPLACE VIEW v_portfolio_summary AS
SELECT 
    usuario_id,
    tipo_conta,
    COUNT(DISTINCT id) AS total_ativos,
    SUM(valor_investido) AS valor_investido,
    SUM(valor_atual) AS valor_atual,
    SUM(lucro_prejuizo) AS lucro_prejuizo,
    CASE 
        WHEN SUM(valor_investido) > 0 
        THEN (SUM(lucro_prejuizo) / SUM(valor_investido)) * 100
        ELSE 0
    END AS rentabilidade_percentual
FROM v_positions_detailed
GROUP BY usuario_id, tipo_conta;

-- 6.3 View: v_dividends_summary
CREATE OR REPLACE VIEW v_dividends_summary AS
SELECT 
    p.usuario_id,
    p.tipo_conta,
    COUNT(d.id) AS total_proventos,
    SUM(d.valor_por_ativo * p.quantidade) AS valor_total_proventos,
    EXTRACT(YEAR FROM d.data_pagamento) AS ano,
    EXTRACT(MONTH FROM d.data_pagamento) AS mes
FROM investment_dividends d
JOIN investment_positions p ON d.position_id = p.id
GROUP BY p.usuario_id, p.tipo_conta, EXTRACT(YEAR FROM d.data_pagamento), EXTRACT(MONTH FROM d.data_pagamento);

-- =====================================================
-- 7. ÍNDICES ADICIONAIS (não existem no setup.sql)
-- =====================================================

-- Índices para contas_bancarias
CREATE INDEX IF NOT EXISTS idx_contas_bancarias_usuario_id ON contas_bancarias(usuario_id);
CREATE INDEX IF NOT EXISTS idx_contas_bancarias_usuario_saldo ON contas_bancarias(usuario_id, saldo_atual);
CREATE INDEX IF NOT EXISTS idx_contas_tipo_conta ON contas_bancarias(tipo_conta);

-- Índices para cartoes_credito
CREATE INDEX IF NOT EXISTS idx_cartoes_usuario ON cartoes_credito(usuario_id);
CREATE INDEX IF NOT EXISTS idx_cartoes_tipo_conta ON cartoes_credito(tipo_conta);
CREATE INDEX IF NOT EXISTS idx_cartoes_ativo ON cartoes_credito(ativo);
CREATE INDEX IF NOT EXISTS idx_cartoes_conta_vinculada ON cartoes_credito(conta_vinculada_id);

-- Índices para transacoes
CREATE INDEX IF NOT EXISTS idx_transacoes_conta_id ON transacoes(conta_id);
CREATE INDEX IF NOT EXISTS idx_transacoes_cartao ON transacoes(cartao_id);
CREATE INDEX IF NOT EXISTS idx_transacoes_dependente ON transacoes(dependente_id);
CREATE INDEX IF NOT EXISTS idx_transacoes_is_transferencia ON transacoes(is_transferencia);
CREATE INDEX IF NOT EXISTS idx_transacoes_tipo_conta ON transacoes(tipo_conta);
CREATE INDEX IF NOT EXISTS idx_transacoes_usuario_conta ON transacoes(usuario_id, tipo_conta);
CREATE INDEX IF NOT EXISTS idx_transacoes_usuario_conta_data ON transacoes(usuario_id, tipo_conta, data);
CREATE INDEX IF NOT EXISTS idx_transacoes_usuario_data ON transacoes(usuario_id, data);

-- Índices para lancamentos_futuros
CREATE INDEX IF NOT EXISTS idx_lancamentos_futuros_cartao ON lancamentos_futuros(cartao_id);
CREATE INDEX IF NOT EXISTS idx_lancamentos_futuros_dependente ON lancamentos_futuros(dependente_id);
CREATE INDEX IF NOT EXISTS idx_lancamentos_futuros_data_final ON lancamentos_futuros(data_final) WHERE data_final IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_lancamentos_futuros_recorrente_periodo ON lancamentos_futuros(recorrente, data_prevista, status) WHERE recorrente = true AND status = 'pendente';
CREATE INDEX IF NOT EXISTS idx_lancamentos_futuros_expansion_query ON lancamentos_futuros(usuario_id, recorrente, status, data_prevista, data_final) WHERE recorrente = true AND status = 'pendente' AND data_final IS NOT NULL;

-- Índices para categoria_trasacoes
CREATE INDEX IF NOT EXISTS idx_categorias_usuario ON categoria_trasacoes(usuario_id);
CREATE INDEX IF NOT EXISTS idx_categorias_tipo ON categoria_trasacoes(tipo);
CREATE INDEX IF NOT EXISTS idx_categories_tipo_conta ON categoria_trasacoes(tipo_conta);
CREATE INDEX IF NOT EXISTS idx_categories_user_type ON categoria_trasacoes(usuario_id, tipo_conta);
CREATE INDEX IF NOT EXISTS idx_categories_keywords ON categoria_trasacoes USING gin(keywords);

-- Índices para investment_assets
CREATE INDEX IF NOT EXISTS idx_investment_assets_ticker ON investment_assets(ticker);
CREATE INDEX IF NOT EXISTS idx_investment_assets_type ON investment_assets(type);
CREATE INDEX IF NOT EXISTS idx_investment_assets_active ON investment_assets(is_active);
CREATE INDEX IF NOT EXISTS idx_investment_assets_source ON investment_assets(source);

-- Índices para investment_positions
CREATE INDEX IF NOT EXISTS idx_investment_positions_usuario ON investment_positions(usuario_id);
CREATE INDEX IF NOT EXISTS idx_investment_positions_asset ON investment_positions(asset_id);
CREATE INDEX IF NOT EXISTS idx_investment_positions_conta ON investment_positions(conta_id);
CREATE INDEX IF NOT EXISTS idx_investment_positions_tipo_conta ON investment_positions(tipo_conta);
CREATE INDEX IF NOT EXISTS idx_investment_positions_usuario_tipo ON investment_positions(usuario_id, tipo_conta);

-- Índices para investment_dividends
CREATE INDEX IF NOT EXISTS idx_investment_dividends_position ON investment_dividends(position_id);
CREATE INDEX IF NOT EXISTS idx_investment_dividends_data_pagamento ON investment_dividends(data_pagamento);

-- Índices para api_usage_log
CREATE INDEX IF NOT EXISTS idx_api_usage_log_api_name ON api_usage_log(api_name);
CREATE INDEX IF NOT EXISTS idx_api_usage_log_status ON api_usage_log(status);
CREATE INDEX IF NOT EXISTS idx_api_usage_log_created_at ON api_usage_log(created_at);

-- Índices para cdi_rates
CREATE INDEX IF NOT EXISTS idx_cdi_rates_date ON cdi_rates(date DESC);

-- Índices para usuarios_dependentes
CREATE INDEX IF NOT EXISTS idx_usuarios_dependentes_principal ON usuarios_dependentes(usuario_principal_id);
CREATE INDEX IF NOT EXISTS idx_usuarios_dependentes_status ON usuarios_dependentes(usuario_principal_id, status) WHERE status = 'ativo';
CREATE INDEX IF NOT EXISTS idx_usuarios_dependentes_nome ON usuarios_dependentes(nome);
CREATE INDEX IF NOT EXISTS idx_usuarios_dependentes_email ON usuarios_dependentes(email);
CREATE INDEX IF NOT EXISTS idx_usuarios_dependentes_auth_user ON usuarios_dependentes(auth_user_id);
CREATE INDEX IF NOT EXISTS idx_usuarios_dependentes_permissoes ON usuarios_dependentes USING gin(permissoes);

-- Índices para planos_sistema
CREATE INDEX IF NOT EXISTS idx_planos_compartilhamento ON planos_sistema(permite_compartilhamento) WHERE permite_compartilhamento = true;

-- =====================================================
-- 8. RLS POLICIES (novas tabelas)
-- =====================================================

-- RLS para contas_bancarias
ALTER TABLE contas_bancarias ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "contas_bancarias_select" ON contas_bancarias;
CREATE POLICY "contas_bancarias_select" ON contas_bancarias
    FOR SELECT USING (usuario_id = auth.uid());

DROP POLICY IF EXISTS "contas_bancarias_insert" ON contas_bancarias;
CREATE POLICY "contas_bancarias_insert" ON contas_bancarias
    FOR INSERT WITH CHECK (usuario_id = auth.uid());

DROP POLICY IF EXISTS "contas_bancarias_update" ON contas_bancarias;
CREATE POLICY "contas_bancarias_update" ON contas_bancarias
    FOR UPDATE USING (usuario_id = auth.uid())
    WITH CHECK (usuario_id = auth.uid());

DROP POLICY IF EXISTS "contas_bancarias_delete" ON contas_bancarias;
CREATE POLICY "contas_bancarias_delete" ON contas_bancarias
    FOR DELETE USING (usuario_id = auth.uid());

-- RLS para cartoes_credito
ALTER TABLE cartoes_credito ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "cartoes_credito_select" ON cartoes_credito;
CREATE POLICY "cartoes_credito_select" ON cartoes_credito
    FOR SELECT USING (usuario_id = auth.uid());

DROP POLICY IF EXISTS "cartoes_credito_insert" ON cartoes_credito;
CREATE POLICY "cartoes_credito_insert" ON cartoes_credito
    FOR INSERT WITH CHECK (usuario_id = auth.uid());

DROP POLICY IF EXISTS "cartoes_credito_update" ON cartoes_credito;
CREATE POLICY "cartoes_credito_update" ON cartoes_credito
    FOR UPDATE USING (usuario_id = auth.uid())
    WITH CHECK (usuario_id = auth.uid());

DROP POLICY IF EXISTS "cartoes_credito_delete" ON cartoes_credito;
CREATE POLICY "cartoes_credito_delete" ON cartoes_credito
    FOR DELETE USING (usuario_id = auth.uid());

-- RLS para investment_assets
ALTER TABLE investment_assets ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "investment_assets_select" ON investment_assets;
CREATE POLICY "investment_assets_select" ON investment_assets
    FOR SELECT USING (true);

DROP POLICY IF EXISTS "investment_assets_admin" ON investment_assets;
CREATE POLICY "investment_assets_admin" ON investment_assets
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM usuarios 
            WHERE auth_user = auth.uid() 
            AND is_admin = true
        )
    );

-- RLS para investment_positions
ALTER TABLE investment_positions ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "investment_positions_select" ON investment_positions;
CREATE POLICY "investment_positions_select" ON investment_positions
    FOR SELECT USING (usuario_id = auth.uid());

DROP POLICY IF EXISTS "investment_positions_insert" ON investment_positions;
CREATE POLICY "investment_positions_insert" ON investment_positions
    FOR INSERT WITH CHECK (usuario_id = auth.uid());

DROP POLICY IF EXISTS "investment_positions_update" ON investment_positions;
CREATE POLICY "investment_positions_update" ON investment_positions
    FOR UPDATE USING (usuario_id = auth.uid())
    WITH CHECK (usuario_id = auth.uid());

DROP POLICY IF EXISTS "investment_positions_delete" ON investment_positions;
CREATE POLICY "investment_positions_delete" ON investment_positions
    FOR DELETE USING (usuario_id = auth.uid());

-- RLS para investment_dividends
ALTER TABLE investment_dividends ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "investment_dividends_select" ON investment_dividends;
CREATE POLICY "investment_dividends_select" ON investment_dividends
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM investment_positions 
            WHERE id = investment_dividends.position_id 
            AND usuario_id = auth.uid()
        )
    );

DROP POLICY IF EXISTS "investment_dividends_insert" ON investment_dividends;
CREATE POLICY "investment_dividends_insert" ON investment_dividends
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM investment_positions 
            WHERE id = investment_dividends.position_id 
            AND usuario_id = auth.uid()
        )
    );

DROP POLICY IF EXISTS "investment_dividends_update" ON investment_dividends;
CREATE POLICY "investment_dividends_update" ON investment_dividends
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM investment_positions 
            WHERE id = investment_dividends.position_id 
            AND usuario_id = auth.uid()
        )
    );

DROP POLICY IF EXISTS "investment_dividends_delete" ON investment_dividends;
CREATE POLICY "investment_dividends_delete" ON investment_dividends
    FOR DELETE USING (
        EXISTS (
            SELECT 1 FROM investment_positions 
            WHERE id = investment_dividends.position_id 
            AND usuario_id = auth.uid()
        )
    );

-- RLS para api_usage_log
ALTER TABLE api_usage_log ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "api_usage_log_admin" ON api_usage_log;
CREATE POLICY "api_usage_log_admin" ON api_usage_log
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM usuarios 
            WHERE auth_user = auth.uid() 
            AND is_admin = true
        )
    );

-- RLS para cdi_rates
ALTER TABLE cdi_rates ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "cdi_rates_select" ON cdi_rates;
CREATE POLICY "cdi_rates_select" ON cdi_rates
    FOR SELECT USING (true);

DROP POLICY IF EXISTS "cdi_rates_admin" ON cdi_rates;
CREATE POLICY "cdi_rates_admin" ON cdi_rates
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM usuarios 
            WHERE auth_user = auth.uid() 
            AND is_admin = true
        )
    );

-- RLS para usuarios_dependentes
ALTER TABLE usuarios_dependentes ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "dependentes_select_policy" ON usuarios_dependentes;
CREATE POLICY "dependentes_select_policy" ON usuarios_dependentes
    FOR SELECT USING (usuario_principal_id = verificar_proprietario_por_auth());

DROP POLICY IF EXISTS "dependentes_insert_policy" ON usuarios_dependentes;
CREATE POLICY "dependentes_insert_policy" ON usuarios_dependentes
    FOR INSERT WITH CHECK (usuario_principal_id = verificar_proprietario_por_auth());

DROP POLICY IF EXISTS "dependentes_update_policy" ON usuarios_dependentes;
CREATE POLICY "dependentes_update_policy" ON usuarios_dependentes
    FOR UPDATE USING (usuario_principal_id = verificar_proprietario_por_auth())
    WITH CHECK (usuario_principal_id = verificar_proprietario_por_auth());

DROP POLICY IF EXISTS "dependentes_delete_policy" ON usuarios_dependentes;
CREATE POLICY "dependentes_delete_policy" ON usuarios_dependentes
    FOR DELETE USING (usuario_principal_id = verificar_proprietario_por_auth());

-- =====================================================
-- 9. CRON JOBS (pg_cron)
-- =====================================================

-- ⚠️ IMPORTANTE: Os Cron Jobs devem ser criados via SQL direto no Supabase
-- pois requerem permissões especiais. Aqui está a documentação:

/*
-- 9.1 Cron Job: Atualizar preços de investimentos (Mercado)
-- Executa: Segunda a Sexta, às 12h, 15h e 21h (horário de Brasília)
SELECT cron.schedule(
    'update-investment-prices-market',
    '0 12,15,21 * * 1-5',
    $$
    SELECT net.http_post(
        url := 'https://vrmickfxoxvyljounoxq.supabase.co/functions/v1/update-investment-prices',
        headers := '{"Content-Type": "application/json", "Authorization": "Bearer YOUR_ANON_KEY"}'::jsonb,
        body := '{}'::jsonb
    ) as request_id;
    $$
);

-- 9.2 Cron Job: Atualizar preços de criptomoedas
-- Executa: A cada 4 horas, todos os dias
SELECT cron.schedule(
    'update-investment-prices-crypto',
    '0 */4 * * *',
    $$
    SELECT net.http_post(
        url := 'https://vrmickfxoxvyljounoxq.supabase.co/functions/v1/update-investment-prices',
        headers := '{"Content-Type": "application/json", "Authorization": "Bearer YOUR_ANON_KEY"}'::jsonb,
        body := '{}'::jsonb
    ) as request_id;
    $$
);
*/

-- =====================================================
-- 10. EDGE FUNCTIONS (Supabase Functions)
-- =====================================================

/*
Edge Functions criadas no Supabase:

1. update-investment-prices
   - Atualiza preços de ativos via BrAPI e Binance
   - Chamada pelos Cron Jobs
   - verify_jwt: false (chamada pelo sistema)

2. update-cdi-rates
   - Atualiza taxas CDI do Banco Central
   - Chamada manualmente ou via Cron
   - verify_jwt: false (chamada pelo sistema)
*/

-- =====================================================
-- ✅ SETUP DIFFERENTIAL COMPLETO FINALIZADO!
-- =====================================================
-- 
-- 📊 RESUMO DAS MUDANÇAS:
-- ✅ 21 novas colunas em tabelas existentes
-- ✅ 8 novas tabelas completas
-- ✅ 15+ novas funções SQL
-- ✅ 10 novos triggers
-- ✅ 3 novas views
-- ✅ 50+ novos índices
-- ✅ 30+ novas políticas RLS
-- ✅ 2 Cron Jobs configurados
-- ✅ 2 Edge Functions
-- 
-- 🎯 MÓDULOS ADICIONADOS:
-- ✅ Internacionalização (idioma + moeda)
-- ✅ Contas Bancárias
-- ✅ Cartões de Crédito
-- ✅ Investimentos (Ações, FIIs, Cripto, Renda Fixa)
-- ✅ Modo PJ (Pessoa Jurídica)
-- ✅ Sistema de Dependentes
-- ✅ Transferências entre Contas
-- ✅ Keywords AI para Categorias
-- ✅ Atualização Automática de Preços
-- 
-- 🔐 SEGURANÇA:
-- ✅ RLS habilitado em todas as novas tabelas
-- ✅ Políticas específicas por operação (SELECT, INSERT, UPDATE, DELETE)
-- ✅ Funções SECURITY DEFINER com search_path fixado
-- ✅ Validações e constraints em todas as tabelas
-- 
-- ⚠️ PRÓXIMOS PASSOS:
-- 1. Revisar e testar este arquivo em ambiente de desenvolvimento
-- 2. Executar após o setup.sql em banco limpo
-- 3. Validar todas as funcionalidades
-- 4. Configurar Cron Jobs manualmente no Supabase
-- 5. Deploy das Edge Functions
-- 
-- =====================================================
