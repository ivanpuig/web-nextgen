# Apunta la AWS CLI a AWS real, con las credenciales de ~/.aws/credentials.
# Uso: source usar-aws.sh
unset AWS_ENDPOINT_URL AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN
export AWS_DEFAULT_REGION=us-east-1
echo "Destino: AWS real"
