-- Kari Ajuda Initial Database Setup

-- Create database if not exists
SELECT 'CREATE DATABASE kariajuda'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'kariajuda')\gexec

-- Connect to kariajuda database
\c kariajuda;

-- Create extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Set timezone
SET timezone = 'America/Sao_Paulo';

-- Create initial schema version table for migrations
CREATE TABLE IF NOT EXISTS alembic_version (
    version_num VARCHAR(32) NOT NULL,
    CONSTRAINT alembic_version_pkc PRIMARY KEY (version_num)
);

-- Grant permissions
GRANT ALL PRIVILEGES ON DATABASE kariajuda TO kariajuda;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO kariajuda;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO kariajuda;