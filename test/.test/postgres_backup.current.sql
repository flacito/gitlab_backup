--
-- PostgreSQL database dump
--

-- Dumped from database version 9.6.5
-- Dumped by pg_dump version 9.6.5

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: 
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


SET search_path = public, pg_catalog;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: testtable; Type: TABLE; Schema: public; Owner: testdbuser
--

CREATE TABLE testtable (
    id character varying(10) NOT NULL,
    message character varying(128)
);


ALTER TABLE testtable OWNER TO testdbuser;

--
-- Data for Name: testtable; Type: TABLE DATA; Schema: public; Owner: testdbuser
--

COPY testtable (id, message) FROM stdin;
A123456789	you know you are a little rocket man
A987654321	dotard! I will blow you up!
A246864228	bring it on shorty!
\.


--
-- Name: testtable idkey; Type: CONSTRAINT; Schema: public; Owner: testdbuser
--

ALTER TABLE ONLY testtable
    ADD CONSTRAINT idkey PRIMARY KEY (id);


--
-- PostgreSQL database dump complete
--

