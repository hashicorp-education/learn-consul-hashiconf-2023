# Clone companion repository
git clone https://github.com/hashicorp-education/learn-consul-hashiconf-2023.git

# Ensure AWS credentials are set for Terraform on the CLI

# Run Terraform
terraform init
terraform apply --auto-approve
# wait 15 minutes for build

# Connect to EKS
aws eks --region $(terraform output -raw region) update-kubeconfig --name $(terraform output -raw kubernetes_cluster_id)

# Set Consul environment variables
export CONSUL_HTTP_TOKEN=$(kubectl get --namespace consul secrets/consul-bootstrap-acl-token --template={{.data.token}} | base64 -d) && \
export CONSUL_HTTP_ADDR=https://$(kubectl get services/consul-ui --namespace consul -o jsonpath='{.status.loadBalancer.ingress[0].hostname}') && \
export CONSUL_HTTP_SSL_VERIFY=false

# Notice that Consul services exist
consul catalog services

# DATA PLANE TIME

# Upgrade Consul to enable data plane metrics
consul-k8s upgrade -config-file=helm/consul-v2-data-plane.yaml
# wait 4-5 mins for upgrade

# Update proxy defaults to enable proxy access logs
kubectl apply --filename config/proxy-defaults.yaml

# Redeploy HashiCups with updated proxies
kubectl rollout restart deployment --namespace default

# Go to API gateway URL and explore HashiCups to generate traffic
export CONSUL_APIGW_ADDR=http://$(kubectl get svc/api-gateway -o json | jq -r '.status.loadBalancer.ingress[0].hostname') && \
echo $CONSUL_APIGW_ADDR
# It is expected that HashiCups is not totally functional at this point

# Go to Grafana URL and check out DATA PLANE dashboards
export GRAFANA_URL=http://$(kubectl get svc/grafana --namespace observability -o json | jq -r '.status.loadBalancer.ingress[0].hostname') && \
echo $GRAFANA_URL

# Set the Consul annotation to true in hashicups/public-api.yaml
# This will make HashiCups functional

# Go back to the HashiCups UI to check that it is now working
echo $CONSUL_APIGW_ADDR

#
# CONTROL PLANE TIME
#

# Upgrade Consul to enable control plane metrics
consul-k8s upgrade -config-file=helm/consul-v3-control-plane.yaml
# wait 4-5 mins for upgrade

# Modify the anonymous ACL policy to allow agent read permissions so Prometheus is allowed to scrape metrics
consul acl policy update -name "anonymous-token-policy" \
                        -datacenter "dc1" \
                        -rules @config/acl-policy.hcl

# Go to Grafana URL and check out CONTROL PLANE dashboards
export GRAFANA_URL=http://$(kubectl get svc/grafana --namespace observability -o json | jq -r '.status.loadBalancer.ingress[0].hostname') && \
echo $GRAFANA_URL

#
# HCP PORTAL TIME
#

# Go to HCP Portal
https://portal.cloud.hashicorp.com/
# Link an existing self-managed cluster by running through the on-screen config instructions

# Upgrade Consul to enable HCP management plane metrics
consul-k8s upgrade -config-file=helm/consul-v4-hcp-mgmt-plane.yaml
# wait 4-5 mins for upgrade

# Deploy service intentions for the consul-telemetry-collector
kubectl apply --filename config/consul-telemetry-intentions.yaml

# Redeploy HashiCups with updated proxy configurations that configure Envoy to send metrics to the Consul Telemetry Collector
kubectl rollout restart deployment --namespace default

# Give it a couple minutes to sync then check out HCP observability insights for the control plane and data plane

# Check out Consul management via HCP UI (optional)