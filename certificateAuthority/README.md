Install the cfssl and cfssljson from your pkg manager or build from source in this repo: https://github.com/cloudflare/cfssl/releases

Then the sequence of scripts is the following (descriptive script names, if need more details go to https://kubernetes.io/docs/tasks/tls/managing-tls-in-a-cluster/):

createSignRequest.sh
sendCertReqToKube.sh
approveCert.sh
createCA.sh
issueCA.sh
uploadSignedCert.sh


For more details on cert use for kubernets context go the kubernets documentation: https://kubernetes.io/docs/tasks/tls/managing-tls-in-a-cluster/
