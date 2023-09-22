terraform init
terraform apply --auto-approve
# wait 15 minutes for build

# Connect to EKS
aws eks --region $(terraform output -raw region) update-kubeconfig --name $(terraform output -raw kubernetes_cluster_id)

# Set environment variables
export CONSUL_HTTP_TOKEN=$(kubectl get --namespace consul secrets/consul-bootstrap-acl-token --template={{.data.token}} | base64 -d) && \
export CONSUL_HTTP_ADDR=https://$(kubectl get services/consul-ui --namespace consul -o jsonpath='{.status.loadBalancer.ingress[0].hostname}') && \
export CONSUL_HTTP_SSL_VERIFY=false

# Notice that Consul services exist
consul catalog services

# DATA PLANE TIME

# Upgrade Consul to enable data plane metrics
consul-k8s upgrade -config-file=helm/consul-v2-data-plane.yaml

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

# Upgrade Consul to enable control plane metrics
consul-k8s upgrade -config-file=helm/consul-v3-control-plane.yaml

# THE ANONYMOUS POLICY IS RESET EACH CONSUL UPGRADE
# Modify the anonymous ACL policy to allow agent read permissions so Prometheus is allowed to scrape metrics
consul acl policy update -name "anonymous-token-policy" \
                        -datacenter "dc1" \
                        -rules @acl-policies/rules.hcl


# Go to Grafana URL and check out CONTROL PLANE dashboards
export GRAFANA_URL=http://$(kubectl get svc/grafana --namespace observability -o json | jq -r '.status.loadBalancer.ingress[0].hostname') && \
echo $GRAFANA_URL


# HCP PORTAL TIME

# Go to HCP Portal
https://portal.cloud.hashicorp.com/
# Link an existing self-managed cluster
# Run through the config instructions

# Upgrade Consul to enable HCP management plane metrics
consul-k8s upgrade -config-file=helm/consul-v4-hcp-mgmt-plane.yaml

# Give it a couple minutes to sync

# Review Architecture diagram

# Come back to check out portal and observability insights

# Summary

# Check out Consul (optional)
echo $CONSUL_HTTP_ADDR && echo $CONSUL_HTTP_TOKEN