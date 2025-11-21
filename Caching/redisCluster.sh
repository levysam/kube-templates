
helm repo add valkey https://valkey.io/valkey-helm/
helm install redis valkey/valkey \
  --set cluster.nodes=3 \
  --set persistence.storageClass=kops-ssd-1-17 \
  --set persistence.size=5Gi \
  -n redis-cluster --create-namespace
