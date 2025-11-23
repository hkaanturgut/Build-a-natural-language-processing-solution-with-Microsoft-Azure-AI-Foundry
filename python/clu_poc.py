import sys
from azure.core.credentials import AzureKeyCredential
from azure.ai.language.conversations import ConversationAnalysisClient
from azure.identity import DefaultAzureCredential
from azure.keyvault.secrets import SecretClient

# Bootstrap: get Key Vault URI from a well-known secret
BOOTSTRAP_KEY_VAULT_URI = "https://kv-nlp-dev-eus2-001.vault.azure.net/"  # Only for first fetch
credential = DefaultAzureCredential()
bootstrap_client = SecretClient(vault_url=BOOTSTRAP_KEY_VAULT_URI, credential=credential)
key_vault_uri = bootstrap_client.get_secret("key-vault-uri").value

# Now use the discovered Key Vault URI for all other secrets
client_kv = SecretClient(vault_url=key_vault_uri, credential=credential)
ENDPOINT = client_kv.get_secret("ai-services-endpoint").value
KEY = client_kv.get_secret("ai-services-key").value
PROJECT_NAME = "galaxyOrderAssistant"
DEPLOYMENT_NAME = "galaxyOrderAssistant"

CONFIDENCE_THRESHOLD = 0.80

def main():
    # Take query from CLI or use default
    if len(sys.argv) > 1:
        query = sys.argv[1]
    else:
        query = "I need a new plasma cutter"

    client = ConversationAnalysisClient(ENDPOINT, AzureKeyCredential(KEY))

    with client:
        result = client.analyze_conversation(
            task={
                "kind": "Conversation",
                "analysisInput": {
                    "conversationItem": {
                        "participantId": "1",
                        "id": "1",
                        "modality": "text",
                        "language": "en",
                        "text": query,
                    },
                    "isLoggingEnabled": False,
                },
                "parameters": {
                    "projectName": PROJECT_NAME,
                    "deploymentName": DEPLOYMENT_NAME,
                    "verbose": True,
                },
            }
        )

    prediction = result["result"]["prediction"]

    print(f"\nUser: {query}")
    print("\nIntents (confidence > 0.8):")
    for intent in prediction["intents"]:
        if intent["confidenceScore"] > CONFIDENCE_THRESHOLD:
            print(f"  - {intent['category']} ({intent['confidenceScore']:.2f})")

    print("\nEntities:")
    for entity in prediction["entities"]:
        print(f"  - {entity['category']}: {entity['text']} ({entity['confidenceScore']:.2f})")

if __name__ == "__main__":
    main()
