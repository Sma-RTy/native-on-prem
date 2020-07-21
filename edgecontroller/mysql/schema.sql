-- SPDX-License-Identifier: Apache-2.0
-- Copyright (c) 2019-2020 Intel Corporation

DROP DATABASE IF EXISTS controller_ce;

CREATE DATABASE controller_ce;

USE controller_ce

-- -------------
-- Entity tables
-- -------------

CREATE TABLE nodes (
    id VARCHAR(36) GENERATED ALWAYS AS (entity->>'$.id') STORED UNIQUE KEY,
    -- TODO add UNIQUE KEY on serial - will require refactoring the tests
    serial VARCHAR(36) GENERATED ALWAYS AS (entity->>'$.serial') STORED,
    entity JSON
);

-- the grpc target for a node may or may not exist yet, so we specify ON DELETE CASCADE to handle deletion without
-- requiring extra logic in the code
CREATE TABLE node_grpc_targets (
    id VARCHAR(36) GENERATED ALWAYS AS (entity->>'$.id') STORED UNIQUE KEY,
    node_id VARCHAR(36) GENERATED ALWAYS AS (entity->>'$.node_id') STORED,
    grpc_target VARCHAR(47) GENERATED ALWAYS AS (entity->>'$.grpc_target') STORED,
    entity JSON,
    FOREIGN KEY (node_id) REFERENCES nodes(id) ON DELETE CASCADE,
    UNIQUE KEY (node_id),
    UNIQUE KEY (grpc_target)
);

CREATE TABLE nodes_nfd_features (
    id VARCHAR(36) GENERATED ALWAYS AS (entity->>'$.id') STORED UNIQUE KEY,
    node_id VARCHAR(36) GENERATED ALWAYS AS (entity->>'$.node_id') STORED,
    nfd_id VARCHAR(36) GENERATED ALWAYS AS (entity->>'$.nfd_id') STORED,
    entity JSON,
    FOREIGN KEY (node_id) REFERENCES nodes(id) ON DELETE CASCADE,
    UNIQUE KEY (node_id, nfd_id)
);

CREATE TABLE apps (
    id VARCHAR(36) GENERATED ALWAYS AS (entity->>'$.id') STORED UNIQUE KEY,
    type VARCHAR(36) GENERATED ALWAYS AS (entity->>'$.type') STORED,
    entity JSON
);

CREATE TABLE traffic_policies (
    id VARCHAR(36) GENERATED ALWAYS AS (entity->>'$.id') STORED UNIQUE KEY,
    entity JSON
);

CREATE TABLE dns_configs (
    id VARCHAR(36) GENERATED ALWAYS AS (entity->>'$.id') STORED UNIQUE KEY,
    entity JSON
);

CREATE TABLE credentials (
    id VARCHAR(36) GENERATED ALWAYS AS (entity->>'$.id') STORED UNIQUE KEY,
    entity JSON
);

-- -------------------
-- Primary join tables
-- -------------------

-- These tables join two entity tables.

-- dns_configs x apps
CREATE TABLE dns_configs_app_aliases (
    id VARCHAR(36) GENERATED ALWAYS AS (entity->>'$.id') STORED UNIQUE KEY,
    dns_config_id  VARCHAR(36) GENERATED ALWAYS AS
        (entity->>'$.dns_config_id') STORED,
    app_id  VARCHAR(36) GENERATED ALWAYS AS (entity->>'$.app_id') STORED,
    entity JSON,
    FOREIGN KEY (dns_config_id) REFERENCES dns_configs(id),
    FOREIGN KEY (app_id) REFERENCES apps(id),
    UNIQUE KEY (dns_config_id, app_id)
);

-- nodes x apps
CREATE TABLE nodes_apps (
    id VARCHAR(36) GENERATED ALWAYS AS (entity->>'$.id') STORED UNIQUE KEY,
    node_id VARCHAR(36) GENERATED ALWAYS AS (entity->>'$.node_id') STORED,
    app_id VARCHAR(36) GENERATED ALWAYS AS (entity->>'$.app_id') STORED,
    entity JSON,
    FOREIGN KEY (node_id) REFERENCES nodes(id),
    FOREIGN KEY (app_id) REFERENCES apps(id),
    UNIQUE KEY (node_id, app_id)
);

-- nodes x dns_configs
CREATE TABLE nodes_dns_configs (
    id VARCHAR(36) GENERATED ALWAYS AS (entity->>'$.id') STORED UNIQUE KEY,
    node_id VARCHAR(36) GENERATED ALWAYS AS (entity->>'$.node_id') STORED UNIQUE KEY,
    dns_config_id VARCHAR(36) GENERATED ALWAYS AS
        (entity->>'$.dns_config_id') STORED,
    entity JSON,
    FOREIGN KEY (node_id) REFERENCES nodes(id),
    FOREIGN KEY (dns_config_id) REFERENCES dns_configs(id)
);

-- nodes (network_interfaces) x traffic_policies
CREATE TABLE nodes_network_interfaces_traffic_policies (
    id VARCHAR(36) GENERATED ALWAYS AS (entity->>'$.id') STORED UNIQUE KEY,
    node_id VARCHAR(36) GENERATED ALWAYS AS (entity->>'$.node_id') STORED,
    network_interface_id VARCHAR(36) GENERATED ALWAYS AS
        (entity->>'$.network_interface_id') STORED,
    traffic_policy_id VARCHAR(36) GENERATED ALWAYS AS
        (entity->>'$.traffic_policy_id') STORED,
    entity JSON,
    FOREIGN KEY (node_id) REFERENCES nodes(id),
    FOREIGN KEY (traffic_policy_id) REFERENCES traffic_policies(id),
    UNIQUE KEY (node_id, network_interface_id)
);

-- ---------------------
-- Secondary join tables
-- ---------------------

-- These tables join an entity table to a primary join table.

-- nodes_apps x traffic_policies
CREATE TABLE nodes_apps_traffic_policies (
    id VARCHAR(36) GENERATED ALWAYS AS (entity->>'$.id') STORED UNIQUE KEY,
    nodes_apps_id VARCHAR(36) GENERATED ALWAYS AS
        (entity->>'$.nodes_apps_id') STORED,
    traffic_policy_id VARCHAR(36) GENERATED ALWAYS AS
        (entity->>'$.traffic_policy_id') STORED,
    entity JSON,
    FOREIGN KEY (nodes_apps_id) REFERENCES nodes_apps(id),
    FOREIGN KEY (traffic_policy_id) REFERENCES traffic_policies(id),
    UNIQUE KEY (nodes_apps_id, traffic_policy_id)
);
