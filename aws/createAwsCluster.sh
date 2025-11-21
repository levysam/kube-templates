export KOPS_STATE_STORE="s3://sismor-kube-state-store"
export CLUSTER_NAME=sismor
export KOPS_DISCOVERY_STORE="s3://sismor-oidc-store"
export DEPLOY_REGION="us-west-1"
export DEPLOY_ZONE="us-west-1a"
export NAME=${CLUSTER_NAME}.k8s.local

export OIDC_PROVIDER_ID=$(aws iam list-open-id-connect-providers \
    --query "OpenIDConnectProviderList[?contains(Arn, '${NAME}')].Arn" \
    --output text | awk -F'/' '{print $NF}')
export OIDC_ISSUER=${KOPS_OIDC_STORE_NAME}.s3.${DEPLOY_REGION}.amazonaws.com/${NAME}/discovery/${NAME}

export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query 'Account' \
    --output text)

export AWS_INSTANCE_PROFILE_NAME=nodes.${NAME}
export KARPENTER_ROLE_NAME=karpenter.kube-system.sa.${NAME}
export CLUSTER_ENDPOINT=$(kubectl config view -o jsonpath="{.clusters[?(@.name=='${NAME}')].cluster.server}")

# Storage of temporary documents for subsequent needs
export TMP_DIR=$(mktemp -d)

aws iam create-group --group-name kops

aws iam attach-group-policy --policy-arn arn:aws:iam::aws:policy/AmazonEC2FullAccess --group-name kops
aws iam attach-group-policy --policy-arn arn:aws:iam::aws:policy/AmazonRoute53FullAccess --group-name kops
aws iam attach-group-policy --policy-arn arn:aws:iam::aws:policy/AmazonS3FullAccess --group-name kops
aws iam attach-group-policy --policy-arn arn:aws:iam::aws:policy/IAMFullAccess --group-name kops
aws iam attach-group-policy --policy-arn arn:aws:iam::aws:policy/AmazonVPCFullAccess --group-name kops
aws iam attach-group-policy --policy-arn arn:aws:iam::aws:policy/AmazonSQSFullAccess --group-name kops
aws iam attach-group-policy --policy-arn arn:aws:iam::aws:policy/AmazonEventBridgeFullAccess --group-name kops

aws iam create-user --user-name kops
aws iam add-user-to-group --user-name kops --group-name kops
aws iam create-access-key --user-name kops


export AWS_ACCESS_KEY_ID=$(aws configure get aws_access_key_id)
export AWS_SECRET_ACCESS_KEY=$(aws configure get aws_secret_access_key)

export KOPS_STATE_STORE_NAME=kops-state-store-${CLUSTER_NAME}
export KOPS_OIDC_STORE_NAME=kops-oidc-store-${CLUSTER_NAME}
export KOPS_STATE_STORE=s3://${KOPS_STATE_STORE_NAME}

aws s3api create-bucket \
    --bucket ${KOPS_STATE_STORE_NAME} \
    --region ${DEPLOY_REGION} \
    --create-bucket-configuration LocationConstraint=${DEPLOY_REGION}

aws s3api create-bucket \
    --bucket ${KOPS_OIDC_STORE_NAME} \
    --region ${DEPLOY_REGION} \
    --create-bucket-configuration LocationConstraint=${DEPLOY_REGION} \
    --object-ownership BucketOwnerPreferred
aws s3api put-public-access-block \
    --bucket ${KOPS_OIDC_STORE_NAME} \
    --public-access-block-configuration BlockPublicAcls=false,IgnorePublicAcls=false,BlockPublicPolicy=false,RestrictPublicBuckets=false
aws s3api put-bucket-acl \
    --bucket ${KOPS_OIDC_STORE_NAME} \
    --acl public-read

kops create cluster \
    --name=${NAME} \
    --cloud=aws \
    --node-count=1 \
    --control-plane-count=1 \
    --zones=${DEPLOY_ZONE} \
    --discovery-store=s3://${KOPS_OIDC_STORE_NAME}/${NAME}/discovery

kops update cluster --name ${NAME} --yes --admin
kops export kubeconfig
# waiting for Ready
kops validate cluster --wait 10m --name ${NAME}


