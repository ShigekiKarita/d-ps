#!/usr/bin/env bash
set -e
set -u
set -o pipefail

source "$(curl -fsS  --retry 3 https://dlang.org/install.sh | bash -s $1 --activate)"
dub test --build=unittest-cov
# cat dub.selections.json

if [ "$DC" = dmd ]; then
    bash <(curl -s https://codecov.io/bash) -s "*-grain-*.lst"
fi

