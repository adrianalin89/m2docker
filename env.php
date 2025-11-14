<?php

/**
 * Magento Env.php file
 *
 * @category    Magento
 * @package     Magento\Framework\App
 * @author      Munteanu Alin
 *
 * This file is an example of the env.php file that is used to configure Magento 2.
 * It is semi-automatically generated and some manual changes may be required.
 * Refer to the documentation for guidance.
 */

$DB_user = "magento";
$DB_pass = "magento";

return [
    /**
     * Settings for the Admin area
     * Add more settings as needed
     */
    "backend" => [
        "frontName" => "admin", // Configure the frontName for the admin url
        "session_lifetime" => 0, // Backend session lifetime
        "password_lifetime" => 0, // Password lifetime
    ],

    /**
     * Configure redis page and default cache
     * Uncomment the following lines to enable redis cache
     */
    "cache" => [
        "frontend" => [
            "default" => [
                "id_prefix" => "69d_",
                "backend" => "Magento\\Framework\\Cache\\Backend\\Redis",
                "backend_options" => [
                    "server" => "{{project_name}}-redis",
                    "database" => "0",
                    "port" => "6379",
                    "password" => "",
                    "compress_data" => "1",
                    "compression_lib" => "",
                ],
            ],
            "page_cache" => [
                "id_prefix" => "69d_",
                "backend" => "Magento\\Framework\\Cache\\Backend\\Redis",
                "backend_options" => [
                    "server" => "{{project_name}}-redis",
                    "database" => "1",
                    "port" => "6379",
                    "password" => "",
                    "compress_data" => "0",
                    "compression_lib" => "",
                ],
            ],
        ],
        "allow_parallel_generation" => false, // A redis FLAG for eliminate waiting for locks DEFAULT: false
        "graphql" => ["id_salt" => "t0JT14Nfg0c2Pd9X7boTCWAWxl97TcM7"],
    ],

    /**
     * All the cache types configurations are available from this node.
     * This current configuration is used for local development and testing.
     */
    "cache_types" => [
        "config" => 1,
        "layout" => 0,
        "block_html" => 0,
        "collections" => 1,
        "reflection" => 1,
        "db_ddl" => 1,
        "compiled_config" => 1,
        "eav" => 1,
        "customer_notification" => 1,
        "config_integration" => 1,
        "config_integration_api" => 1,
        "full_page" => 0,
        "config_webservice" => 1,
        "translate" => 1,
    ],

    /**
     * Configure the session storage
     * Uncomment the following lines to enable rabitmq server
     */
    "queue" => [
        "amqp" => [
            "host" => "rabbitmq",
            "port" => "5672",
            "user" => "{{project_name}}",
            "password" => "magento",
            "virtualhost" => "{project_name}}-magento",
            "ssl" => false,
            "reconnect_attempts" => 3,
            "connect_timeout" => 5,
        ],
        "consumers_wait_for_messages" => 0,
        /**
         * 1 — Consumers continue to process messages from the message queue until reaching the max_messages value
         * specified in the env.php file before closing the TCP connection and terminating the consumer process.
         * If the queue empties before reaching the max_messages value, the consumer waits for more messages to arrive.
         * We recommend this setting for large merchants because a constant message flow is expected and delays in
         * processing are undesirable.
         *
         * 0 — Consumers process available messages in the queue, close the TCP connection, and terminate.
         * Consumers do not wait for additional messages to enter the queue, even if the number of processed
         * messages is less than the max_messages value specified in the env.php file.
         * This can help prevent issues with cron jobs caused by long delays in message queue processing.
         * We recommend this setting for smaller merchants that do not expect a constant message flow and
         * prefer to conserve computing resources in exchange for minor processing delays when there could be
         * no messages for days.
         */
    ],

    /**
     * Configure the default cron job settings
     * Local don't need to run cron jobs
     */
    "cron" => [
        "enabled" => 0,
    ],

    /**
     * Commerce uses an encryption key to protect passwords and other sensitive data.
     * This key is generated during the installation process.
     */
    "crypt" => ["key" => "7418fb8efd9f75d91ce5a2bf7c8cb621"],

    /**
     * All database configurations are available in this node.
     */
    "db" => [
        "table_prefix" => "", // Prefix for the database table names
        "connection" => [
            "default" => [
                "host" => "{{project_name}}-db",
                "dbname" => "{{project_name}}",
                "username" => $DB_user,
                "password" => $DB_pass,
                "active" => "1",
                "model" => "mysql4",
                "engine" => "innodb",
                "initStatements" =>
                    "SET NAMES utf8; SET SESSION query_cache_type = OFF;",
                "driver_options" => [1014 => false],
                "profiler" => [
                    "class" => "\\Magento\\Framework\\DB\\Profiler",
                    "enabled" => true,
                ],
            ],
        ],
    ],

    /**
     * Optional directory mapping options that need to be set when the web server is configured
     * to serve from the /pub directory for improved security.
     */
    "directories" => ["document_root_is_pub" => true],

    /**
     * A list of downloadable domains available in this node.
     */
    "downloadable_domains" => ["{{project_name}}.test"],

    /**
     * Lock provider settings
     */
    "lock" => ["provider" => "db"],

    /**
     * The deployment mode
     */
    "MAGE_MODE" => "developer",

    /**
     * Resource configuration settings
     */
    "resource" => ["default_setup" => ["connection" => "default"]],

    /**
     * The configuration settings for the session
     * Uncomment the following lines to enable redis session
     */
    "session" => [
        //save' => 'files',
        /*
    'session_name' => 'PHPSESSID',
    'session_save_path' => '/var/session',
    'cookie_lifetime' => 86400,
     //'cookie_path' => '/',
     //'cookie_domain' => '.{{project_name}}.test',
    'use_remote_addr' => '0', // Set to 0 to disable remote address validation
    'use_http_via' => '0',
    'use_http_x_forwarded_for' => '0',
    'use_http_user_agent' => '0', // Set to 0 to disable user agent validation
    'use_frontend_sid' => true
    */

        "save" => "redis",
        "redis" => [
            "host" => "{{project_name}}-redis",
            "port" => "6379",
            "password" => "",
            "timeout" => "2.5",
            "persistent_identifier" => "",
            "database" => "2",
            "compression_threshold" => "2048",
            "compression_library" => "gzip",
            "log_level" => "4",
            "max_concurrency" => "6",
            "break_after_frontend" => "5",
            "break_after_adminhtml" => "30",
            "first_lifetime" => "600",
            "bot_first_lifetime" => "60",
            "bot_lifetime" => "7200",
            "disable_locking" => "0",
            "min_lifetime" => "60",
            "max_lifetime" => "2592000",
            "sentinel_master" => "",
            "sentinel_servers" => "",
            "sentinel_connect_retries" => "5",
            "sentinel_verify_master" => "0",
        ],
    ],

    /**
     * The configuration settings for the header frame options
     */
    "x-frame-options" => "SAMEORIGIN",

    /**
     * The configuration settings for the search engine
     */
    "elasticsearch" => [
        "host" => "{{project_name}}-opensearch",
        "port" => "9200",
        "index_prefix" => "{{project_name}}",
        "enable_auth" => false,
        "timeout" => 15,
    ],

    /**
     * The configuration settings for the domain
     */
    "system" => [
        "default" => [
            "web" => [
                "secure" => [
                    "base_url" => "https://{{project_name}}.test/",
                ],
            ],
        ],
    ],

    /**
     * This debuging for the db will create big log files so uncoment only if you need to debug the db
     */
    /*
'db_logger' => [
    'output' => 'file',
    'log_everything' => 1,
    'query_time_threshold' => '5.000',
    'include_stacktrace' => 1,
],
'dev' => [
    'syslog' => [
        'syslog_logging' => 0
    ],
    'debug' => [
        'xdebug_enable' => true,
        'xdebug_host' => 'host.docker.internal',
    ],
],
*/
    "remote_storage" => ["driver" => "file"],
    "install" => [
        "date" => "Sat, 17 Oct 2020 19:17:20 +0000",
    ],
];
