--
-- PostgreSQL database dump
--

-- Dumped from database version 11.5
-- Dumped by pg_dump version 11.5

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Data for Name: invoices; Type: TABLE DATA; Schema: store; Owner: dude
--

SET SESSION AUTHORIZATION DEFAULT;

ALTER TABLE store.invoices DISABLE TRIGGER ALL;

INSERT INTO store.invoices (id, person_id, order_date, payment_date, payment_info, subtotal, shipping, total, country, address, ship_date, ship_info) VALUES (1, 4, '2019-10-02', '2019-10-02', 'PayPal #abc123', 15, 6, 21, 'US', 'Charlie Buckets
3 Skid Row
Hershey, PA 04141', '2019-10-03', 'usps# a1b2');
INSERT INTO store.invoices (id, person_id, order_date, payment_date, payment_info, subtotal, shipping, total, country, address, ship_date, ship_info) VALUES (2, 3, '2019-10-02', '2019-10-02', 'Visa #43625', 1499.9, 10, 1509.9, 'GB', 'Veruca Salt
10 Posh Lane
Poshest House
Kensington, London WC1 7NT', NULL, NULL);
INSERT INTO store.invoices (id, person_id, order_date, payment_date, payment_info, subtotal, shipping, total, country, address, ship_date, ship_info) VALUES (3, 6, '2019-10-02', '2019-10-02', 'Mastercard #4143625', 21.23, 0, 21.23, 'DE', NULL, NULL, NULL);
INSERT INTO store.invoices (id, person_id, order_date, payment_date, payment_info, subtotal, shipping, total, country, address, ship_date, ship_info) VALUES (4, 7, '2019-10-02', NULL, NULL, 2, 0, 2, 'CN', NULL, NULL, NULL);


ALTER TABLE store.invoices ENABLE TRIGGER ALL;

--
-- Data for Name: items; Type: TABLE DATA; Schema: store; Owner: dude
--

ALTER TABLE store.items DISABLE TRIGGER ALL;

INSERT INTO store.items (id, name, price, weight) VALUES (1, 'Smell the Factory', 21.23, NULL);
INSERT INTO store.items (id, name, price, weight) VALUES (2, 'Everlasting Gobstopper', 149.99, 0.25);
INSERT INTO store.items (id, name, price, weight) VALUES (3, 'Fizzy Lifting Drink', 5, 1);
INSERT INTO store.items (id, name, price, weight) VALUES (4, 'JPG of Mr. Wonka', 2, NULL);


ALTER TABLE store.items ENABLE TRIGGER ALL;

--
-- Data for Name: lineitems; Type: TABLE DATA; Schema: store; Owner: dude
--

ALTER TABLE store.lineitems DISABLE TRIGGER ALL;

INSERT INTO store.lineitems (id, invoice_id, item_id, quantity, price) VALUES (1, 1, 3, 3, 15);
INSERT INTO store.lineitems (id, invoice_id, item_id, quantity, price) VALUES (2, 2, 2, 10, 1499.9);
INSERT INTO store.lineitems (id, invoice_id, item_id, quantity, price) VALUES (3, 3, 1, 1, 21.23);
INSERT INTO store.lineitems (id, invoice_id, item_id, quantity, price) VALUES (4, 4, 4, 1, 2);


ALTER TABLE store.lineitems ENABLE TRIGGER ALL;

--
-- Data for Name: shipchart; Type: TABLE DATA; Schema: store; Owner: dude
--

ALTER TABLE store.shipchart DISABLE TRIGGER ALL;

INSERT INTO store.shipchart (id, country, weight, cost) VALUES (1, 'US', 0.5, 3);
INSERT INTO store.shipchart (id, country, weight, cost) VALUES (2, 'US', 1, 4);
INSERT INTO store.shipchart (id, country, weight, cost) VALUES (3, 'US', 2, 5);
INSERT INTO store.shipchart (id, country, weight, cost) VALUES (4, 'US', 3, 6);
INSERT INTO store.shipchart (id, country, weight, cost) VALUES (5, 'US', 4, 7);
INSERT INTO store.shipchart (id, country, weight, cost) VALUES (6, 'US', 999, 12);
INSERT INTO store.shipchart (id, country, weight, cost) VALUES (7, 'CA', 0.5, 5);
INSERT INTO store.shipchart (id, country, weight, cost) VALUES (8, 'CA', 1, 6);
INSERT INTO store.shipchart (id, country, weight, cost) VALUES (9, 'CA', 2, 7);
INSERT INTO store.shipchart (id, country, weight, cost) VALUES (10, 'CA', 3, 8);
INSERT INTO store.shipchart (id, country, weight, cost) VALUES (11, 'CA', 999, 13);
INSERT INTO store.shipchart (id, country, weight, cost) VALUES (12, NULL, 0.5, 7);
INSERT INTO store.shipchart (id, country, weight, cost) VALUES (13, NULL, 1, 8);
INSERT INTO store.shipchart (id, country, weight, cost) VALUES (14, NULL, 2, 9);
INSERT INTO store.shipchart (id, country, weight, cost) VALUES (15, NULL, 3, 10);
INSERT INTO store.shipchart (id, country, weight, cost) VALUES (16, NULL, 999, 14);


ALTER TABLE store.shipchart ENABLE TRIGGER ALL;

--
-- Name: invoices_id_seq; Type: SEQUENCE SET; Schema: store; Owner: dude
--

SELECT pg_catalog.setval('store.invoices_id_seq', 4, true);


--
-- Name: items_id_seq; Type: SEQUENCE SET; Schema: store; Owner: dude
--

SELECT pg_catalog.setval('store.items_id_seq', 4, true);


--
-- Name: lineitems_id_seq; Type: SEQUENCE SET; Schema: store; Owner: dude
--

SELECT pg_catalog.setval('store.lineitems_id_seq', 4, true);


--
-- Name: shipchart_id_seq; Type: SEQUENCE SET; Schema: store; Owner: dude
--

SELECT pg_catalog.setval('store.shipchart_id_seq', 16, true);


--
-- PostgreSQL database dump complete
--

