node_prefix "" {
   policy = "read"
}
service_prefix "" {
   policy = "read"
}
agent "consul-server-1" {
  policy = "read"
}
agent "consul-server-2" {
  policy = "read"
}
agent "consul-server-3" {
  policy = "read"
}