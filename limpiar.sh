#!/usr/bin/env bash
# Borra el bucket y todo su contenido en el destino actual.
set -euo pipefail
source ./config.sh
echo "Borrando el bucket $BUCKET en: ${AWS_ENDPOINT_URL:-AWS REAL}"
aws s3 rb "s3://$BUCKET" --force
