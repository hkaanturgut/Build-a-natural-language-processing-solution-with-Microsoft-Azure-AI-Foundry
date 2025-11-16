import os
from azure.ai.textanalytics import TextAnalyticsClient
from azure.core.credentials import AzureKeyCredential
from dotenv import load_dotenv

# Load environment variables from .env file
load_dotenv()

# Get Azure AI Services configuration from environment
ENDPOINT = os.getenv("AZURE_AI_SERVICES_ENDPOINT") or os.getenv("ENDPOINT")
KEY = os.getenv("AZURE_AI_SERVICES_KEY") or os.getenv("KEY")

if not ENDPOINT or not KEY:
    raise ValueError(
        "Missing Azure AI Services configuration. "
        "Please ensure AZURE_AI_SERVICES_ENDPOINT and AZURE_AI_SERVICES_KEY are set in your .env file. "
        "Run 'terraform apply' in the infra directory to generate the .env file automatically."
    )

def get_client():
    return TextAnalyticsClient(
        endpoint=ENDPOINT,
        credential=AzureKeyCredential(KEY)
    )

def redact_text(client, text: str) -> None:
    response = client.recognize_pii_entities([text], language="en")
    doc = response[0]

    print("Original:")
    print(text)
    print("\nDetected PII entities:")
    for ent in doc.entities:
        print(f"- {ent.text} | category={ent.category} | score={ent.confidence_score:.2f}")

    print("\nRedacted text:")
    print(doc.redacted_text)
    print("-" * 60)

if __name__ == "__main__":
    client = get_client()
    with open("../data/pii_samples.txt", encoding="utf-8") as f:
        content = f.read().strip().split("\n\n")

    for chunk in content:
        redact_text(client, chunk)
