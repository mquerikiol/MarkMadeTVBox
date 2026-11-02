#!/bin/sh

cd "$(dirname "$0")/.." || exit 1

sh -n lib/jellyfin.sh || exit 1

. ./config/jellyfin.conf
. ./lib/jellyfin.sh

jellyfin_check
