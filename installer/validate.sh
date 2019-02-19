#!/bin/bash
. ./utils/messages.sh

DOMAIN_NAME=$1
cd ../scripts
header "Validating IMM platform installation"
header "Preparing python environment"
virtualenv -p python3 .testvenv
. .testvenv/bin/activate
pip install -r requirements.txt
header "Preparing env variables and installing CA"
. ./prepare_test_env.sh $DOMAIN_NAME
header "Running tests"
./test_imm.sh
deactivate
cd -
