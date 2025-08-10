#!/usr/bin/env bash
set -euo pipefail

# Toggle to pull 7-day Lambda invocation metrics (slower):
INCLUDE_METRICS="${INCLUDE_METRICS:-0}"

ACCOUNT_ID="$(aws sts get-caller-identity --query Account --output text 2>/dev/null || echo unknown)"
START="$(date -u -d '7 days ago' +%FT%TZ)"
END="$(date -u +%FT%TZ)"

# CSV headers
echo "Account,Region,FunctionName,Runtime,Architectures,MemoryMB,Timeout,EphemeralMB,LastModified,HasVPC,Subnets,SecurityGroups,Role,PackageType,ImageUri,RecentInvocations7d" > lambda_inventory.csv
echo "Account,Region,TableName,BillingMode,ReadCapacity,WriteCapacity,ItemCount,TableSizeBytes,PITR,StreamEnabled,StreamViewType,GlobalTableReplicas" > dynamodb_inventory.csv

regions=$(aws ec2 describe-regions --query "Regions[].RegionName" --output text)

for region in $regions; do
  echo "=== Region: $region ==="

  #############
  # LAMBDA
  #############
  echo "--- Lambda functions ---"
  funcs_json=$(aws lambda list-functions --region "$region" --output json | jq -c '.Functions[]?')
  if [[ -z "$funcs_json" ]]; then
    echo "(none)"
  else
    # Pretty table to terminal
    aws lambda list-functions --region "$region" \
      --query "Functions[].{Name:FunctionName,Runtime:Runtime,Arch:join(',',Architectures),Mem:MemorySize,Timeout:Timeout,LastMod:LastModified,VPC:VpcConfig!=null}" \
      --output table

    # CSV rows
    while IFS= read -r f; do
      name=$(jq -r '.FunctionName' <<<"$f")
      runtime=$(jq -r '.Runtime // "-" ' <<<"$f")
      arch=$(jq -r '( .Architectures // [] ) | join("|")' <<<"$f")
      mem=$(jq -r '.MemorySize // 0' <<<"$f")
      timeout=$(jq -r '.Timeout // 0' <<<"$f")
      eph=$(jq -r '.EphemeralStorage.Size // 512' <<<"$f")
      lastmod=$(jq -r '.LastModified // "-" ' <<<"$f")
      hasvpc=$(jq -r 'has("VpcConfig") and (.VpcConfig.SubnetIds|length>0)' <<<"$f")
      subnets=$(jq -r '(.VpcConfig.SubnetIds // []) | join("|")' <<<"$f")
      sgs=$(jq -r '(.VpcConfig.SecurityGroupIds // []) | join("|")' <<<"$f")
      role=$(jq -r '.Role // "-" ' <<<"$f")
      pkg=$(jq -r '.PackageType // "Zip"' <<<"$f")
      image=$(jq -r '.ImageConfigResponse.ImageUri // "-" ' <<<"$f" 2>/dev/null || echo "-")
      inv=""

      if [[ "$INCLUDE_METRICS" == "1" ]]; then
        inv=$(aws cloudwatch get-metric-statistics \
          --region "$region" \
          --namespace AWS/Lambda \
          --metric-name Invocations \
          --dimensions Name=FunctionName,Value="$name" \
          --statistics Sum \
          --period 86400 \
          --start-time "$START" \
          --end-time "$END" \
          --query 'Datapoints[].Sum' --output text 2>/dev/null | awk '{s+=$1} END{print s+0}')
      else
        inv="-"
      fi

      printf "%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s\n" \
        "$ACCOUNT_ID" "$region" "$name" "$runtime" "$arch" "$mem" "$timeout" "$eph" "$lastmod" \
        "$hasvpc" "$subnets" "$sgs" "$role" "$pkg" "$image" "$inv" >> lambda_inventory.csv
    done <<<"$funcs_json"
  fi

  #############
  # DYNAMODB
  #############
  echo "--- DynamoDB tables ---"
  tables=$(aws dynamodb list-tables --region "$region" --query 'TableNames[]' --output text 2>/dev/null || true)
  if [[ -z "${tables:-}" ]]; then
    echo "(none)"
  else
    # Pretty table to terminal
    for t in $tables; do
      desc=$(aws dynamodb describe-table --region "$region" --table-name "$t")
      billing=$(jq -r '.Table.BillingModeSummary.BillingMode // (if .Table.ProvisionedThroughput.ReadCapacityUnits then "PROVISIONED" else "PAY_PER_REQUEST" end)' <<<"$desc")
      rcu=$(jq -r '(.Table.ProvisionedThroughput.ReadCapacityUnits // 0)' <<<"$desc")
      wcu=$(jq -r '(.Table.ProvisionedThroughput.WriteCapacityUnits // 0)' <<<"$desc")
      items=$(jq -r '.Table.ItemCount' <<<"$desc")
      size=$(jq -r '.Table.TableSizeBytes' <<<"$desc")
      replicas=$(jq -r '(.Table.Replicas // []) | map(.RegionName) | join("|")' <<<"$desc")
      streamEnabled=$(jq -r '.Table.StreamSpecification.StreamEnabled // false' <<<"$desc")
      streamView=$(jq -r '.Table.StreamSpecification.StreamViewType // "-" ' <<<"$desc")

      # PITR status
      pitr=$(aws dynamodb describe-continuous-backups --region "$region" --table-name "$t" \
              --query 'ContinuousBackupsDescription.PointInTimeRecoveryDescription.PointInTimeRecoveryStatus' --output text 2>/dev/null || echo "UNKNOWN")

      printf "Table: %-40s  Mode: %-16s  R/W: %4s/%-4s  Items: %-10s  Size(B): %-12s  PITR: %-8s  Stream: %-5s\n" \
        "$t" "$billing" "$rcu" "$wcu" "$items" "$size" "$pitr" "$streamEnabled"

      printf "%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s\n" \
        "$ACCOUNT_ID" "$region" "$t" "$billing" "$rcu" "$wcu" "$items" "$size" "$pitr" "$streamEnabled" "$streamView" >> dynamodb_inventory.csv
    done
  fi

  echo
done

echo "Done."
echo "CSV outputs:"
echo " - $(pwd)/lambda_inventory.csv"
echo " - $(pwd)/dynamodb_inventory.csv"
