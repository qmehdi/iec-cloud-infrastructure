#!/usr/bin/env bash
# Checks that this laptop is ready for the course, and sets up the AWS
# profile that Terraform uses. Safe to run as many times as you like.

set -uo pipefail

COURSE_REGION="us-west-2"
COURSE_PROFILE="course"
LOGIN_PROFILE="${COURSE_LOGIN_PROFILE:-default}"

green=$'\033[32m'; red=$'\033[31m'; yellow=$'\033[33m'; bold=$'\033[1m'; reset=$'\033[0m'
problems=0

ok()   { printf '  %s✓%s %s\n' "$green" "$reset" "$1"; }
bad()  { printf '  %s✗%s %s\n' "$red" "$reset" "$1"; printf '      %s\n' "$2"; problems=$((problems + 1)); }
warn() { printf '  %s!%s %s\n' "$yellow" "$reset" "$1"; [ -n "${2:-}" ] && printf '      %s\n' "$2"; }

# Returns success if version $1 >= version $2 (both like 1.2.3)
version_at_least() {
  local IFS=.
  # shellcheck disable=SC2206  # splitting "1.2.3" on dots is the point
  local have=($1) need=($2) i
  for i in 0 1 2; do
    if [ "${have[i]:-0}" -gt "${need[i]:-0}" ]; then return 0; fi
    if [ "${have[i]:-0}" -lt "${need[i]:-0}" ]; then return 1; fi
  done
  return 0
}

printf '\n%sChecking your tools%s\n' "$bold" "$reset"

if command -v git >/dev/null 2>&1; then
  ok "Git $(git --version | awk '{print $3}')"
else
  bad "Git is not installed" "Follow the install steps in docs/00-setup.md"
fi

if command -v terraform >/dev/null 2>&1; then
  tf_version="$(terraform -version | head -n1 | sed -E 's/^Terraform v([0-9.]+).*/\1/')"
  if version_at_least "$tf_version" "1.10.0"; then
    ok "Terraform $tf_version"
  else
    bad "Terraform $tf_version is too old (need 1.10 or newer)" "Re-run the Terraform install steps in docs/00-setup.md"
  fi
else
  bad "Terraform is not installed" "Follow the install steps in docs/00-setup.md"
fi

aws_ok=0
if command -v aws >/dev/null 2>&1; then
  aws_version="$(aws --version 2>&1 | sed -E 's#^aws-cli/([0-9.]+).*#\1#')"
  if version_at_least "$aws_version" "2.32.0"; then
    ok "AWS CLI $aws_version"
    aws_ok=1
  else
    bad "AWS CLI $aws_version is too old (need 2.32 or newer for 'aws login')" "Re-run the AWS CLI install steps in docs/00-setup.md"
    aws_ok=1
  fi
else
  bad "The AWS CLI is not installed" "Follow the install steps in docs/00-setup.md"
fi

printf '\n%sChecking your AWS sign-in%s\n' "$bold" "$reset"

if [ "$aws_ok" -eq 1 ]; then
  # Terraform reads credentials through a profile called "course". It asks the
  # AWS CLI for fresh credentials whenever it needs them, so your 'aws login'
  # session works for Terraform too.
  if aws configure get credential_process --profile "$COURSE_PROFILE" >/dev/null 2>&1; then
    ok "AWS profile '$COURSE_PROFILE' already set up"
  else
    aws configure set credential_process \
      "aws configure export-credentials --profile $LOGIN_PROFILE --format process" \
      --profile "$COURSE_PROFILE"
    aws configure set region "$COURSE_REGION" --profile "$COURSE_PROFILE"
    ok "Created AWS profile '$COURSE_PROFILE' (Terraform uses this)"
  fi

  if identity="$(aws sts get-caller-identity --profile "$COURSE_PROFILE" --output text --query '[Account,Arn]' 2>/dev/null)"; then
    account="$(printf '%s' "$identity" | awk '{print $1}')"
    arn="$(printf '%s' "$identity" | awk '{print $2}')"
    ok "Signed in to AWS account $account"
    case "$arn" in
      *:root) warn "You're signed in as the root user" "That's OK for this course. Keep your root password safe and turn on MFA." ;;
    esac
  else
    bad "Not signed in to AWS" "Run 'aws login' (or 'aws login --remote' in WSL), then run this check again"
  fi

  region="$(aws configure get region --profile "$COURSE_PROFILE" 2>/dev/null || true)"
  if [ "$region" = "$COURSE_REGION" ]; then
    ok "Region is $COURSE_REGION"
  else
    aws configure set region "$COURSE_REGION" --profile "$COURSE_PROFILE"
    ok "Region set to $COURSE_REGION (was '${region:-not set}')"
  fi
fi

printf '\n%sChecking the course files%s\n' "$bold" "$reset"
repo_root="$(cd "$(dirname "$0")/.." && pwd)"
if [ -d "$repo_root/scripts" ] && [ -f "$repo_root/README.md" ]; then
  ok "Course repo found at $repo_root"
else
  bad "Can't find the course files" "Run this from inside the iec-cloud-infrastructure folder"
fi

echo
if [ "$problems" -eq 0 ]; then
  printf '%s%sAll set! You are ready for class.%s\n\n' "$green" "$bold" "$reset"
else
  printf '%s%s%d thing(s) to fix.%s Follow the hints above, then run this check again.\n\n' "$red" "$bold" "$problems" "$reset"
  exit 1
fi
