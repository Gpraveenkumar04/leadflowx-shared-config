-- Create the raw_leads table
CREATE TABLE raw_leads (
    id SERIAL PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    name VARCHAR(255) NOT NULL,
    company VARCHAR(255) NOT NULL,
    website VARCHAR(255) NOT NULL,
    phone VARCHAR(50) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    correlation_id VARCHAR(255) NOT NULL
);

-- Create the dlq_leads table
CREATE TABLE dlq_leads (
    id SERIAL PRIMARY KEY,
    email VARCHAR(255) NOT NULL,
    name VARCHAR(255),
    company VARCHAR(255) NOT NULL,
    website VARCHAR(255) NOT NULL,
    phone VARCHAR(50) NOT NULL,
    correlation_id VARCHAR(255) NOT NULL,
    error TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL
);

-- Create the config table
CREATE TABLE config (
    id SERIAL PRIMARY KEY,
    key VARCHAR(255) UNIQUE NOT NULL,
    value TEXT
);

-- Create the scoring_jobs table
CREATE TABLE scoring_jobs (
    id SERIAL PRIMARY KEY,
    job_date DATE NOT NULL,
    status VARCHAR(50) NOT NULL,
    leads_processed INTEGER DEFAULT 0,
    start_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    end_time TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL
);
