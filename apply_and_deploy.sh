#!/usr/bin/env bash

pushd ./deploy

terraform apply -var-file ./varfiles/sandbox

popd

eb deploy
