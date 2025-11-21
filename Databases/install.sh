helm repo add mysql-operator https://mysql.github.io/mysql-operator/
helm repo update

helm install my-mysql-operator mysql-operator/mysql-operator \
   --namespace mysql-operator --create-namespace
