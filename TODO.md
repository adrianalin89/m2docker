# TODO

Open points for the m2docker boilerplate. Each one is discussed and decided
separately before it is implemented.

## Open

- [ ] Build and test `images/php/8.5` and `images/frankenphp/8.5` (never built yet), then a
      throwaway Mage-OS 3.6 project on 8.5 + nginx and on FrankenPHP (bin/download,
      bin/setup-install, bin/health-check, cart / checkout / admin).

## Done / decided

- 2026-10-23: Composer 2.10.3 and Node 24 in the 8.3 / 8.4 / 8.5 / FrankenPHP images (`ARG`s
  in the Dockerfiles); imagick from PECL 3.8.1 in 8.3 / 8.4, loaded once.
- 2026-10-23: `bin/setup-docker` only touches the boilerplate files; `bin/update` replaces the
  placeholder itself, has `--dry-run` / `--diff` / confirmation, deletes files removed from the
  boilerplate (bin/, lib/, images/) and never touches .env, src/ or compose.override.yaml,
  which `bin/docker-compose` now loads; legacy `bin/setup` removed; `bin/start` without the
  broken `--no-dev` branch.
- 2026-10-23: README: SSL certificates (self-signed, Let's Encrypt, own / wildcard client
  certificates) and bin/update.
- Ports of the project DB / Redis and of RabbitMQ stay published; htpasswd on the shared
  tools is considered enough (decided 2026-10-23).
