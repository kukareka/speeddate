#!/bin/bash

source ../secrets.sh
MIX_ENV=prod mix compile
npm install --prefix ./assets
npm run deploy --prefix ./assets
mix phx.digest
