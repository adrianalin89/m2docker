# Magento Docker Project Setup Guide

## Prerequisites
- [Docker Compose](https://docs.docker.com/engine/install/ubuntu/)
- Git
- [NGINX PROXY](https://github.com/adrianalin89/nginx-proxy) need's to be setup

## Setup Instructions

### 1. Project Configuration
- Edit the `.env` file
- Set the `PROJECT_NAME` variable to your project name

### 2. Initial Setup
```bash
# Make setup script executable
chmod +x bin/setup-docker

# Run setup command
bin/setup-docker
```

> **Note:** Restart Nginx proxy containers after project start to generate SSL certificates.

### 3. Project Structure
```
project-root/
├── bin/           # Project management scripts
├── src/           # Magento source code
└── .env           # Project configuration
```

### 4. Project Initialization
```bash
# Create source folder
mkdir src

# Start project containers
bin/start

# Navigate to source and pull project files
cd src
git clone [YOUR_PROJECT_REPOSITORY]
```

### 5. Database Setup
```bash
# Import database (replace placeholders)
bin/clinotty mysql -h <database-container-name> -u root -p'<password>' <database-name> < <file.sql>

# Install dependencies
bin/composer install
```

### 6. Magento Configuration
1. Create `app/etc/env.php`
    - Use Docker container names as hosts
    - Add credentials from `.env`

2. Update database configuration
```bash
# Import configuration
bin/magento app:config:import

# Setup domain in hosts and database
bin/setup-magento

# Restart containers
bin/restart

# Run Magento setup
bin/magento setup:upgrade
```

## Additional Management

### Script Permissions
```bash
# Make all scripts in bin/ executable
sudo chmod +x bin/*
```

### Multiple Domain Configuration
- Current limitation: `bin/setup-magento` supports only a single domain
- Manual adjustments needed for multiple domain routing

### Ownership Management
- Use `bin/fixowns` to set proper file ownership
- Test this command to ensure correct permissions

## Troubleshooting
- Verify all container names match in `.env` and configuration files
- Check Docker logs for any startup or configuration issues
- Ensure all required environment variables are set

## Best Practices
- Always backup your database before major changes
- Use version control for your `.env` files (exclude sensitive data)
- Regularly update Docker images and Magento dependencies