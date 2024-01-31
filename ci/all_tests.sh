#!/usr/bin/env bash

# https://vaneyckt.io/posts/safer_bash_scripts_with_set_euxo_pipefail/
set -euxo pipefail

roc='./roc_nightly/roc'

examples_dir='./package/'

# roc check
for roc_file in $examples_dir*.roc; do
    $roc check $roc_file
done

$roc test ./package/Tests.roc