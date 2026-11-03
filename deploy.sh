#!/usr/bin/env bash
# Publica la carpeta web/ en un bucket S3 y comprueba que la web responde.
# Es el MISMO script en Floci, en GitHub Actions y en AWS: el destino lo
# deciden las variables de entorno, no este archivo.
set -euo pipefail
source ./config.sh

REGION="${AWS_DEFAULT_REGION:-us-east-1}"
INTENTOS="${INTENTOS:-6}"

if [ -n "${AWS_ENDPOINT_URL:-}" ]; then
  echo "== Destino: FLOCI ($AWS_ENDPOINT_URL) =="
  HOST_WEB="$BUCKET.s3-website-$REGION.localhost:4566"
  URL_PRUEBA="$AWS_ENDPOINT_URL/"
else
  echo "== Destino: AWS REAL (región $REGION) =="
  HOST_WEB="$BUCKET.s3-website-$REGION.amazonaws.com"
  URL_PRUEBA="http://$HOST_WEB/"
fi

echo "1/4 Bucket: $BUCKET"
if ! aws s3api head-bucket --bucket "$BUCKET" >/dev/null 2>&1; then
  aws s3 mb "s3://$BUCKET"
fi

echo "2/4 Activando el modo sitio web"
aws s3 website "s3://$BUCKET" --index-document index.html --error-document error.html

echo "3/4 Permiso de lectura pública: $WEB_PUBLICA"
if [ "$WEB_PUBLICA" = "si" ]; then
  aws s3api put-public-access-block --bucket "$BUCKET" --public-access-block-configuration \
    BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=false,RestrictPublicBuckets=false
  POLITICA="{\"Version\":\"2012-10-17\",\"Statement\":[{\"Sid\":\"LecturaPublica\",\"Effect\":\"Allow\",\"Principal\":\"*\",\"Action\":\"s3:GetObject\",\"Resource\":\"arn:aws:s3:::$BUCKET/*\"}]}"
  aws s3api put-bucket-policy --bucket "$BUCKET" --policy "$POLITICA"
fi

echo "4/4 Subiendo los archivos de web/"
aws s3 sync web "s3://$BUCKET" --delete --no-progress

echo "Comprobando que la web responde..."
for ((i = 1; i <= INTENTOS; i++)); do
  CODIGO=$(curl -s -o /dev/null -m 10 -w '%{http_code}' -H "Host: $HOST_WEB" "$URL_PRUEBA" || true)
  [ "$CODIGO" = "200" ] && break
  [ "$i" -lt "$INTENTOS" ] && sleep 5
done

if [ "$CODIGO" != "200" ]; then
  echo "ERROR: la web responde con el código $CODIGO (se esperaba 200)."
  exit 1
fi
echo "OK. Tu web está en: http://$HOST_WEB/"
