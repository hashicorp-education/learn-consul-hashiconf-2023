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

# Upgrade Consul to enable metrics
terraform apply -var="consul_helm_filename=consul-v2.tpl"

# Redeploy HashiCups with updated proxies
kubectl delete --filename hashicups/ && kubectl apply --filename hashicups/

# Go to API gateway URL and explore HashiCups to generate traffic
export CONSUL_APIGW_ADDR=http://$(kubectl get svc/api-gateway -o json | jq -r '.status.loadBalancer.ingress[0].hostname') && \
echo $CONSUL_APIGW_ADDR

# Go to Grafana URL and check out dashboards
export GRAFANA_URL=http://$(kubectl get svc/grafana --namespace observability -o json | jq -r '.status.loadBalancer.ingress[0].hostname') && \
echo $GRAFANA_URL

# Check out Consul (optional)
echo $CONSUL_HTTP_ADDR && export $CONSUL_HTTP_TOKEN