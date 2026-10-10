#!/usr/bin/env bash
# Puts your Yelp API key into AWS Secrets Manager and restarts the app so it
# picks the key up. Nothing is written to disk and nothing is echoed to the
# screen, so the key never ends up in your shell history or in a screenshot.
#
#   ./scripts/set-yelp-key.sh
#
# Get a free key (30-day trial) at https://fusion.yelp.com

set -uo pipefail

PROFILE="${AWS_PROFILE:-course}"
REGION="${AWS_REGION:-us-west-2}"
SECRET_NAME="${YELP_SECRET_NAME:-course/yelp-api-key}"
INSTANCE_TAG="${APP_INSTANCE_TAG:-course-app}"

green=$'\033[32m'; red=$'\033[31m'; yellow=$'\033[33m'; bold=$'\033[1m'; reset=$'\033[0m'

aws_q() { aws --profile "$PROFILE" --region "$REGION" --output text "$@"; }

die() {
  printf '%s%s%s\n' "$red" "$1" "$reset" >&2
  exit 1
}

# --- 1. Are we signed in? ----------------------------------------------------
if ! aws sts get-caller-identity --profile "$PROFILE" >/dev/null 2>&1; then
  die "Not signed in to AWS. Run 'aws login' first, then try again."
fi

# --- 2. Does the secret exist? -----------------------------------------------
if ! aws_q secretsmanager describe-secret --secret-id "$SECRET_NAME" >/dev/null 2>&1; then
  die "Can't find the secret '$SECRET_NAME'. Run 'terraform apply' in infra/02-database first."
fi

# --- 3. Ask for the key ------------------------------------------------------
printf '\n%sPaste your Yelp API key%s (you will not see it as you type), then press Enter:\n' "$bold" "$reset"
printf '  > '
read -rs YELP_KEY
printf '\n\n'

# Strip any spaces that came along with a copy and paste.
YELP_KEY="${YELP_KEY#"${YELP_KEY%%[![:space:]]*}"}"
YELP_KEY="${YELP_KEY%"${YELP_KEY##*[![:space:]]}"}"

[ -n "$YELP_KEY" ] && [ "${#YELP_KEY}" -ge 20 ] || die "That doesn't look like a Yelp key (they're long). Nothing was changed."

# --- 4. Store it -------------------------------------------------------------
if aws_q secretsmanager put-secret-value \
  --secret-id "$SECRET_NAME" \
  --secret-string "$YELP_KEY" >/dev/null 2>&1; then
  printf '  %s✓%s Key stored in Secrets Manager as %s\n' "$green" "$reset" "$SECRET_NAME"
else
  die "Couldn't store the key. Are you signed in to the right account?"
fi
unset YELP_KEY

# --- 5. Restart the app so it reads the new key -------------------------------
# The app reads its secrets once, when it starts. A new key therefore needs a
# restart. Notice that we are NOT rebuilding the server or changing any code:
# this is a configuration change, and the infrastructure doesn't move.
instance_id="$(aws_q ec2 describe-instances \
  --filters "Name=tag:Name,Values=$INSTANCE_TAG" Name=instance-state-name,Values=running \
  --query 'Reservations[0].Instances[0].InstanceId' 2>/dev/null)"

if [ -z "$instance_id" ] || [ "$instance_id" = "None" ]; then
  printf '  %s!%s No running app server found, so nothing to restart.\n' "$yellow" "$reset"
  printf '      The key is saved. Run this again, or restart the app yourself, once the server is up.\n\n'
  exit 0
fi

command_id="$(aws_q ssm send-command \
  --instance-ids "$instance_id" \
  --document-name "AWS-RunShellScript" \
  --comment "Restart Neighborhood Eats to pick up the new Yelp key" \
  --parameters 'commands=["systemctl restart neighborhood-eats"]' \
  --query 'Command.CommandId' 2>/dev/null)"

if [ -z "$command_id" ] || [ "$command_id" = "None" ]; then
  printf '  %s!%s Couldn'\''t send the restart command.\n' "$yellow" "$reset"
  printf '      Restart it yourself: aws ssm start-session --target %s --profile %s --region %s\n' \
    "$instance_id" "$PROFILE" "$REGION"
  printf '      then run: sudo systemctl restart neighborhood-eats\n\n'
  exit 0
fi

printf '  %s✓%s Asked %s to restart the app\n' "$green" "$reset" "$instance_id"

# Wait for the restart to actually finish, so students don't reload too early.
for _ in $(seq 1 20); do
  status="$(aws_q ssm get-command-invocation \
    --command-id "$command_id" --instance-id "$instance_id" \
    --query 'Status' 2>/dev/null)"
  case "$status" in
    Success)
      printf '  %s✓%s App restarted\n\n' "$green" "$reset"
      printf '%sReload the site. The search bar is now there.%s\n\n' "$bold" "$reset"
      exit 0
      ;;
    Failed|Cancelled|TimedOut)
      printf '  %s!%s The restart reported "%s". Check the server with Session Manager.\n\n' \
        "$yellow" "$reset" "$status"
      exit 0
      ;;
  esac
  sleep 3
done

printf '  %s!%s Still restarting. Give it a few seconds, then reload the site.\n\n' "$yellow" "$reset"
