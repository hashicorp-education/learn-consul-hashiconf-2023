terraform init
terraform apply --auto-approve
# wait 10-15 minutes for build

# Connect to EKS
aws eks --region $(terraform output -raw region) update-kubeconfig --name $(terraform output -raw kubernetes_cluster_id)

# Set environment variables
export CONSUL_HTTP_TOKEN=$(terraform output -raw consul_root_token) && \
export CONSUL_HTTP_ADDR=$(terraform output -raw consul_url)

# Notice that Consul services exist
consul catalog services

# DATA PLANE TIME

# Upgrade Consul to enable metrics
terraform apply -var="consul_helm_filename=consul-v2-data-plane.tpl"

# Review data plane helm lines while it's upgrading

# Update proxy defaults to enable proxy access logs
kubectl apply --filename proxy/proxy-defaults.yaml

# Redeploy HashiCups with updated proxies
kubectl rollout restart deployment --namespace default

# Go to API gateway URL and explore HashiCups to generate traffic
export CONSUL_APIGW_ADDR=http://$(kubectl get svc/api-gateway -o json | jq -r '.status.loadBalancer.ingress[0].hostname') && \
echo $CONSUL_APIGW_ADDR

# Go to Grafana URL and check out DATA PLANE dashboards
export GRAFANA_URL=http://$(kubectl get svc/grafana --namespace observability -o json | jq -r '.status.loadBalancer.ingress[0].hostname') && \
echo $GRAFANA_URL

# CONTROL PLANE TIME

# Go to Grafana URL and check out CONTROL PLANE dashboards
export GRAFANA_URL=http://$(kubectl get svc/grafana --namespace observability -o json | jq -r '.status.loadBalancer.ingress[0].hostname') && \
echo $GRAFANA_URL

# HCP PORTAL TIME

# Go to HCP Portal
https://portal.cloud.hashicorp.com/
# Link an existing self-managed cluster
# Run through the config instructions


# Give it a couple minutes to sync

# Review Architecture diagram

# Come back to check out portal and observability insights

# Summary

# Check out Consul (optional)
echo $CONSUL_HTTP_ADDR && echo $CONSUL_HTTP_TOKEN