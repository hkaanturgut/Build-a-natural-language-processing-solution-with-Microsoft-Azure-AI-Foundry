# Set variables
SUBSCRIPTION_ID="52513787-3db1-4afb-845e-922fd437040e"
SPN_CLIENT_ID="cfbe9921-267a-4f31-87bf-c5771971c029"

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