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
   - RabbitMQ

## Prerequisites
- [Docker Compose](https://docs.docker.com/engine/install/ubuntu/)
- [NGINX PROXY](https://github.com/adrianalin89/nginx-proxy) project need's to be setup and running

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
After starting the container and editing the `.env` file you will have to download the version of Magento that you want to use.

``` 
bin/download community 2.4.7-p3
```
Use `bin/setup-install` to automatically install it using the information from the env file. This will seed the DB and generate the env.php file.

Use `bin/setup-magento` to add the new domain to hosts file.

Restart the container `bin/restart` and you shod be good to go `bin/magento set:up`
#

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
- `bin/setup`: Run the Magento setup process to install Magento from the source code, with optional domain name. Defaults to `{{project_name}}.test`. Ex. `bin/setup {{project_name}}.test`
- `bin/setup-composer-auth`: Setup authentication credentials for Composer.
- `bin/setup-dcker` : Setup Magento project in Docker.
- `bin/setup-magento` : Setup Magento ....
- `bin/setup-grunt`: Install and configure Grunt JavaScript task runner to compile .less files
- `bin/setup-install`: Automates the installation process for a Magento instance.
- `bin/setup-integration-tests`: Script to set up integration tests.
- `bin/setup-pwa-studio`: (BETA) Install PWA Studio (requires NodeJS and Yarn to be installed on the host machine). Pass in your base site domain, otherwise the default `master-7rqtwti-mfwmkrjfqvbjk.us-4.magentosite.cloud` will be used. Ex: `bin/setup-pwa-studio {{project_name}}.test`.
- `bin/setup-pwa-studio-sampledata`: This script makes it easier to install Venia sample data. Pass in your base site domain, otherwise the default `master-7rqtwti-mfwmkrjfqvbjk.us-4.magentosite.cloud` will be used. Ex: `bin/setup-pwa-studio-sampledata {{project_name}}.test`.
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
#### de facut documentatia mai clara pentru tipul de certificare





### Multiple Domain Configuration
- Current limitation: `bin/setup-magento` supports only a single domain
- Manual adjustments needed for multiple domain routing
Use a single domain to instal it and after that update the `.env` file `DOMAIN_HOSTS` add multiple domains separated by comma `,`. 

### HTPASSWD project
Run the following command to add a user to the `.htpasswd` file. Change the `admin` to the user you want to add.
```
sh -c "echo -n 'admin:' >> images/nginx/.htpasswd"
```
Run the following command to add a password to the `.htpasswd` file. A password will be prompted to be entered.
```
sh -c "openssl passwd -apr1 >> images/nginx/.htpasswd"
```
In images/nginx/default.conf find and update the location / to the fallowing:
```
location / {
        try_files $uri $uri/ /index.php?$query_string;
        # Uncomment to enable naxsi on this location
        #auth_basic "Restricted Area";
        #auth_basic_user_file /etc/nginx/.htpasswd;
    }
```
Add a volume to the nginx service in the `compose.yml` file to mount the `.htpasswd` file to the container.
```
    volumes:
      - ./images/nginx/.htpasswd:/etc/nginx/.htpasswd
```

### add dummy data
`` bin/magento sampledata:deploy`` to add default magento dummy data and then run `bin/magento setup:upgrade` to install it.
### how to use the update command
### create chat ores for grunt, pcx, xdebug, testing,... and all that stuff
### Troubleshooting
- Verify all container names match in `.env` and configuration files
- Check Docker logs for any startup or configuration issues
- Ensure all required environment variables are set
- `bin/setup-magento` prompts the fallowing error:`There are no commands defined in the "config" namespace.` you need to run `bin/magento set:up` to see what the issue is. After resolving the issue you will have to manually change the base url in the database.
- `bin/magento set:up` prompts the fallowing error:'Could not validate a connection to Elasticsearch. No alive nodes found in your cluster'. It may mean the magento version is not compatible with opensearch and you need to change to elasticsearch. You can do this by changing the network in the `compose.yaml`  from `open-search-network` to `elastic-search-network` (also go to the env.php file and under elasticsearch change the host to `elastisearch`) and then run `bin/restart` and try again.

### Caching

For an improved developer experience, caches are automatically refreshed when related files are updated, courtesy of [cache-clean](https://github.com/mage2tv/magento-cache-clean). This means you can keep all of the standard Magento caches enabled, and this script will only clear the specific caches needed, and only when necessary.

To disable this functionality, uncomment the last line in the `bin/start` file to disable the watcher.

### Redis

Redis is now the default cache and session storage engine, and is automatically configured & enabled when running `bin/setup` on new installs.

Use the following lines to enable Redis on existing installs:

**Enable for Cache:**

`bin/magento setup:config:set --cache-backend=redis --cache-backend-redis-server=redis --cache-backend-redis-db=0`

**Enable for Full Page Cache:**

`bin/magento setup:config:set --page-cache=redis --page-cache-redis-server=redis --page-cache-redis-db=1`

**Enable for Session:**

`bin/magento setup:config:set --session-save=redis --session-save-redis-host=redis --session-save-redis-log-level=4 --session-save-redis-db=2`

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
      bin/cli cat /usr/local/etc/php/php.ini
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
                      "/var/www/html": "${workspaceFolder}"
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
        * For Configuration files, add both the `compose.yaml` and `compose.dev.yaml` files from your project directory.
        * For Service, select `phpfpm`, then click OK.
        * Name this CLI Interpreter `phpfpm`, then click OK again.

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