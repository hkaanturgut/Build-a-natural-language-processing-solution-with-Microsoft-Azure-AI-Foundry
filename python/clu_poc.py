import sys
from azure.core.credentials import AzureKeyCredential
from azure.ai.language.conversations import ConversationAnalysisClient
from dotenv import load_dotenv

# Load environment variables from .env file
load_dotenv()

ENDPOINT = os.getenv("AZURE_AI_SERVICES_ENDPOINT") or os.getenv("ENDPOINT")
KEY = os.getenv("AZURE_AI_SERVICES_KEY") or os.getenv("KEY")
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
