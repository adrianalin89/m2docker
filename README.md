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
### Project Structure
```
project-root/
├── bin/           # Project management scripts
├── src/           # Magento source code
├── Makefile       # CLI commands
├── docker-compose.yml
├── env.php        # Magento configuration
└── .env           # Project configuration
```
### Project Configuration
Edit the `.env` file to configure your project:
  - Set the `PROJECT_NAME` variable to your project name
  - Additional change the <b>domain</b> if it's not local hosted
  - Set <b>users</b> and <b>passwords</b> for all the services 

Comment RabbitMQ if you don't use it `docker-compose.yml` (coment the volume also)
```
# Run setup command to update the project with the new env variables
bin/setup-docker
```
### Project Initialization
Create the source folder, this is where the project files will be stored, this folder is mounted to the container so creating it is mandatory. `mkdir src`

Start project containers, first start will take a while to build the images. If you have any issues with the build process, please check the troubleshooting section.
```bash
bin/start
```
After the build process is done, you can clone your project repository into the `src` folder. Go to src `cd src` and do a clone `git clone [YOUR_PROJECT_REPOSITORY] .` Don't forget to add a dot at the end of the command to clone the repository into the current folder.

> **Note:** Restart Nginx proxy containers after project start to auto generate the SSL certificates. and for the change to take effect.
### Database Setup
You will need to have a db backeup ready at this point to import. Place the sql file in the root of this project (not in src) and run the following command (replace placeholders) to import the database. Depending on the size of the database, this process may take a while. You can remove the sql dump after the import is done.
```
bin/clinotty mysql -h <database-container-name> -u root -p'<password>' <database-name> < <file.sql>
```

### Pull Magento Dependencies
Install Magento dependencies using Composer. This will install all required packages in the `vendor` folder inside the container using the php version of the container. Make sure you have the auth.json file in the src folder containing all the composer credentials. (including magento repo)
```bash
bin/composer install
```

### Magento Configuration
1. Copy the `env.php` file from the root of this project to the `app/etc` folder in the Magento source code. Open it and add the db credentials and other configuration you see fit.
2. After adding the env for magento it's time to update the db white the new configuration. Run the following command to import the configuration.
```bash
bin/magento app:config:import
```
3. Set the domain in hosts and database. This command will update the base url in the database and the hosts file of your server. Please see the troubleshooting section if you have any issues with the setup process.
```bash
bin/setup-magento
```
4. Restart containers
```bash
bin/restart
```
5. Run Magento setup
```bash
bin/magento setup:upgrade
```

At this point you should have a working Magento 2 project running on your server. The fallowing documentation is not in a reticular order, and it's being developed as we go.

## CLI Commands
- `bin/analyse`: Run `phpstan analyse` within the container to statically analyse code, passing in directory to analyse. Ex. `bin/analyse app/code`
- `bin/bash`: Drop into the bash prompt of your Docker container. The `phpfpm` container should be mainly used to access the filesystem within Docker.
- `bin/blackfire`: Disable or enable Blackfire. Accepts argument `disable`, `enable`, or `status`. Ex. `bin/blackfire enable`
- `bin/cache-clean`: Access the [cache-clean](https://github.com/mage2tv/magento-cache-clean) CLI. Note the watcher is automatically started at startup in `bin/start`. Ex. `bin/cache-clean config full_page`
- `bin/check-dependencies`: Provides helpful recommendations for dependencies tailored to the chosen Magento version.
- `bin/cli`: Run any CLI command without going into the bash prompt. Ex. `bin/cli ls`
- `bin/clinotty`: Run any CLI command with no TTY. Ex. `bin/clinotty chmod u+x bin/magento`
- `bin/cliq`: The same as `bin/cli`, but pipes all output to `/dev/null`. Useful for a quiet CLI, or implementing long-running processes.
- `bin/composer`: Run the composer binary. Ex. `bin/composer install`
- `bin/configure-linux`: Adds the Docker container's IP address to the system's `/etc/hosts` file if it's not already present. Additionally, it prompts the user to open port 9003 for Xdebug if desired.
- `bin/copyfromcontainer`: Copy folders or files from container to host. Ex. `bin/copyfromcontainer vendor`
- `bin/copytocontainer`: Copy folders or files from host to container. Ex. `bin/copytocontainer --all`
- `bin/create-user`: Create either an admin user or customer account.
- `bin/cron`: Start or stop the cron service. Ex. `bin/cron start`
- `bin/debug-cli`: Enable Xdebug for bin/magento, with an optional argument of the IDE key. Defaults to PHPSTORM Ex. `bin/debug-cli enable PHPSTORM`
- `bin/deploy`: Runs the standard Magento deployment process commands. Pass extra locales besides `en_US` via an optional argument. Ex. `bin/deploy nl_NL`
- `bin/dev-test-run`: Facilitates running PHPUnit tests for a specified test type (e.g., integration). It expects the test type as the first argument and passes any additional arguments to PHPUnit, allowing for customization of test runs. If no test type is provided, it prompts the user to specify one before exiting.
- `bin/dev-urn-catalog-generate`: Generate URN's for PhpStorm and remap paths to local host. Restart PhpStorm after running this command.
- `bin/devconsole`: Alias for `bin/n98-magerun2 dev:console`
- `bin/docker-compose`: Support V1 (`docker-compose`) and V2 (`docker compose`) docker compose command, and use custom configuration files, such as `compose.yml` and `compose.dev.yml`
- `bin/docker-stats`: Display container name and container ID, status for CPU, memory usage(in MiB and %), and memory limit of currently-running Docker containers.
- `bin/download`: Download specific Magento version from Composer to the container, with optional arguments of the type ("community" [default], "enterprise", or "mageos") and version ([default] is defined in `bin/download`). Ex. `bin/download mageos` or `bin/download enterprise 2.4.7-p3`
- `bin/ece-patches`: Run the Cloud Patches CLI. Ex: `bin/ece-tools apply`
- `bin/fixowns`: This will fix filesystem ownerships within the container.
- `bin/fixperms`: This will fix filesystem permissions within the container.
- `bin/grunt`: Run the grunt binary. Ex. `bin/grunt exec`
- `bin/install-php-extensions`: Install PHP extension in the container. Ex. `bin/install-php-extensions sourceguardian`
- `bin/log`: Monitor the Magento log files. Pass no params to tail all files. Ex. `bin/log debug.log`
- `bin/magento`: Run the Magento CLI. Ex: `bin/magento cache:flush`
- `bin/magento-version`: Determine the Magento version installed in the current environment.
- `bin/mftf`: Run the Magento MFTF. Ex: `bin/mftf build:project`
- `bin/mysql`: Run the MySQL CLI with database config from `env/db.env`. Ex. `bin/mysql -e "EXPLAIN core_config_data"` or`bin/mysql < magento.sql`
- `bin/mysqldump`: Backup the Magento database. Ex. `bin/mysqldump > magento.sql`
- `bin/n98-magerun2`: Access the [n98-magerun2](https://github.com/netz98/n98-magerun2) CLI. Ex: `bin/n98-magerun2 dev:console`
- `bin/node`: Run the node binary. Ex. `bin/node --version`
- `bin/npm`: Run the npm binary. Ex. `bin/npm install`
- `bin/phpcbf`: Auto-fix PHP_CodeSniffer errors with Magento2 options. Ex. `bin/phpcbf <path-to-extension>`
- `bin/phpcs`: Run PHP_CodeSniffer with Magento2 options. Ex. `bin/phpcs <path-to-extension>`
- `bin/phpcs-json-report`: Run PHP_CodeSniffer with Magento2 options and save to `report.json` file. Ex. `bin/phpcs-json-report <path-to-extension>`
- `bin/pwa-studio`: (BETA) Start the PWA Studio server. Note that Chrome will throw SSL cert errors and not allow you to view the site, but Firefox will.
- `bin/redis`: Run a command from the redis container. Ex. `bin/redis redis-cli monitor`
- `bin/restart`: Stop and then start all containers.
- `bin/root`: Run any CLI command as root without going into the bash prompt. Ex `bin/root apt-get install nano`
- `bin/rootnotty`: Run any CLI command as root with no TTY. Ex `bin/rootnotty chown -R app:app /var/www/html`
- `bin/setup`: Run the Magento setup process to install Magento from the source code, with optional domain name. Defaults to `magento.test`. Ex. `bin/setup magento.test`
- `bin/setup-composer-auth`: Setup authentication credentials for Composer.
- `bin/setup-dcker` : Setup Magento project in Docker.
- `bin/setup-magento` : Setup Magento ....
- `bin/setup-grunt`: Install and configure Grunt JavaScript task runner to compile .less files
- `bin/setup-install`: Automates the installation process for a Magento instance.
- `bin/setup-integration-tests`: Script to set up integration tests.
- `bin/setup-pwa-studio`: (BETA) Install PWA Studio (requires NodeJS and Yarn to be installed on the host machine). Pass in your base site domain, otherwise the default `master-7rqtwti-mfwmkrjfqvbjk.us-4.magentosite.cloud` will be used. Ex: `bin/setup-pwa-studio magento.test`.
- `bin/setup-pwa-studio-sampledata`: This script makes it easier to install Venia sample data. Pass in your base site domain, otherwise the default `master-7rqtwti-mfwmkrjfqvbjk.us-4.magentosite.cloud` will be used. Ex: `bin/setup-pwa-studio-sampledata magento.test`.
- `bin/spx`: Disable or enable output compression to enable or disbale SPX. Accepts params `disable` (default) or `enable`. Ex. `bin/spx enable`
- `bin/start`: Start all containers, good practice to use this instead of `docker-compose up -d`, as it may contain additional helpers.
- `bin/status`: Check the container status.
- `bin/stop`: Stop all project containers.
- `bin/test/unit`: Run unit tests for a specific path. Ex. `bin/test/unit my-dir`
- `bin/test/unit-coverage`: Generate unit tests coverage reports, saved to the folder `dev/tests/unit/report`. Ex. `bin/test/unit-coverage my-dir`
- `bin/test/unit-xdebug`: Run unit tests with Xdebug. Ex. `bin/test/unit-xdebug my-dir`
- `bin/update`: Update your project to the most recent version of `docker-magento`.
- `bin/xdebug`: Disable or enable Xdebug. Accepts argument `disable`, `enable`, or `status`. Ex. `bin/xdebug enable`

> [!IMPORTANT]
>
> #### CLI commands
>
> Not all commands are tested and may require adjustments for your project, the repo is still in development and will be updated with more features and commands.


# TO DO

### Multiple Domain Configuration
- Current limitation: `bin/setup-magento` supports only a single domain
- Manual adjustments needed for multiple domain routing


### Setup new empty magento project
### add dummy data
### how to use the update command
### create chat ores for grunt, pcx, xdebug, testing,... and all that stuff
### Troubleshooting
- Verify all container names match in `.env` and configuration files
- Check Docker logs for any startup or configuration issues
- Ensure all required environment variables are set
- `bin/setup-magento` prompts the fallowing error:`There are no commands defined in the "config" namespace.` you need to run `bin/magento set:up` to see what the issue is. After resolving the issue you will have to manually change the base url in the database.
- `bin/magento set:up` prompts the fallowing error:'Could not validate a connection to Elasticsearch. No alive nodes found in your cluster'. It may mean the magento version is not compatible with opensearch and you need to change to elasticsearch. You can do this by changing the network in the `compose.yaml`  from `open-search-network` to `elastic-search-network` (also go to the env.php file and under elasticsearch change the host to `elastisearch`) and then run `bin/restart` and try again.


### Contributions
Want to make this project better? Feel free to submit a PR or open an issue. We promise not to ignore it (too much).