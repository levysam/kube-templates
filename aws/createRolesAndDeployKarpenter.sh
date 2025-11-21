export KOPS_STATE_STORE="s3://sismor-kube-state-store"
export CLUSTER_NAME=sismor
export KOPS_DISCOVERY_STORE="s3://sismor-oidc-store"
export DEPLOY_REGION="us-west-1"
export DEPLOY_ZONE="us-west-1a"
export NAME=${CLUSTER_NAME}.k8s.local

export KOPS_STATE_STORE_NAME=kops-state-store-${CLUSTER_NAME}
export KOPS_OIDC_STORE_NAME=kops-oidc-store-${CLUSTER_NAME}
export KOPS_STATE_STORE=s3://${KOPS_STATE_STORE_NAME}

export OIDC_PROVIDER_ID=$(aws iam list-open-id-connect-providers \
    --query "OpenIDConnectProviderList[?contains(Arn, '${NAME}')].Arn" \
    --output text | awk -F'/' '{print $NF}')
export OIDC_ISSUER=${KOPS_OIDC_STORE_NAME}.s3.${DEPLOY_REGION}.amazonaws.com/${NAME}/discovery/${NAME}

export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query 'Account' \
    --output text)

export AWS_INSTANCE_PROFILE_NAME=nodes.${NAME}
export KARPENTER_ROLE_NAME=karpenter.kube-system.sa.${NAME}
export CLUSTER_ENDPOINT=$(kubectl config view -o jsonpath="{.clusters[?(@.name=='${NAME}')].cluster.server}")

export AWS_INSTANCE_PROFILE_NAME=nodes.${NAME}
export KARPENTER_ROLE_NAME=karpenter.kube-system.sa.${NAME}
export CLUSTER_ENDPOINT=$(kubectl config view -o jsonpath="{.clusters[?(@.name=='${NAME}')].cluster.server}")

# Storage of temporary documents for subsequent needs
export TMP_DIR=$(mktemp -d)

aws iam create-role \
    --role-name ${KARPENTER_ROLE_NAME} \
    --assume-role-policy-document "{
        \"Version\": \"2012-10-17\",
        \"Statement\": [
            {
                \"Effect\": \"Allow\",
                \"Principal\": {
                    \"Federated\": \"arn:aws:iam::${AWS_ACCOUNT_ID}:oidc-provider/${KOPS_OIDC_STORE_NAME}.s3.us-west-1.amazonaws.com/${NAME}/discovery/${NAME}\"
                },
                \"Action\": \"sts:AssumeRoleWithWebIdentity\",
                \"Condition\": {
                    \"StringEquals\": {
                        \"${OIDC_ISSUER}:sub\": \"system:serviceaccount:kube-system:karpenter\"
                    }
                }
            }
        ]
    }"

aws iam put-role-policy \
    --role-name ${KARPENTER_ROLE_NAME} \
    --policy-name InlineKarpenterPolicy \
    --policy-document '{
        "Version": "2012-10-17",
        "Statement": [
            {
                "Effect": "Allow",
                "Action": [
                    "ec2:CreateFleet",
                    "ec2:CreateTags",
                    "ec2:DescribeAvailabilityZones",
                    "ec2:DescribeImages",
                    "ec2:DescribeInstanceTypeOfferings",
                    "ec2:DescribeInstanceTypes",
                    "ec2:DescribeInstances",
                    "ec2:DescribeLaunchTemplates",
                    "ec2:DescribeSecurityGroups",
                    "ec2:DescribeSpotPriceHistory",
                    "ec2:DescribeSubnets",
                    "ec2:RunInstances",
                    "ec2:TerminateInstances",
                    "iam:PassRole",
                    "pricing:GetProducts",
                    "ssm:GetParameter",
                    "ec2:CreateLaunchTemplate",
                    "ec2:DeleteLaunchTemplate",
                    "sts:AssumeRoleWithWebIdentity"
                ],
                "Resource": "*"
            }
        ]
    }'


cat <<EOF > ${TMP_DIR}/values.yaml
serviceAccount:
  annotations:
    "eks.amazonaws.com/role-arn": "arn:aws:iam::${AWS_ACCOUNT_ID}:role/${KARPENTER_ROLE_NAME}"

replicas: 1

affinity:
  nodeAffinity:
    requiredDuringSchedulingIgnoredDuringExecution:
      nodeSelectorTerms:
        - matchExpressions:
            - key: node-role.kubernetes.io/control-plane
              operator: Exists
  podAntiAffinity:
    requiredDuringSchedulingIgnoredDuringExecution:
      - topologyKey: "kubernetes.io/hostname"

tolerations:
  - key: CriticalAddonsOnly
    operator: Exists
  - key: node-role.kubernetes.io/master
    operator: Exists
  - key: node-role.kubernetes.io/control-plane
    operator: Exists
  - effect: NoExecute
    key: node.kubernetes.io/not-ready
    operator: Exists
    tolerationSeconds: 300
  - effect: NoExecute
    key: node.kubernetes.io/unreachable
    operator: Exists
    tolerationSeconds: 300

extraVolumes:
  - name: token-amazonaws-com
    projected:
      defaultMode: 420
      sources:
        - serviceAccountToken:
            audience: amazonaws.com
            expirationSeconds: 86400
            path: token

controller:
  image:
    repository: public.ecr.aws/karpenter/karpenter
    tag: 1.8.0
  env:
    - name: AWS_REGION
      value: us-west-1
    - name: AWS_DEFAULT_REGION
      value: us-west-1
    - name: AWS_ROLE_ARN
      value: arn:aws:iam::${AWS_ACCOUNT_ID}:role/${KARPENTER_ROLE_NAME}
    - name: AWS_WEB_IDENTITY_TOKEN_FILE
      value: /var/run/secrets/amazonaws.com/token
  extraVolumeMounts:
    - mountPath: /var/run/secrets/amazonaws.com/
      name: token-amazonaws-com
      readOnly: true
  featureGates:
    SpotToSpotConsolidation: true
    NodeRepair: false

logLevel: debug

settings:
  clusterName: ${NAME}
  clusterEndpoint: ${CLUSTER_ENDPOINT}
EOF


export KARPENTER_NAMESPACE="kube-system"

helm upgrade --install karpenter oci://public.ecr.aws/karpenter/karpenter --version 1.8.2 \
  --namespace "kube-system" \
  --wait -f $TMP_DIR/values.yaml \
  --skip-crds


