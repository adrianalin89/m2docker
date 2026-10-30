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
   - Valkey(Redis)

## Prerequisites
- [Docker Compose](https://docs.docker.com/engine/install/ubuntu/)
- [NGINX PROXY](https://github.com/adrianalin89/nginx-proxy) project need's to be setup and running

## Setup Instructions
### Project Structure
```
project-root/
├── bin/                      # Project management scripts (bin/magento, bin/composer, bin/deploy, ...)
├── lib/                      # Shared script helpers and the requirements table (versions.tsv)
├── images/                   # Docker build contexts and configs (nginx, php/<version>, frankenphp)
├── scripts/                  # Optional scripts, ex. db-backup.sh
├── src/                      # Magento / Mage-OS source code (its own git repository)
├── compose.yaml              # Project services: nginx, php, db, redis
├── compose.frankenphp.yaml   # FrankenPHP variant (WEB_SERVER=frankenphp)
├── env.php                   # Magento app/etc/env.php template
├── .gitignore.sample_magento # copied to src/.gitignore by bin/download
├── bitbucket-pipelines.yml.sample
├── Makefile                  # CLI commands
└── .env                      # Project configuration (from .env.sample)
```
### Project Configuration
Copy the `.env.sample` to `.env` and edit the file:
  - Set the `PROJECT_NAME` variable to your project name
  - Additional change the <b>domain</b> if it's not local hosted
  - Set <b>users</b> and <b>passwords</b> for all the services

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
If this is a new clean magento installation continue the steps from "Setup new empty magento project".

After the build process is done, you can clone your project repository into the `src` folder. Go to src `cd src` and do a clone `git clone [YOUR_PROJECT_REPOSITORY] .` Don't forget to add a dot at the end of the command to clone the repository into the current folder.

> **Note:** Restart Nginx proxy containers after project start to auto generate the SSL certificates. and for the change to take effect.
### Database Setup
You will need to have a db backeup ready at this point to import. Place the sql file in the root of this project (not in src) and run the following command (replace placeholders) to import the database. Depending on the size of the database, this process may take a while. You can remove the sql dump after the import is done.
```
bin/clinotty mysql -h {{project_name}}-db -u root -p'<password>' <database-name> < <file.sql>
```

### Pull Magento Dependencies
Install Magento dependencies using Composer. This will install all required packages in the `vendor` folder inside the container using the php version of the container. Make sure you have the auth.json file in the src folder containing all the composer credentials. (including magento repo)
```bash
bin/composer install
```
Use `bin\setup-rabbitmq` to setup the project in rabbitmq service.

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

### Setup new empty magento project
After starting the container and editing the `.env` file you will have to download the version of Magento that you want to use. `src/` must be empty.

```
bin/download                      # latest Mage-OS release (3.0 or newer), default
bin/download mageos 3.5.0         # specific Mage-OS version
bin/download community            # Magento Open Source 2.4.9 (needs repo.magento.com keys)
bin/download enterprise 2.4.8-p3  # Adobe Commerce
```
Use `bin\setup-rabbitmq` to setup the project in rabbitmq service.
Use `bin/setup-install` to automatically install it using the information from the env file. This will seed the DB and generate the env.php file.

Use `bin/setup-magento` to add the new domain to hosts file.

Restart the container `bin/restart` and you shod be good to go `bin/magento set:up`
#

At this point you should have a working Magento 2 project running on your server. The fallowing documentation is not in a reticular order, and it's being developed as we go.

## CLI Commands
- `bin/analyse`: Run `phpstan analyse` within the container to statically analyse code, passing in directory to analyse. Ex. `bin/analyse app/code`
- `bin/bash`: Drop into the bash prompt of the `{{project_name}}-php` container.
- `bin/cache-clean`: Access the [cache-clean](https://github.com/mage2tv/magento-cache-clean) CLI. Note the watcher is automatically started at startup in `bin/start`. Ex. `bin/cache-clean config full_page`
- `bin/check-dependencies`: Compare this project (version from `src/composer.lock`) with the official requirements: PHP, Composer, MariaDB, cache image and the shared OpenSearch / RabbitMQ. Ex. `bin/check-dependencies`, `bin/check-dependencies mageos 3.6.0`, `bin/check-dependencies --list`
- `bin/cli`: Run any CLI command without going into the bash prompt. Ex. `bin/cli ls`
- `bin/clinotty`: Run any CLI command with no TTY. Ex. `bin/clinotty chmod u+x bin/magento`
- `bin/cliq`: The same as `bin/cli`, but pipes all output to `/dev/null`. Useful for a quiet CLI, or implementing long-running processes.
- `bin/composer`: Run the composer binary. Ex. `bin/composer install`
- `bin/configure-linux`: Adds the Docker container's IP address to the system's `/etc/hosts` file if it's not already present. Additionally, it prompts the user to open port 9003 for Xdebug if desired.
- `bin/create-user`: Create either an admin user or customer account.
- `bin/cron`: Start or stop the cron service. Ex. `bin/cron start`
- `bin/debug-cli`: Enable Xdebug for bin/magento, with an optional argument of the IDE key. Defaults to PHPSTORM Ex. `bin/debug-cli enable PHPSTORM`
- `bin/deploy`: In place deployment of `src/` configured by the `DEPLOY_*` variables in `.env` (git pull of `DEPLOY_BRANCH`, maintenance, composer, di:compile, Tailwind, setup:upgrade, static content). Extra locales can be passed as arguments, `--no-git` skips the pull. Ex. `bin/deploy ro_RO`
- `bin/health-check`: Read only post deploy check: maintenance off, `setup:db:status`, storefront answers 200, invalid indexers, cron running. Exit code 1 on errors.
- `bin/pipeline`: Entry point for CI deployments, runs `bin/deploy` or `bin/deploy-releases` depending on `DEPLOY_TYPE`, then `bin/health-check`. Ex. `bin/pipeline`, `bin/pipeline --dry-run`, `bin/pipeline hotfix-branch`
- `bin/dev-test-run`: Facilitates running PHPUnit tests for a specified test type (e.g., integration). It expects the test type as the first argument and passes any additional arguments to PHPUnit, allowing for customization of test runs. If no test type is provided, it prompts the user to specify one before exiting.
- `bin/dev-urn-catalog-generate`: Generate URN's for PhpStorm and remap paths to local host. Restart PhpStorm after running this command.
- `bin/devconsole`: Alias for `bin/n98-magerun2 dev:console`
- `bin/docker-compose`: Support V1 (`docker-compose`) and V2 (`docker compose`) docker compose command with `compose.yaml` (+ `compose.frankenphp.yaml` when `WEB_SERVER=frankenphp`).
- `bin/docker-stats`: Display container name and container ID, status for CPU, memory usage(in MiB and %), and memory limit of currently-running Docker containers.
- `bin/download`: Download Mage-OS or Magento into `src/` with Composer (and copy `.gitignore.sample_magento` to `src/.gitignore`), with optional arguments of the edition ("mageos" [default], "community" or "enterprise") and version (Mage-OS defaults to the latest 3.x+ release, Magento to 2.4.9). Ex. `bin/download` or `bin/download enterprise 2.4.8-p3`. See `bin/download --help`.
- `bin/fixowns`: This will fix filesystem ownerships within the container.
- `bin/fixperms`: This will fix filesystem permissions within the container.
- `bin/grunt`: Run the grunt binary. Ex. `bin/grunt exec`
- `bin/install-php-extensions`: Install PHP extension in the container. Ex. `bin/install-php-extensions sourceguardian`
- `bin/log`: Monitor the Magento log files. Pass no params to tail all files. Ex. `bin/log debug.log`
- `bin/magento`: Run the Magento CLI. Ex: `bin/magento cache:flush`
- `bin/magento-version`: Determine the Magento version installed in the current environment.
- `bin/mysql`: Run the MySQL CLI with database config from `env/db.env`. Ex. `bin/mysql -e "EXPLAIN core_config_data"` or`bin/mysql < magento.sql`
- `bin/mysqldump`: Backup the Magento database. Ex. `bin/mysqldump > magento.sql`
- `bin/n98-magerun2`: Access the [n98-magerun2](https://github.com/netz98/n98-magerun2) CLI. Ex: `bin/n98-magerun2 dev:console`
- `bin/node`: Run the node binary. Ex. `bin/node --version`
- `bin/npm`: Run the npm binary. Ex. `bin/npm install`
- `bin/phpcbf`: Auto-fix PHP_CodeSniffer errors with Magento2 options. Ex. `bin/phpcbf <path-to-extension>`
- `bin/phpcs`: Run PHP_CodeSniffer with Magento2 options. Ex. `bin/phpcs <path-to-extension>`
- `bin/phpcs-json-report`: Run PHP_CodeSniffer with Magento2 options and save to `report.json` file. Ex. `bin/phpcs-json-report <path-to-extension>`
- `bin/redis`: Run a command from the redis container. Ex. `bin/redis redis-cli monitor`
- `bin/restart`: Stop and then start all containers.
- `bin/root`: Run any CLI command as root without going into the bash prompt. Ex `bin/root apt-get install nano`
- `bin/rootnotty`: Run any CLI command as root with no TTY. Ex `bin/rootnotty chown -R www-data:www-data /var/www/src/var`
- `bin/setup-composer-auth`: Setup authentication credentials for Composer.
- `bin/setup-docker`: Replace the `{{project_name}}` placeholder in the boilerplate files with `PROJECT_NAME` from `.env`. Run it once, before `src/` exists.
- `bin/setup-magento`: Add `DOMAIN_HOSTS` to `/etc/hosts` and set the Magento base URLs to `https://DOMAIN_HOSTS/`.
- `bin/setup-grunt`: Install and configure Grunt JavaScript task runner to compile .less files
- `bin/setup-ecomscan`: Install the eComscan security scanner in the php container (daily scan from cron at 02:00, see `ECOMSCAN_*` in `.env`).
- `bin/setup-rabbitmq`: Create this project's vhost and user (`RABBITMQ_DEFAULT_VHOST` / `RABBITMQ_DEFAULT_USER` from `.env`) in the shared RabbitMQ.
- `bin/setup-install`: Automates the installation process for a Magento instance.
- `bin/setup-integration-tests`: Script to set up integration tests.
- `bin/start`: Start all containers, good practice to use this instead of `docker-compose up -d`, as it may contain additional helpers.
- `bin/status`: Check the container status.
- `bin/stop`: Stop all project containers.
- `bin/tailwind`: Run npm in every Hyvä theme with `web/tailwind/package.json`. Ex. `bin/tailwind` (build), `bin/tailwind run watch`, `bin/tailwind install`
- `bin/test/unit`: Run unit tests for a specific path. Ex. `bin/test/unit my-dir`
- `bin/test/unit-coverage`: Generate unit tests coverage reports, saved to the folder `dev/tests/unit/report`. Ex. `bin/test/unit-coverage my-dir`
- `bin/test/unit-xdebug`: Run unit tests with Xdebug. Ex. `bin/test/unit-xdebug my-dir`
- `bin/update`: Update the boilerplate files of this project from `adrianalin89/m2docker` master, with `--dry-run` / `--diff` and confirmation. See "Updating the boilerplate".
- `bin/xdebug`: Disable or enable Xdebug. Accepts argument `disable`, `enable`, or `status`. Ex. `bin/xdebug enable`
- `bin/migrate-to-releases`: Migrate folder structure for 0DownTime Deploy.
- `bin/deploy-releases`: Zero downtime deployment of `DEPLOY_BRANCH` into a new `releases/` folder, switched atomically when ready (keeps `DEPLOY_KEEP_RELEASES`). If the new release changes a file that the nginx container mounts from the project (ex. a project nginx config in `src/` through `compose.override.yaml`), nginx is restarted after the switch, the only moment with a few seconds of downtime; otherwise it keeps serving without a restart.
- `bin/rollback`: Roll back to a previous release.

> [!IMPORTANT]
>
> #### CLI commands
>
> Not all commands are tested and may require adjustments for your project, the repo is still in development and will be updated with more features and commands.


Open points are tracked in [TODO.md](TODO.md).

### SSL certificates
TLS is terminated by [nginx-proxy](https://github.com/adrianalin89/nginx-proxy), the project containers only speak HTTP. The certificate type is chosen in the nginx-proxy `.env` with `COMPOSE_PROFILES`; this project only declares its domains (`DOMAIN_HOSTS`, `DOMAIN_EMAIL`), which become `VIRTUAL_HOST`, `SELF_SIGNED_HOST` and `LETSENCRYPT_HOST` / `LETSENCRYPT_EMAIL` in `compose.yaml`.

- **Local, self-signed** (`COMPOSE_PROFILES=self-signed`): a certificate signed by a local CA is generated for every domain when the project starts. Trust the CA once so the browser doesn't warn: import `nginx-proxy/certs/nginx-proxy-ca.crt` in the system store (Arch / CachyOS: `sudo trust anchor certs/nginx-proxy-ca.crt`, Debian / Ubuntu: copy it to `/usr/local/share/ca-certificates/nginx-proxy-ca.crt` and run `sudo update-ca-certificates`) and in Firefox (Settings > Certificates > Import, "trust this CA to identify websites").
- **Server, Let's Encrypt** (`COMPOSE_PROFILES=acme`): the domains must point (DNS A / AAAA) to the server and ports 80 / 443 must be reachable; `DOMAIN_EMAIL` must be a real address (expiry notices). The certificate is requested when the project starts and renewed automatically.
- **Own certificate from the client** (also wildcard): nginx-proxy only reads certificates from its own `certs/` folder, so the files always go there, even if the project keeps a copy of the originals (keep them out of git):
  1. Copy them to `nginx-proxy/certs/` named after the domain: `shop.client.com.crt` (the certificate followed by the intermediate certificates, full chain) and `shop.client.com.key`. A wildcard certificate is named after its base domain, ex. `client.com.crt` / `client.com.key`, and is used for `www.client.com`, `shop.client.com`, ... when no exact file exists. Any other file name works with `CERT_NAME` (below).
  2. Stop the companions from generating / overwriting a certificate for these domains, in `compose.override.yaml` of the project:
     ```yaml
     services:
       {{project_name}}-nginx:      # {{project_name}}-php when WEB_SERVER=frankenphp
         environment:
           - LETSENCRYPT_HOST=
           - SELF_SIGNED_HOST=
           #- CERT_NAME=client-wildcard   # uses certs/client-wildcard.crt / .key
     ```
  3. `bin/restart` the project (nginx-proxy regenerates its configuration when the container starts) and check the CERT column of `bin/sites` in nginx-proxy.

### Updating the boilerplate (bin/update)
`bin/update` brings the infrastructure files of a project (`bin/`, `lib/`, `images/`, `compose*.yaml`, `Makefile`, samples, ...) to the latest m2docker `master`:
```
bin/update --dry-run   # list what would be added, changed and removed
bin/update --diff      # same, with the differences of the changed files
bin/update             # apply, after confirmation (twice: changed files, then removed files)
```
- The `{{project_name}}` placeholder is replaced automatically, the project keeps working without `bin/setup-docker`.
- Never touched: `.env`, `src/`, `releases/`, `shared/`, `current`, `compose.override.yaml` and your own files in the project root.
- Files removed from the boilerplate are deleted only from `bin/`, `lib/`, `images/` (and old root files like `other.yaml`), after confirmation.
- Project specific Docker changes (extra service, other image, environment) go in `compose.override.yaml`: `bin/docker-compose` loads it last, so it survives every update.
- After an update that changed `images/`, rebuild: `bin/docker-compose build` then `bin/restart`. Compare with the new `.env.sample` for new variables.

### Deployment / Bitbucket pipelines
Every server has its own `.env`, so the same project can deploy `stage` on staging and `master` on production:
```
DEPLOY_TYPE=simple          # simple (bin/deploy) or releases (bin/deploy-releases, run bin/migrate-to-releases once first)
DEPLOY_BRANCH=stage         # branch deployed on this server
DEPLOY_LOCALES="en_US ro_RO"
DEPLOY_MAINTENANCE=1
DEPLOY_COMPOSER_ARGS=       # ex. --no-dev --optimize-autoloader
DEPLOY_TAILWIND=1           # npm ci + build-prod for every Hyvä theme
DEPLOY_KEEP_RELEASES=3
```
The pipeline in the project repository (`src/bitbucket-pipelines.yml`, start from `bitbucket-pipelines.yml.sample`: `stage` deploys automatically, `master` waits for a manual Run, plus custom pipelines to redeploy) only runs `bin/pipeline` on the server; its output (each numbered step with its duration) is shown in Bitbucket and a failed step fails the pipeline:
```yaml
pipelines:
  branches:
    stage:
      - step:
          name: Deploy to staging
          deployment: Staging
          script:
            - pipe: atlassian/ssh-run:0.8.1
              variables:
                SSH_USER: 'roweb'
                SERVER: '<server>'
                SSH_KEY: $SSH_PRIVATE_KEY
                COMMAND: '/home/roweb/docker/<project>/bin/pipeline'
```
- The scripts don't need a TTY, so they work with the `ssh-run` pipe and with `ssh` without `-tt`.
- `bin/deploy` refuses to pull when `src/` has uncommitted changes (checked before maintenance mode). If a later step fails, maintenance mode stays on so a half deployed shop is never served.
- Run `bin/pipeline --dry-run` on the server to check the settings without deploying.

### FrankenPHP (optional web server)
Instead of the `nginx` + `php-fpm` containers, a project can run on [FrankenPHP](https://frankenphp.dev/) (Caddy + PHP 8.5 in one container, classic mode).
Set it in `.env` before the first `bin/start`:
```
WEB_SERVER=frankenphp
```
- `bin/docker-compose` then also loads `compose.frankenphp.yaml`: the `{{project_name}}-nginx` container is disabled and `{{project_name}}-php` is built from `images/frankenphp/8.5` and routed by nginx-proxy on port `8080`. `PHP_VERSION` is ignored in this mode.
- The container keeps the `{{project_name}}-php` name, so all `bin/*` commands work the same.
- Web server rules live in `images/frankenphp/8.5/conf/Caddyfile` (mounted, `bin/restart` after editing). Only Magento's entry points (`index.php`, `get.php`, `static.php`, `health_check.php`, `errors/*.php`) can be executed.
- When switching an existing project run `bin/stop` first, otherwise the old nginx container keeps running and nginx-proxy routes to both.
- Worker mode is not enabled: Magento keeps state between requests and leaks it in worker mode.

### Multiple Domain Configuration
- Current limitation: `bin/setup-magento` supports only a single domain
- Manual adjustments needed for multiple domain routing
Use a single domain to instal it and after that update the `.env` file `DOMAIN_HOSTS` add multiple domains separated by comma `,`.

### HTPASSWD project
Basic auth on the storefront (staging), switched by `HTPASSWD` in `.env`:
```
bin/setup-htpasswd                  # user roweb / roweb321, HTPASSWD=on, recreates nginx
bin/setup-htpasswd <user> <pass>    # another user (replaces the file)
bin/setup-htpasswd --off            # HTPASSWD=off (the file is kept)
```
- Users live in the project root file `.htpasswd` (outside the web root, never touched by `bin/update`);
  nginx includes `images/nginx/auth-on.conf` or `auth-off.conf` through the compose volume
  `auth-${HTPASSWD:-off}.conf`, so `default.conf` / `compose.yaml` need no editing.
- `bin/health-check` accepts the anonymous 401 when `HTPASSWD=on`.
- Older projects with `images/nginx/.htpasswd` and hand-edited `default.conf` / `compose.yaml`: run
  `bin/update`, then `bin/setup-htpasswd` (moves the old file to the root).
- nginx only; the FrankenPHP variant has no basic auth switch.

### add dummy data
`` bin/magento sampledata:deploy`` to add default magento dummy data and then run `bin/magento setup:upgrade` to install it.
### Troubleshooting
- Verify all container names match in `.env` and configuration files
- Check Docker logs for any startup or configuration issues
- Ensure all required environment variables are set
- `bin/setup-magento` prompts the fallowing error:`There are no commands defined in the "config" namespace.` you need to run `bin/magento set:up` to see what the issue is. After resolving the issue you will have to manually change the base url in the database.
- `bin/magento set:up` prompts 'Could not validate a connection to Elasticsearch. No alive nodes found in your cluster': check that the shared `opensearch` container of nginx-proxy is running and that the search host is `opensearch` (port 9200). The shared OpenSearch is 3.x: Magento < 2.4.8-p5 and Mage-OS 2.x officially need 2.19, run `bin/check-dependencies` to compare.
- if bin/magento-setup does not change teh base urls you should do this manually in the db by phpmyadmin
- if using Hyva theme for magento and the Hyva css files are not loaded properly run `rm -rf pub/static/frontend/*` and refresh the page (once or twice)

### Caching

For an improved developer experience, caches are automatically refreshed when related files are updated, courtesy of [cache-clean](https://github.com/mage2tv/magento-cache-clean). This means you can keep all of the standard Magento caches enabled, and this script will only clear the specific caches needed, and only when necessary.

To disable this functionality, comment out the last line (`bin/cache-clean --watch`) in the `bin/start` file.

### Redis

Redis (Valkey, container `{{project_name}}-redis`) is the default cache and session storage engine, configured automatically by `bin/setup-install` on new installs and in the `env.php` template.

Use the following lines to enable Redis on existing installs:

**Enable for Cache:**

`bin/magento setup:config:set --cache-backend=redis --cache-backend-redis-server={{project_name}}-redis --cache-backend-redis-db=0`

**Enable for Full Page Cache:**

`bin/magento setup:config:set --page-cache=redis --page-cache-redis-server={{project_name}}-redis --page-cache-redis-db=1`

**Enable for Session:**

`bin/magento setup:config:set --session-save=redis --session-save-redis-host={{project_name}}-redis --session-save-redis-log-level=4 --session-save-redis-db=2`

You may also monitor Redis by running: `bin/redis redis-cli monitor`

For more information about Redis usage with Magento, <a href="https://devdocs.magento.com/guides/v2.4/config-guide/redis/redis-session.html" target="_blank">see the DevDocs</a>.


### Xdebug & VS Code

Install and enable the PHP Debug extension from the [Visual Studio Marketplace](https://marketplace.visualstudio.com/items?itemName=felixfbecker.php-debug).

Otherwise, this project now automatically sets up Xdebug support with VS Code. If you wish to set this up manually, please see the [`.vscode/launch.json`](https://github.com/markshust/docker-magento/blame/master/compose/.vscode/launch.json) file.

### Xdebug & VS Code in a WSL2 environment

Install and enable the PHP Debug extension from the [Visual Studio Marketplace](https://marketplace.visualstudio.com/items?itemName=felixfbecker.php-debug).

Otherwise, this project now automatically sets up Xdebug support with VS Code. If you wish to set this up manually, please see the [`.vscode/launch.json`](https://github.com/markshust/docker-magento/blame/master/compose/.vscode/launch.json) file.

1. In VS Code, make sure that it's running in a WSL window, rather than in the default window.
2. Install the [`PHP Debug`](https://marketplace.visualstudio.com/items?itemName=xdebug.php-debug) extension on VS Code.
3. Create a new configuration file inside the project. Go to the `Run and Debug` section in VS Code, then click on `create a launch.json file`.
4. Attention to the following configs inside the file:
    * The port must be the same as the port on the xdebug.ini file.
    ```bash
      bin/cli cat /usr/local/etc/php/conf.d/php.ini   # bin/xdebug enable sets xdebug.mode = debug
    ```
    ```bash
      memory_limit = 4G
      max_execution_time = 1800
      zlib.output_compression = On
      cgi.fix_pathinfo = 0
      date.timezone = UTC

      xdebug.mode = debug
      xdebug.client_host = host.docker.internal
      xdebug.idekey = PHPSTORM
      xdebug.client_port=9003
      #You can uncomment the following line to force the debug with each request
      #xdebug.start_with_request=yes

      upload_max_filesize = 100M
      post_max_size = 100M
      max_input_vars = 10000
    ```
    * The pathMappings should have the same folder path as the project inside the Docker container.
    ```json
      {
          "version": "0.2.0",
          "configurations": [
              {
                  "name": "Listen for XDebug",
                  "type": "php",
                  "request": "launch",
                  "port": 9003,
                  "pathMappings": {
                      "/var/www": "${workspaceFolder}"
                  },
                  "hostname": "localhost"
              }
          ]
      }
    ```
5. Run the following command in the Windows Powershell. It allows WSL through the firewall, otherwise breakpoints might not be hitten.
    ```powershell
    New-NetFirewallRule -DisplayName "WSL" -Direction Inbound  -InterfaceAlias "vEthernet (WSL)"  -Action Allow
    ```

### Xdebug & PhpStorm

1.  First, install the [Chrome Xdebug helper](https://chrome.google.com/webstore/detail/xdebug-helper/eadndfjplgieldjbigjakmdgkmoaaaoc). After installed, right click on the Chrome icon for it and go to Options. Under IDE Key, select PhpStorm from the list to set the IDE Key to "PHPSTORM", then click Save.

2.  Next, enable Xdebug debugging in the PHP container by running: `bin/xdebug enable`.

3.  Then, open `PhpStorm > Preferences > PHP` and configure:

    * `CLI Interpreter`
        * Create a new interpreter from the `From Docker, Vagrant, VM...` list.
        * Select the Docker Compose option.
        * For Server, select `Docker`. If you don't have Docker set up as a server, create one and name it `Docker`.
        * For Configuration files, add the `compose.yaml` file from your project directory (and `compose.frankenphp.yaml` when using FrankenPHP).
        * For Service, select `{{project_name}}-php`, then click OK.
        * Name this CLI Interpreter `{{project_name}}-php`, then click OK again.

    * `Path mappings`
        * There is no need to define a path mapping in this area.

4. Open `PhpStorm > Preferences > PHP > Debug` and ensure Debug Port is set to `9000,9003`.

5. Open `PhpStorm > Preferences > PHP > Servers` and create a new server:

    * For the Name, set this to the value of your domain name (ex. `{{project_name}}.test`).
    * For the Host, set this to the value of your domain name (ex. `{{project_name}}.test`).
    * Keep port set to `80`.
    * Check the "Use path mappings" box and map `src` to the absolute path of `/var/www/src`.

6. Go to `Run > Edit Configurations` and create a new `PHP Remote Debug` configuration.

    * Set the Name to the name of your domain (ex. `{{project_name}}.test`).
    * Check the `Filter debug connection by IDE key` checkbox, select the Server you just setup.
    * For IDE key, enter `PHPSTORM`. This value should match the IDE Key value set by the Chrome Xdebug Helper.
    * Click OK to finish setting up the remote debugger in PHPStorm.

7. Open up `pub/index.php` and set a breakpoint near the end of the file.

    * Start the debugger with `Run > Debug '{{project_name}}.test'`, then open up a web browser.
    * Ensure the Chrome Xdebug helper is enabled by clicking on it and selecting Debug. The icon should turn bright green.
    * Navigate to your Magento store URL, and Xdebug should now trigger the debugger within PhpStorm at the toggled breakpoint.


### Contributions
Want to make this project better? Feel free to submit a PR or open an issue. We promise not to ignore it (too much).
