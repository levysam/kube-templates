helm repo add kube-prometheus-stack https://prometheus-community.github.io/helm-charts
helm install kube-prometheus-stack oci://ghcr.io/prometheus-community/charts/kube-prometheus-stack
