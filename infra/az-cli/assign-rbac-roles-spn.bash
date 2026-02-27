# Set variables
SUBSCRIPTION_ID="52513787-3db1-4afb-845e-922fd437040e"
SPN_CLIENT_ID="9d2cd39a-a347-4664-a9d0-6c1bf7c597c8"

# 1. Contributor
az role assignment create \
  --assignee "$SPN_CLIENT_ID" \
  --role "Contributor" \
  --scope "/subscriptions/$SUBSCRIPTION_ID"

# 2. User Access Administrator
az role assignment create \
  --assignee "$SPN_CLIENT_ID" \
  --role "User Access Administrator" \
  --scope "/subscriptions/$SUBSCRIPTION_ID"

# 3. Key Vault Secrets Officer
az role assignment create \
  --assignee "$SPN_CLIENT_ID" \
  --role "Key Vault Secrets Officer" \
  --scope "/subscriptions/$SUBSCRIPTION_ID"