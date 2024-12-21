# Magento 2 Docker working on NGINX PROXY

<img src="https://img.shields.io/badge/magento-2.X-brightgreen.svg?logo=magento&longCache=true" alt="Supported Magento Versions" />[![Test](https://github.com/nginx-proxy/nginx-proxy/actions/workflows/test.yml/badge.svg)](https://github.com/nginx-proxy/nginx-proxy/actions/workflows/test.yml)
<img src="https://img.shields.io/badge/maintained%3F-yes-brightgreen.svg" alt="Maintained - Yes" />

This is a modify version of the original dcoker magento [markshust/docker-magento]() project. 
The main difference is that this project is using a custom [NGINX PROXY](https://github.com/adrianalin89/nginx-proxy) 
to have more then one project running on the same server. 
A lot of core features of the original repo are modify so please dont just copy cod from one place to the other and hope it's works as expected.
There will be a lot of changes to the way this project is setup and how it works. So to not get confused please read the whole documentation.

The main goal of this project is to have a simple way to setup a magento 2 project on a server with multiple projects running on the same server.
The projects containers consist of:
   - NGINX
   - PHP
   - MySQL
   - Redis

## Prerequisites
- [Docker Compose](https://docs.docker.com/engine/install/ubuntu/)
- [NGINX PROXY](https://github.com/adrianalin89/nginx-proxy) need's to be setup and running

## Setup Instructions

### Project Configuration
- Edit the `.env` file
  - Set the `PROJECT_NAME` variable to your project name
  - Additional change the domain if it's not local hosted
  - Please also set users and passwords for the database and the magento admin user
- Update the project with the new env variables that you have set

   ```bash
   # Run setup command to update the project with the new env variables
   bin/setup-docker
   ```

> **Note:** Restart Nginx proxy containers after project start to auto generate the SSL certificates. and for the change to take effect.

### Project Structure
```
project-root/
├── bin/           # Project management scripts
├── src/           # Magento source code
├── Makefile       # CLI commands
├── docker-compose.yml
└── .env           # Project configuration
```

### Project Initialization
```bash
# Create source folder
mkdir src

# Start project containers
bin/start

# Navigate to source and pull project files
cd src
git clone [YOUR_PROJECT_REPOSITORY]
```

### Database Setup
```bash
# Import database (replace placeholders)
bin/clinotty mysql -h <database-container-name> -u root -p'<password>' <database-name> < <file.sql>
```

### Pull Magento Dependencies
```bash
# Install dependencies in vendor
bin/composer install
```

### Magento Configuration
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

At this point you should have a working Magento 2 project running on your server. The fallowing documentation is not in a reticular order, and it's being developed as we go.

# TO DO
> [!IMPORTANT]
>
> #### CLI commands
>
> Not all commands are tested and may require adjustments for your project, the repo is still in development and will be updated with more features and commands.


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

## Setup new empty magento project
### add dummy data

## CLI Commands

### how to use the update command
### create chat ores for grunt, pcx, xdebug, testing,... and all that stuff
### Troubleshooting


### Contributions
Want to make this project better? Feel free to submit a PR or open an issue. We promise not to ignore it (too much).

### Contact Information
If you're stuck or have questions:
- Option 1: Read the docs until you question your life choices.
- Option 2: Open an issue and pray someone answers before the next millennium.
- Option 3: Offer cookies or coffee, and maybe, just maybe, someone will help.
