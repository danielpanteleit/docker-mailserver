#!/usr/bin/env bash

set -e

if [[ ! -d venv ]]; then
  python3 -m venv venv
  . venv/bin/activate
  pip install pip setuptools --upgrade
  pip install pytest
else
  . venv/bin/activate
fi

pytest py-tests
