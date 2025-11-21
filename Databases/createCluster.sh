helm install mycluster mysql-operator/mysql-innodbcluster \
   --set tls.useSelfSigned=true --values credentials.yaml -n mysql --create-namespace
