#!/usr/bin/env bash
# shellcheck disable=SC2016  # the backticks below are AWS query syntax, not shell
# Lists anything in your AWS account that costs money while it runs.
# Run it at the end of every class. You want to see "Nothing billable running".

set -uo pipefail

PROFILE="${AWS_PROFILE:-course}"
REGION="${AWS_REGION:-us-west-2}"
aws_q() { aws --profile "$PROFILE" --region "$REGION" --output text "$@" 2>/dev/null; }

green=$'\033[32m'; yellow=$'\033[33m'; red=$'\033[31m'; bold=$'\033[1m'; reset=$'\033[0m'
found=0

if ! aws sts get-caller-identity --profile "$PROFILE" >/dev/null 2>&1; then
  printf '%sNot signed in to AWS.%s Run '\''aws login'\'' first, then try again.\n' "$red" "$reset"
  exit 1
fi

# Prints a section if the AWS query returned anything.
#   $1 = label, $2 = what it costs, rest = the aws command
check() {
  local label="$1" cost="$2"; shift 2
  local result
  result="$(aws_q "$@" | sed '/^None$/d;/^$/d')"
  if [ -n "$result" ]; then
    found=$((found + 1))
    printf '  %s!%s %s%s%s  (%s)\n' "$yellow" "$reset" "$bold" "$label" "$reset" "$cost"
    printf '%s\n' "$result" | sed 's/^/      /'
  fi
}

printf '\n%sChecking %s for anything that costs money...%s\n\n' "$bold" "$REGION" "$reset"

check "NAT gateways" "a few cents per hour" \
  ec2 describe-nat-gateways --filter Name=state,Values=pending,available \
  --query 'NatGateways[].[NatGatewayId,Tags[?Key==`Name`]|[0].Value]'
check "Elastic IP addresses" "about half a cent per hour each" \
  ec2 describe-addresses --query 'Addresses[].[PublicIp,Tags[?Key==`Name`]|[0].Value]'
check "EC2 servers" "about a cent per hour each" \
  ec2 describe-instances --filters Name=instance-state-name,Values=pending,running,stopping \
  --query 'Reservations[].Instances[].[InstanceId,InstanceType,Tags[?Key==`Name`]|[0].Value]'
check "Databases (RDS)" "a couple of cents per hour" \
  rds describe-db-instances --query 'DBInstances[].[DBInstanceIdentifier,DBInstanceStatus]'
check "Load balancers" "a few cents per hour" \
  elbv2 describe-load-balancers --query 'LoadBalancers[].[LoadBalancerName,State.Code]'

# Containers (Week 5): clusters are free, running tasks are not.
for cluster in $(aws_q ecs list-clusters --query 'clusterArns[]' | sed '/^None$/d'); do
  running="$(aws_q ecs list-tasks --cluster "$cluster" --desired-status RUNNING --query 'length(taskArns)')"
  if [ -n "$running" ] && [ "$running" != "0" ]; then
    found=$((found + 1))
    printf '  %s!%s %sRunning containers (ECS)%s  (a few cents per hour per copy)\n' "$yellow" "$reset" "$bold" "$reset"
    printf '      %s: %s running\n' "${cluster##*/}" "$running"
  fi
done

vpcs="$(aws_q ec2 describe-vpcs --filters Name=tag:Project,Values=cloud-devops-course --query 'Vpcs[].VpcId')"
bucket="$(aws_q s3api list-buckets --query 'Buckets[?starts_with(Name, `tfstate-`)].Name')"

echo
if [ "$found" -eq 0 ]; then
  printf '%s%s✓ Nothing billable running.%s You'\''re all set.\n' "$green" "$bold" "$reset"
else
  printf '%s%s%d kind(s) of resource still running.%s\n' "$yellow" "$bold" "$found" "$reset"
  printf 'If class is over, run '\''terraform destroy'\'' in each infra folder you used (newest first).\n'
fi

echo
printf 'Free to keep (these cost nothing or close to it):\n'
[ -n "$vpcs" ]   && printf '  - Course VPC: %s (free, but we destroy it anyway at the end of class)\n' "$vpcs"
[ -n "$bucket" ] && printf '  - State bucket: %s (pennies per year; keep it until the last week)\n' "$bucket"
printf '  - Budget alarm (the first two budgets in an account are free)\n\n'
