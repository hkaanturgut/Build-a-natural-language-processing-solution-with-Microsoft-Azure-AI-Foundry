

from dotenv import load_dotenv
import os
from azure.identity import DefaultAzureCredential
from azure.keyvault.secrets import SecretClient
from azure.ai.textanalytics import TextAnalyticsClient
from azure.core.credentials import AzureKeyCredential

# Load environment variables from .env file
load_dotenv()
BOOTSTRAP_KEY_VAULT_URI = os.getenv("KEY_VAULT_URI")
credential = DefaultAzureCredential()
bootstrap_client = SecretClient(vault_url=BOOTSTRAP_KEY_VAULT_URI, credential=credential)
key_vault_uri = bootstrap_client.get_secret("key-vault-uri").value

# Now use the discovered Key Vault URI for all other secrets
client_kv = SecretClient(vault_url=key_vault_uri, credential=credential)
gpt_5_chat_key = client_kv.get_secret("gpt-5-chat-key").value
gpt_5_chat_endpoint = client_kv.get_secret("gpt-5-chat-endpoint").value

def authenticate_client():
    ta_credential = AzureKeyCredential(gpt_5_chat_key)
    text_analytics_client = TextAnalyticsClient(
        endpoint=gpt_5_chat_endpoint,
        credential=ta_credential)
    return text_analytics_client

client = authenticate_client()

# Example function for recognizing entities from text
def entity_recognition_example(client):
    try:
        documents = ["I had a wonderful trip to Seattle last week."]
        result = client.recognize_entities(documents = documents)[0]

        print("Named Entities:\n")
        for entity in result.entities:
            print("\tText: \t", entity.text, "\tCategory: \t", entity.category, "\tSubCategory: \t", entity.subcategory,
                    "\n\tConfidence Score: \t", round(entity.confidence_score, 2), "\tLength: \t", entity.length, "\tOffset: \t", entity.offset, "\n")

    except Exception as err:
        print("Encountered exception. {}".format(err))

entity_recognition_example(client)