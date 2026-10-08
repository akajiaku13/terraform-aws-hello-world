#!/usr/bin/env bash
set -euo pipefail
: "${INSTANCE_ID:?}" "${ARTIFACT_BUCKET:?}" "${ARTIFACT_KEY:?}" "${AWS_REGION:?}"
PARAMS=$(jq -nc --arg b "$ARTIFACT_BUCKET" --arg k "$ARTIFACT_KEY" '{commands:[
"set -euo pipefail",
"for i in $(seq 1 60); do [ -f /var/www/.provisioned ] && break; sleep 5; done",
"test -f /var/www/.provisioned",
("aws s3 cp s3://"+$b+"/"+$k+" /tmp/app.zip"),
"release=/var/www/releases/$(date +%Y%m%d%H%M%S)",
"mkdir -p $release",
"unzip -q /tmp/app.zip -d $release",
"test -f $release/index.html",
"test -f $release/health.txt",
"if [ -L /var/www/current ]; then readlink -f /var/www/current > /var/www/previous-release; elif [ -d /var/www/current ]; then mv /var/www/current /var/www/releases/bootstrap; echo /var/www/releases/bootstrap > /var/www/previous-release; fi",
"ln -sfn $release /var/www/current",
"nginx -t",
"systemctl reload nginx",
"curl -fsS http://localhost/health.txt | grep -qx OK"
]}')
COMMAND_ID=$(aws ssm send-command --region "$AWS_REGION" --instance-ids "$INSTANCE_ID" --document-name AWS-RunShellScript --comment "Deploy $ARTIFACT_KEY" --parameters "$PARAMS" --query 'Command.CommandId' --output text)
aws ssm wait command-executed --region "$AWS_REGION" --command-id "$COMMAND_ID" --instance-id "$INSTANCE_ID" || true
STATUS=$(aws ssm get-command-invocation --region "$AWS_REGION" --command-id "$COMMAND_ID" --instance-id "$INSTANCE_ID" --query Status --output text)
aws ssm get-command-invocation --region "$AWS_REGION" --command-id "$COMMAND_ID" --instance-id "$INSTANCE_ID" --query '[StandardOutputContent,StandardErrorContent]' --output text
[[ "$STATUS" == "Success" ]]
