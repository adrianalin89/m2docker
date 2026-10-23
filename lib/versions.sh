#!/usr/bin/env bash
# Shared helpers for reading lib/versions.tsv.
#
# Source this file with:
#   . "$(dirname "$0")/../lib/versions.sh"
#
#   versions_lookup <edition> <version>     prints the TAB-separated row
#                                           "php composer mariadb opensearch rabbitmq cache nginx"
#                                           or returns 1 if no row matches
#   versions_prefix_match <prefix> <version> returns 0 if <prefix> is a boundary-aware prefix of <version>
#   version_ge <a> <b>                      returns 0 if version a >= version b

versions_tsv_path() {
  printf '%s\n' "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/versions.tsv"
}

versions_prefix_match() {
  local prefix="$1"
  local version="$2"
  case "$version" in
    "$prefix"|"$prefix".*|"$prefix"-*) return 0 ;;
    *) return 1 ;;
  esac
}

versions_lookup() {
  local edition="$1"
  local version="$2"
  local tsv
  tsv="$(versions_tsv_path)"

  [ -f "$tsv" ] && [ -n "$edition" ] && [ -n "$version" ] || return 1

  local row_edition row_prefix php composer db os rmq cache nginx
  while IFS=$'\t' read -r row_edition row_prefix php composer db os rmq cache nginx; do
    case "$row_edition" in
      ''|'#'*) continue ;;
    esac
    if [ "$row_edition" = "$edition" ] && versions_prefix_match "$row_prefix" "$version"; then
      printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "$php" "$composer" "$db" "$os" "$rmq" "$cache" "$nginx"
      return 0
    fi
  done < "$tsv"

  return 1
}

version_ge() {
  [ "$(printf '%s\n%s\n' "$2" "$1" | sort -V | head -n1)" = "$2" ]
}
