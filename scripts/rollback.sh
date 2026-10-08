#!/usr/bin/env bash
set -euo pipefail
: "${INSTANCE_ID:?}" "${AWS_REGION:?}"
PARAMS=$(jq -nc '{commands:["set -euo pipefail","previous=$(cat /var/www/previous-release)","test -d $previous","ln -sfn $previous /var/www/current","nginx -t","systemctl reload nginx","curl -fsS http://localhost/health.txt | grep -qx OK"]}')
COMMAND_ID=$(aws ssm send-command --region "$AWS_REGION" --instance-ids "$INSTANCE_ID" --document-name AWS-RunShellScript --comment "Automatic rollback" --parameters "$PARAMS" --query 'Command.CommandId' --output text)
aws ssm wait command-executed --region "$AWS_REGION" --command-id "$COMMAND_ID" --instance-id "$INSTANCE_ID" || true
STATUS=$(aws ssm get-command-invocation --region "$AWS_REGION" --command-id "$COMMAND_ID" --instance-id "$INSTANCE_ID" --query Status --output text)
aws ssm get-command-invocation --region "$AWS_REGION" --command-id "$COMMAND_ID" --instance-id "$INSTANCE_ID" --query '[StandardOutputContent,StandardErrorContent]' --output text
echo "Rollback status: $STATUS"
[[ "$STATUS" == "Success" ]]
