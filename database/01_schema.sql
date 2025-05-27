--
-- PostgreSQL database dump
--

-- Dumped from database version 17.4
-- Dumped by pg_dump version 17.4

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: asset_classes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.asset_classes (
    class_id integer NOT NULL,
    class_name character varying(50) NOT NULL,
    description text,
    is_active boolean DEFAULT true
);


--
-- Name: asset_classes_class_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.asset_classes_class_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: asset_classes_class_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.asset_classes_class_id_seq OWNED BY public.asset_classes.class_id;


--
-- Name: asset_valuations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.asset_valuations (
    valuation_id integer NOT NULL,
    asset_id integer,
    valuation_date date NOT NULL,
    value_original_currency numeric(15,4),
    value_usd numeric(15,4),
    valuation_method character varying(30),
    notes text,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: asset_valuations_valuation_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.asset_valuations_valuation_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: asset_valuations_valuation_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.asset_valuations_valuation_id_seq OWNED BY public.asset_valuations.valuation_id;


--
-- Name: assets; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.assets (
    asset_id integer NOT NULL,
    asset_name character varying(200) NOT NULL,
    asset_type character varying(20) NOT NULL,
    convertibility character varying(20),
    class_id integer,
    description text,
    institution_id integer,
    usage_type character varying(20),
    base_currency character varying(3),
    current_value_original numeric(15,4),
    current_value_usd numeric(15,4),
    annual_income numeric(14,4) DEFAULT 0,
    location character varying(100),
    original_purchase_price numeric(14,4),
    purchase_date date,
    last_manual_update timestamp without time zone,
    last_api_update timestamp without time zone,
    auto_update_enabled boolean DEFAULT false,
    is_active boolean DEFAULT true,
    notes text,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT assets_asset_type_check CHECK (((asset_type)::text = ANY ((ARRAY['Tangible'::character varying, 'Intangible'::character varying])::text[]))),
    CONSTRAINT assets_convertibility_check CHECK (((convertibility)::text = ANY ((ARRAY['Current'::character varying, 'Non-current'::character varying])::text[]))),
    CONSTRAINT assets_usage_type_check CHECK (((usage_type)::text = ANY ((ARRAY['Operating'::character varying, 'Non-operating'::character varying])::text[])))
);


--
-- Name: assets_asset_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.assets_asset_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: assets_asset_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.assets_asset_id_seq OWNED BY public.assets.asset_id;


--
-- Name: currencies; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.currencies (
    currency_code character varying(3) NOT NULL,
    currency_name character varying(50) NOT NULL,
    symbol character varying(5),
    is_active boolean DEFAULT true
);


--
-- Name: current_net_worth; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.current_net_worth AS
 SELECT ac.class_name,
    sum(a.current_value_usd) AS total_value_usd,
    count(*) AS asset_count
   FROM (public.assets a
     JOIN public.asset_classes ac ON ((a.class_id = ac.class_id)))
  WHERE (a.is_active = true)
  GROUP BY ac.class_id, ac.class_name
  ORDER BY (sum(a.current_value_usd)) DESC;


--
-- Name: dividends; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.dividends (
    dividend_id integer NOT NULL,
    symbol character varying(20),
    ex_dividend_date date NOT NULL,
    record_date date,
    payment_date date,
    declaration_date date,
    dividend_amount numeric(12,6) NOT NULL,
    frequency character varying(20),
    currency character varying(3),
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: dividends_dividend_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.dividends_dividend_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: dividends_dividend_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.dividends_dividend_id_seq OWNED BY public.dividends.dividend_id;


--
-- Name: exchange_rates; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.exchange_rates (
    from_currency character varying(3) NOT NULL,
    to_currency character varying(3) NOT NULL,
    rate numeric(12,6) NOT NULL,
    rate_date date NOT NULL,
    data_source character varying(30) DEFAULT 'FMP'::character varying,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: institutions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.institutions (
    institution_id integer NOT NULL,
    institution_name character varying(100) NOT NULL,
    institution_type character varying(50),
    country character varying(50),
    supports_api boolean DEFAULT false,
    api_provider character varying(50),
    website_url character varying(200),
    is_active boolean DEFAULT true
);


--
-- Name: institutions_institution_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.institutions_institution_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: institutions_institution_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.institutions_institution_id_seq OWNED BY public.institutions.institution_id;


--
-- Name: investment_accounts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.investment_accounts (
    account_id integer NOT NULL,
    asset_id integer,
    account_number character varying(50),
    account_type character varying(30),
    institution_id integer,
    base_currency character varying(3),
    cash_balance numeric(15,4) DEFAULT 0,
    total_market_value numeric(15,4) DEFAULT 0,
    api_connection_status character varying(20) DEFAULT 'Manual'::character varying,
    last_sync timestamp without time zone,
    is_active boolean DEFAULT true
);


--
-- Name: investment_accounts_account_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.investment_accounts_account_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: investment_accounts_account_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.investment_accounts_account_id_seq OWNED BY public.investment_accounts.account_id;


--
-- Name: market_prices; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.market_prices (
    symbol character varying(20) NOT NULL,
    price numeric(12,4) NOT NULL,
    price_date date NOT NULL,
    currency character varying(3),
    data_source character varying(30) DEFAULT 'FMP'::character varying,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: net_worth_snapshots; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.net_worth_snapshots (
    snapshot_id integer NOT NULL,
    snapshot_date date NOT NULL,
    total_assets_usd numeric(18,4),
    total_liabilities_usd numeric(18,4),
    net_worth_usd numeric(18,4),
    breakdown_by_class jsonb,
    breakdown_by_currency jsonb,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: net_worth_snapshots_snapshot_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.net_worth_snapshots_snapshot_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: net_worth_snapshots_snapshot_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.net_worth_snapshots_snapshot_id_seq OWNED BY public.net_worth_snapshots.snapshot_id;


--
-- Name: positions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.positions (
    position_id integer NOT NULL,
    account_id integer,
    symbol character varying(20),
    quantity numeric(15,6) NOT NULL,
    average_cost_basis numeric(12,4),
    current_price numeric(12,4),
    market_value numeric(15,4),
    unrealized_gain_loss numeric(15,4),
    unrealized_gain_loss_percent numeric(8,4),
    currency character varying(3),
    last_updated timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: portfolio_summary; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.portfolio_summary AS
 SELECT ia.account_id,
    i.institution_name,
    ia.account_type,
    sum(p.market_value) AS total_market_value,
    sum(p.unrealized_gain_loss) AS total_unrealized_gain_loss,
    count(p.position_id) AS positions_count
   FROM ((public.investment_accounts ia
     JOIN public.institutions i ON ((ia.institution_id = i.institution_id)))
     LEFT JOIN public.positions p ON ((ia.account_id = p.account_id)))
  WHERE (ia.is_active = true)
  GROUP BY ia.account_id, i.institution_name, ia.account_type;


--
-- Name: positions_position_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.positions_position_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: positions_position_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.positions_position_id_seq OWNED BY public.positions.position_id;


--
-- Name: securities_master; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.securities_master (
    symbol character varying(20) NOT NULL,
    security_name character varying(200) NOT NULL,
    security_type character varying(30) NOT NULL,
    exchange character varying(10),
    sector character varying(50),
    currency character varying(3),
    country character varying(50),
    isin character varying(20),
    cusip character varying(20),
    is_active boolean DEFAULT true,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: transactions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.transactions (
    transaction_id integer NOT NULL,
    account_id integer,
    symbol character varying(20),
    transaction_type character varying(20) NOT NULL,
    quantity numeric(15,6),
    price numeric(12,4),
    gross_amount numeric(15,4),
    fees numeric(12,4) DEFAULT 0,
    net_amount numeric(15,4),
    transaction_date date NOT NULL,
    settlement_date date,
    currency character varying(3),
    external_transaction_id character varying(100),
    description text,
    imported_from character varying(50),
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: transactions_transaction_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.transactions_transaction_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: transactions_transaction_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.transactions_transaction_id_seq OWNED BY public.transactions.transaction_id;


--
-- Name: user_settings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_settings (
    setting_id integer NOT NULL,
    setting_name character varying(50) NOT NULL,
    setting_value text,
    setting_type character varying(20) DEFAULT 'string'::character varying,
    description text
);


--
-- Name: user_settings_setting_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.user_settings_setting_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: user_settings_setting_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.user_settings_setting_id_seq OWNED BY public.user_settings.setting_id;


--
-- Name: asset_classes class_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.asset_classes ALTER COLUMN class_id SET DEFAULT nextval('public.asset_classes_class_id_seq'::regclass);


--
-- Name: asset_valuations valuation_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.asset_valuations ALTER COLUMN valuation_id SET DEFAULT nextval('public.asset_valuations_valuation_id_seq'::regclass);


--
-- Name: assets asset_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.assets ALTER COLUMN asset_id SET DEFAULT nextval('public.assets_asset_id_seq'::regclass);


--
-- Name: dividends dividend_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dividends ALTER COLUMN dividend_id SET DEFAULT nextval('public.dividends_dividend_id_seq'::regclass);


--
-- Name: institutions institution_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.institutions ALTER COLUMN institution_id SET DEFAULT nextval('public.institutions_institution_id_seq'::regclass);


--
-- Name: investment_accounts account_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.investment_accounts ALTER COLUMN account_id SET DEFAULT nextval('public.investment_accounts_account_id_seq'::regclass);


--
-- Name: net_worth_snapshots snapshot_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.net_worth_snapshots ALTER COLUMN snapshot_id SET DEFAULT nextval('public.net_worth_snapshots_snapshot_id_seq'::regclass);


--
-- Name: positions position_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.positions ALTER COLUMN position_id SET DEFAULT nextval('public.positions_position_id_seq'::regclass);


--
-- Name: transactions transaction_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.transactions ALTER COLUMN transaction_id SET DEFAULT nextval('public.transactions_transaction_id_seq'::regclass);


--
-- Name: user_settings setting_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_settings ALTER COLUMN setting_id SET DEFAULT nextval('public.user_settings_setting_id_seq'::regclass);


--
-- Name: asset_classes asset_classes_class_name_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.asset_classes
    ADD CONSTRAINT asset_classes_class_name_key UNIQUE (class_name);


--
-- Name: asset_classes asset_classes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.asset_classes
    ADD CONSTRAINT asset_classes_pkey PRIMARY KEY (class_id);


--
-- Name: asset_valuations asset_valuations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.asset_valuations
    ADD CONSTRAINT asset_valuations_pkey PRIMARY KEY (valuation_id);


--
-- Name: assets assets_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.assets
    ADD CONSTRAINT assets_pkey PRIMARY KEY (asset_id);


--
-- Name: currencies currencies_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.currencies
    ADD CONSTRAINT currencies_pkey PRIMARY KEY (currency_code);


--
-- Name: dividends dividends_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dividends
    ADD CONSTRAINT dividends_pkey PRIMARY KEY (dividend_id);


--
-- Name: dividends dividends_symbol_exdate_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dividends
    ADD CONSTRAINT dividends_symbol_exdate_unique UNIQUE (symbol, ex_dividend_date);


--
-- Name: exchange_rates exchange_rates_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.exchange_rates
    ADD CONSTRAINT exchange_rates_pkey PRIMARY KEY (from_currency, to_currency, rate_date);


--
-- Name: institutions institutions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.institutions
    ADD CONSTRAINT institutions_pkey PRIMARY KEY (institution_id);


--
-- Name: investment_accounts investment_accounts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.investment_accounts
    ADD CONSTRAINT investment_accounts_pkey PRIMARY KEY (account_id);


--
-- Name: market_prices market_prices_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.market_prices
    ADD CONSTRAINT market_prices_pkey PRIMARY KEY (symbol, price_date);


--
-- Name: net_worth_snapshots net_worth_snapshots_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.net_worth_snapshots
    ADD CONSTRAINT net_worth_snapshots_pkey PRIMARY KEY (snapshot_id);


--
-- Name: positions positions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.positions
    ADD CONSTRAINT positions_pkey PRIMARY KEY (position_id);


--
-- Name: securities_master securities_master_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.securities_master
    ADD CONSTRAINT securities_master_pkey PRIMARY KEY (symbol);


--
-- Name: transactions transactions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.transactions
    ADD CONSTRAINT transactions_pkey PRIMARY KEY (transaction_id);


--
-- Name: user_settings user_settings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_settings
    ADD CONSTRAINT user_settings_pkey PRIMARY KEY (setting_id);


--
-- Name: user_settings user_settings_setting_name_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_settings
    ADD CONSTRAINT user_settings_setting_name_key UNIQUE (setting_name);


--
-- Name: idx_assets_class_active; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_assets_class_active ON public.assets USING btree (class_id, is_active);


--
-- Name: idx_exchange_rates_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_exchange_rates_date ON public.exchange_rates USING btree (rate_date DESC);


--
-- Name: idx_market_prices_symbol_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_market_prices_symbol_date ON public.market_prices USING btree (symbol, price_date DESC);


--
-- Name: idx_positions_account_symbol; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_positions_account_symbol ON public.positions USING btree (account_id, symbol);


--
-- Name: idx_transactions_account_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_transactions_account_date ON public.transactions USING btree (account_id, transaction_date);


--
-- Name: asset_valuations asset_valuations_asset_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.asset_valuations
    ADD CONSTRAINT asset_valuations_asset_id_fkey FOREIGN KEY (asset_id) REFERENCES public.assets(asset_id);


--
-- Name: assets assets_base_currency_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.assets
    ADD CONSTRAINT assets_base_currency_fkey FOREIGN KEY (base_currency) REFERENCES public.currencies(currency_code);


--
-- Name: assets assets_class_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.assets
    ADD CONSTRAINT assets_class_id_fkey FOREIGN KEY (class_id) REFERENCES public.asset_classes(class_id);


--
-- Name: assets assets_institution_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.assets
    ADD CONSTRAINT assets_institution_id_fkey FOREIGN KEY (institution_id) REFERENCES public.institutions(institution_id);


--
-- Name: dividends dividends_currency_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dividends
    ADD CONSTRAINT dividends_currency_fkey FOREIGN KEY (currency) REFERENCES public.currencies(currency_code);


--
-- Name: dividends dividends_symbol_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dividends
    ADD CONSTRAINT dividends_symbol_fkey FOREIGN KEY (symbol) REFERENCES public.securities_master(symbol);


--
-- Name: exchange_rates exchange_rates_from_currency_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.exchange_rates
    ADD CONSTRAINT exchange_rates_from_currency_fkey FOREIGN KEY (from_currency) REFERENCES public.currencies(currency_code);


--
-- Name: exchange_rates exchange_rates_to_currency_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.exchange_rates
    ADD CONSTRAINT exchange_rates_to_currency_fkey FOREIGN KEY (to_currency) REFERENCES public.currencies(currency_code);


--
-- Name: investment_accounts investment_accounts_asset_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.investment_accounts
    ADD CONSTRAINT investment_accounts_asset_id_fkey FOREIGN KEY (asset_id) REFERENCES public.assets(asset_id);


--
-- Name: investment_accounts investment_accounts_base_currency_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.investment_accounts
    ADD CONSTRAINT investment_accounts_base_currency_fkey FOREIGN KEY (base_currency) REFERENCES public.currencies(currency_code);


--
-- Name: investment_accounts investment_accounts_institution_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.investment_accounts
    ADD CONSTRAINT investment_accounts_institution_id_fkey FOREIGN KEY (institution_id) REFERENCES public.institutions(institution_id);


--
-- Name: market_prices market_prices_currency_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.market_prices
    ADD CONSTRAINT market_prices_currency_fkey FOREIGN KEY (currency) REFERENCES public.currencies(currency_code);


--
-- Name: market_prices market_prices_symbol_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.market_prices
    ADD CONSTRAINT market_prices_symbol_fkey FOREIGN KEY (symbol) REFERENCES public.securities_master(symbol);


--
-- Name: positions positions_account_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.positions
    ADD CONSTRAINT positions_account_id_fkey FOREIGN KEY (account_id) REFERENCES public.investment_accounts(account_id);


--
-- Name: positions positions_currency_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.positions
    ADD CONSTRAINT positions_currency_fkey FOREIGN KEY (currency) REFERENCES public.currencies(currency_code);


--
-- Name: positions positions_symbol_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.positions
    ADD CONSTRAINT positions_symbol_fkey FOREIGN KEY (symbol) REFERENCES public.securities_master(symbol);


--
-- Name: securities_master securities_master_currency_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.securities_master
    ADD CONSTRAINT securities_master_currency_fkey FOREIGN KEY (currency) REFERENCES public.currencies(currency_code);


--
-- Name: transactions transactions_account_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.transactions
    ADD CONSTRAINT transactions_account_id_fkey FOREIGN KEY (account_id) REFERENCES public.investment_accounts(account_id);


--
-- Name: transactions transactions_currency_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.transactions
    ADD CONSTRAINT transactions_currency_fkey FOREIGN KEY (currency) REFERENCES public.currencies(currency_code);


--
-- Name: transactions transactions_symbol_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.transactions
    ADD CONSTRAINT transactions_symbol_fkey FOREIGN KEY (symbol) REFERENCES public.securities_master(symbol);


--
-- PostgreSQL database dump complete
--

