kubectl get csr my-svc.my-namespace -o jsonpath='{.spec.request}' | \
  base64 --decode | \
  cfssl sign -ca ca.pem -ca-key ca-key.pem -config tls/server-signing-config.json - | \
  cfssljson -bare ca-signed-server
