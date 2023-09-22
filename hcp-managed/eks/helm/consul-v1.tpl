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

externalServers:
  enabled: true
  hosts: [${consul_hosts}]
  httpsPort: 443
  useSystemRoots: true
  k8sAuthMethodHost: ${k8s_api_endpoint}

# Configures values that configure the Consul server cluster.
server:
  enabled: false

# Configures and installs the automatic Consul Connect sidecar injector.
connectInject:
  enabled: true
  # Configures and installs the Consul API Gateway.
  apiGateway:
    manageExternalCRDs: true
    # Configuration settings for the GatewayClass
    managedGatewayClass:
      # Defines the type of service created for gateways (e.g. LoadBalancer, ClusterIP, NodePort)
      # LoadBalancer is primarily used for cloud deployments.
      serviceType: LoadBalancer