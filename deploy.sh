#!/bin/bash
set -e

ENVIRONMENT=$1
COMMIT_SHA=$2
APP_NAME="your-fastapi-app"
REGISTRY_URL="157.180.69.112:5000"

echo "🚀 Deploying $APP_NAME to $ENVIRONMENT environment..."


if ! sudo grep -q "157.180.69.112:5000" /etc/docker/daemon.json 2>/dev/null; then
    echo "Configuring Docker for insecure registry..."
    sudo systemctl stop docker
    echo '{"insecure-registries": ["157.180.69.112:5000"]}' | sudo tee /etc/docker/daemon.json
    sudo systemctl start docker
    sleep 5
fi

# Login to registry
docker login $REGISTRY_URL -u $REGISTRY_USERNAME -p $REGISTRY_PASSWORD

# Create app directory if it doesn't exist
mkdir -p /opt/swarm/apps/$APP_NAME

# Pull latest image
docker pull $REGISTRY_URL/$APP_NAME:$ENVIRONMENT-latest

# Set environment-specific variables
case $ENVIRONMENT in
  "dev")
    STACK_NAME="$APP_NAME-dev"
    DOMAIN="dev.$APP_NAME.cortanexai.com"
    REPLICAS=1
    ;;
  "prod")
    STACK_NAME="$APP_NAME-prod"
    DOMAIN="$APP_NAME.cortanexai.com"
    REPLICAS=2
    ;;
  *)
    echo "❌ Unknown environment: $ENVIRONMENT"
    exit 1
    ;;
esac

# Create docker-compose file
cat > /opt/swarm/apps/$APP_NAME/docker-compose.$ENVIRONMENT.yml << EOF
version: '3.8'

services:
  app:
    image: $REGISTRY_URL/$APP_NAME:$ENVIRONMENT-latest
    deploy:
      replicas: $REPLICAS
      update_config:
        parallelism: 1
        delay: 10s
      restart_policy:
        condition: on-failure
    environment:
      - ENVIRONMENT=$ENVIRONMENT
      - COMMIT_SHA=$COMMIT_SHA
    networks:
      - traefik-public
    labels:
      - "traefik.enable=true"
      - "traefik.docker.network=traefik-public"
      - "traefik.http.services.$STACK_NAME.loadbalancer.server.port=8000"
      - "traefik.http.routers.$STACK_NAME.rule=Host(\`$DOMAIN\`)"
      - "traefik.http.routers.$STACK_NAME.entrypoints=web"

networks:
  traefik-public:
    external: true
EOF

# Deploy stack
cd /opt/swarm/apps/$APP_NAME
docker stack deploy -c docker-compose.$ENVIRONMENT.yml $STACK_NAME --with-registry-auth

# Wait for deployment
echo "⏳ Waiting for deployment to complete..."
sleep 30

# Health check
echo "🔍 Performing health check..."
MAX_RETRIES=10
RETRY_COUNT=0

until curl -f http://$DOMAIN/health || [ $RETRY_COUNT -eq $MAX_RETRIES ]; do
  echo "⏳ Service not ready, retrying... ($((RETRY_COUNT+1))/$MAX_RETRIES)"
  sleep 10
  RETRY_COUNT=$((RETRY_COUNT+1))
done

if [ $RETRY_COUNT -eq $MAX_RETRIES ]; then
  echo "❌ Health check failed after $MAX_RETRIES attempts"
  exit 1
fi

echo "✅ Deployment to $ENVIRONMENT completed successfully!"
echo "🌐 Access your application at: http://$DOMAIN"
echo "📚 API documentation at: http://$DOMAIN/docs"