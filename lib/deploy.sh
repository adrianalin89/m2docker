#!/usr/bin/env bash
# Shared helpers for bin/pipeline, bin/deploy and bin/deploy-releases.
#
# Source this file with:
#   . "$(dirname "$0")/../lib/deploy.sh"
#
# Everything here runs without a TTY (bin/clinotty), so it works from CI
# pipelines (Bitbucket ssh-run pipe, ssh without -t, cron).

# The Bitbucket ssh-run pipe connects with `ssh -tt`, so there IS a terminal: git
# (log, show, diff) would open a pager and wait forever with maintenance mode on.
export GIT_PAGER=cat PAGER=cat

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="$PROJECT_ROOT/.env"

# Read a single variable from .env without sourcing the whole file.
env_value() {
  [ -f "$ENV_FILE" ] || return 0
  grep -E "^$1=" "$ENV_FILE" | tail -n 1 | cut -d '=' -f2- | sed -e 's/^"//' -e 's/"$//'
}

# Deploy settings, see .env.sample. Values already exported in the shell win
# over .env, so a single run can be overridden: DEPLOY_BRANCH=hotfix bin/pipeline
load_deploy_env() {
  PROJECT_NAME="${PROJECT_NAME:-$(env_value PROJECT_NAME)}"
  DEPLOY_TYPE="${DEPLOY_TYPE:-$(env_value DEPLOY_TYPE)}"
  DEPLOY_TYPE="${DEPLOY_TYPE:-simple}"
  DEPLOY_BRANCH="${DEPLOY_BRANCH:-$(env_value DEPLOY_BRANCH)}"
  DEPLOY_LOCALES="${DEPLOY_LOCALES:-$(env_value DEPLOY_LOCALES)}"
  DEPLOY_LOCALES="${DEPLOY_LOCALES:-en_US}"
  DEPLOY_MAINTENANCE="${DEPLOY_MAINTENANCE:-$(env_value DEPLOY_MAINTENANCE)}"
  DEPLOY_MAINTENANCE="${DEPLOY_MAINTENANCE:-1}"
  DEPLOY_COMPOSER_ARGS="${DEPLOY_COMPOSER_ARGS:-$(env_value DEPLOY_COMPOSER_ARGS)}"
  DEPLOY_TAILWIND="${DEPLOY_TAILWIND:-$(env_value DEPLOY_TAILWIND)}"
  DEPLOY_TAILWIND="${DEPLOY_TAILWIND:-1}"
  DEPLOY_KEEP_RELEASES="${DEPLOY_KEEP_RELEASES:-$(env_value DEPLOY_KEEP_RELEASES)}"
  DEPLOY_KEEP_RELEASES="${DEPLOY_KEEP_RELEASES:-3}"
  PHP_CONTAINER="${PROJECT_NAME}-php"
}

log_info()  { echo -e "${BLUE}ℹ️  $1${NC}"; }
log_ok()    { echo -e "${GREEN}✅ $1${NC}"; }
log_warn()  { echo -e "${YELLOW}⚠️  $1${NC}"; }
log_error() { echo -e "${RED}❌ $1${NC}"; }

# step "Title" command args...  -> numbered, timed, stops the deploy on failure
STEP_NO=0
step() {
  local title="$1"
  shift
  STEP_NO=$((STEP_NO + 1))
  local started=$SECONDS
  echo ""
  echo -e "${YELLOW}━━ [$STEP_NO] $title${NC}"
  if "$@"; then
    log_ok "$title ($((SECONDS - started))s)"
  else
    local rc=$?
    log_error "$title failed (exit $rc)"
    return $rc
  fi
}

check_php_container() {
  if ! docker ps --format '{{.Names}}' | grep -q "^${PHP_CONTAINER}$"; then
    log_error "Container ${PHP_CONTAINER} is not running (bin/start)."
    return 1
  fi
}

# Run a command inside the php container, in the given directory (relative to /var/www).
in_container() {
  local dir="$1"
  shift
  docker exec -u www-data -w "/var/www/$dir" "$PHP_CONTAINER" bash -c "$*"
}

# Tailwind theme folders (Hyvä) inside a Magento root, relative to it.
tailwind_themes() {
  in_container "$1" '{
      find app/design/frontend -mindepth 5 -maxdepth 5 -type f -path "*/web/tailwind/package.json" 2>/dev/null
      find app/code -mindepth 5 -maxdepth 5 -type f -path "*/web/tailwind/package.json" 2>/dev/null
    } | sed "s|/package.json$||" | sort -u'
}

# npm ci (or install when there is no lock file) + build-prod for every Hyvä theme.
build_tailwind() {
  local root="$1"
  local themes
  themes="$(tailwind_themes "$root")"
  if [ -z "$themes" ]; then
    log_info "No Hyvä Tailwind themes found, skipping."
    return 0
  fi
  local theme
  while IFS= read -r theme; do
    [ -z "$theme" ] && continue
    log_info "Tailwind: $theme"
    in_container "$root" "if [ -f '$theme/package-lock.json' ]; then npm --prefix '$theme' ci; else npm --prefix '$theme' install; fi && npm --prefix '$theme' run build-prod" || return 1
  done <<< "$themes"
}

# Empty the Redis cache databases of <dir>/app/etc/env.php (dir relative to /var/www) without
# bin/magento. After a code update the cache can still hold the DI config of the previous code, and
# then bin/magento itself cannot boot (ex. a new <preference> -> "Cannot instantiate interface"), so
# not even cache:flush works. FLUSHDB on each cache database is what cache:flush does on Redis.
flush_redis_cache() {
  docker exec -i -u www-data -w "/var/www/$1" "$PHP_CONTAINER" php <<'PHP'
<?php
$env = include 'app/etc/env.php';
$send = function ($socket, array $args) {
    $request = '*' . count($args) . "\r\n";
    foreach ($args as $arg) {
        $request .= '$' . strlen((string) $arg) . "\r\n" . $arg . "\r\n";
    }
    fwrite($socket, $request);
    $reply = fgets($socket);
    if ($reply === false || $reply[0] === '-') {
        throw new RuntimeException(trim($reply === false ? 'no reply' : substr($reply, 1)));
    }
};
$flushed = [];
foreach ($env['cache']['frontend'] ?? [] as $name => $frontend) {
    $backend = $frontend['backend'] ?? 'file';
    $options = $frontend['backend_options'] ?? [];
    if (stripos($backend, 'RemoteSynchronizedCache') !== false) {
        $backend = $options['remote_backend'] ?? '';
        $options = $options['remote_backend_options'] ?? [];
    }
    if (!preg_match('/redis|valkey/i', $backend)) {
        echo "$name: $backend backend, not Redis, skipped\n";
        continue;
    }
    $server = $options['server'] ?? '127.0.0.1';
    $port = (int) ($options['port'] ?? 6379);
    $database = (int) ($options['database'] ?? 0);
    $address = strpos($server, '/') === 0 ? "unix://$server"
        : (strpos($server, '://') !== false ? "$server:$port" : "tcp://$server:$port");
    if (isset($flushed["$address/$database"])) {
        continue;
    }
    try {
        $socket = stream_socket_client($address, $errno, $error, 5);
        if (!$socket) {
            throw new RuntimeException($error);
        }
        stream_set_timeout($socket, 60);
        if (!empty($options['password'])) {
            $send($socket, empty($options['username'])
                ? ['AUTH', $options['password']] : ['AUTH', $options['username'], $options['password']]);
        }
        $send($socket, ['SELECT', $database]);
        $send($socket, ['FLUSHDB']);
        fclose($socket);
    } catch (Throwable $e) {
        fwrite(STDERR, "$name: could not flush $address db $database: {$e->getMessage()}\n");
        exit(1);
    }
    $flushed["$address/$database"] = true;
    echo "$name: flushed $address db $database\n";
}
if (!$flushed) {
    echo "No Redis cache in app/etc/env.php\n";
}
PHP
}

# Make PHP pick up new code after a release switch (realpath + OPcache).
reload_php() {
  if docker exec "$PHP_CONTAINER" pgrep -o php-fpm >/dev/null 2>&1; then
    docker exec "$PHP_CONTAINER" bash -c 'kill -USR2 $(pgrep -o php-fpm)'
  elif docker exec "$PHP_CONTAINER" pgrep -o frankenphp >/dev/null 2>&1; then
    docker exec "$PHP_CONTAINER" supervisorctl -c /etc/supervisor/conf.d/supervisord.conf restart frankenphp
  else
    log_warn "No php-fpm or frankenphp process found to reload."
  fi
}
