global:
  # The main enabled/disabled setting.
  # If true, servers, clients, Consul DNS and the Consul UI will be enabled.
  enabled: false
  # The prefix used for all resources created in the Helm chart.
  name: consul
  # The consul image version.
  image: "hashicorp/consul-enterprise:${consul_version}-ent"
  # The name of the datacenter that the agents should register as.
  datacenter: ${datacenter}
  # Enables ACLs across the cluster to secure access to data and APIs.
  acls:
    # If true, automatically manage ACL tokens and policies for all Consul components.
    manageSystemACLs: true
    bootstrapToken:
      secretName: bootstrap-token
      secretKey: token
  # Enables TLS across the cluster to verify authenticity of the Consul servers and clients.
  tls:
    enabled: true
  # Exposes Prometheus metrics for the Consul service mesh and sidecars.
  metrics:
    enabled: true
    # Enables Consul servers and clients metrics.
    enableAgentMetrics: true
    # Configures the retention time for metrics in Consul servers and clients.
    agentMetricsRetentionTime: "1m"

# Configuration for Consul servers when the servers are running outside of Kubernetes.
externalServers:
  enabled: true
  hosts: [${consul_hosts}]
  httpsPort: 443
  useSystemRoots: true
  k8sAuthMethodHost: ${k8s_api_endpoint}

# Server, when enabled, configures a server cluster to run. This should be disabled if you plan on connecting to a Consul cluster external to the Kubernetes cluster.
server:
  enabled: false

# Configures the automatic Connect sidecar injector.
connectInject:
  enabled: true
  # Enables metrics for Consul Connect sidecars.
  metrics:
    defaultEnabled: true
  # Configuration settings for the Consul transparent proxy.
  transparentProxy:
    defaultEnabled: true
  # Configuration settings for the Consul API Gateway integration.
  apiGateway:
    manageExternalCRDs: true
    managedGatewayClass:
      serviceType: LoadBalancer
  default: true