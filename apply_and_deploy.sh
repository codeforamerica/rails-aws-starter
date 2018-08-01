#!/usr/bin/env bash

set -e

pushd ./deploy

terraform apply -var-file ./varfiles/sandbox

popd

eb deploy
