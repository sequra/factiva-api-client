#!/bin/sh

set -e

bundle check || bundle install && bundle binstubs --all --path="$BUNDLE_BIN"

exec "$@"
