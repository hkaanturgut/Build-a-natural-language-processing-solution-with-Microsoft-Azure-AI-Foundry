


from dotenv import load_dotenv
import os
import csv
from datetime import datetime
from azure.identity import DefaultAzureCredential
from azure.keyvault.secrets import SecretClient
from azure.storage.blob import BlobServiceClient
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
storage_connection_string = client_kv.get_secret("storage-connection-string").value

def authenticate_client():
    ta_credential = AzureKeyCredential(gpt_5_chat_key)
    text_analytics_client = TextAnalyticsClient(
        endpoint=gpt_5_chat_endpoint,
        credential=ta_credential)
    return text_analytics_client

client = authenticate_client()

# Fetch invoice files from Azure Storage
def fetch_invoices_from_storage(container_name="invoices", blob_name="invoices.txt"):
    blob_service_client = BlobServiceClient.from_connection_string(storage_connection_string)
    container_client = blob_service_client.get_container_client(container_name)
    blob_client = container_client.get_blob_client(blob_name)
    invoices_data = blob_client.download_blob().readall().decode("utf-8")
    # Split by document separator if needed, here assuming one invoice per line
    invoices = [line for line in invoices_data.splitlines() if line.strip()]
    return invoices

# Define custom entities for extraction
CUSTOM_ENTITIES = [
    "InvoiceNumber",
    "ClientName",
    "ItemName",
    "PriceAmount"
]

def entity_recognition_example(client, documents):
    print("Step 1: Starting entity extraction from invoice documents...")
    batch_size = 5
    csv_rows = []
    for i in range(0, len(documents), batch_size):
        try:
            print(f"  Processing batch {i//batch_size + 1} (documents {i+1} to {min(i+batch_size, len(documents))})...")
            batch = documents[i:i+batch_size]
            results = client.recognize_entities(documents=batch)
            for idx, result in enumerate(results):
                doc_num = i + idx + 1
                for entity in result.entities:
                    print(f"    Extracted entity: {entity.text} (Type: {entity.category}, Confidence: {entity.confidence_score * 100:.2f}%)")
                    tags = [entity.category]
                    if entity.subcategory:
                        tags.append(entity.subcategory)
                    tags_str = ", ".join([f"{tag} ({entity.confidence_score * 100:.0f}%)" for tag in tags])
                    metadata_name = "Integer" if entity.category.lower() == "number" else ""
                    metadata_value = entity.text if entity.category.lower() == "number" else ""
                    csv_rows.append({
                        "Document Number": doc_num,
                        "Entity Text": entity.text,
                        "Type": entity.category,
                        "Offset": entity.offset,
                        "Length": entity.length,
                        "Confidence": f"{entity.confidence_score * 100:.2f}%",
                        "Tags": tags_str,
                        "Metadata Name": metadata_name,
                        "Metadata Value": metadata_value
                    })
        except Exception as err:
            print(f"  Encountered exception in batch {i//batch_size + 1}: {err}")

    print("Step 2: Writing extracted entities to CSV file...")
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    csv_file = f"entity_extraction_results_{timestamp}.csv"
    with open(csv_file, mode="w", newline='', encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=[
            "Document Number", "Entity Text", "Type", "Offset", "Length", "Confidence", "Tags", "Metadata Name", "Metadata Value"
        ])
        writer.writeheader()
        writer.writerows(csv_rows)
    print(f"  Entity extraction results exported to {csv_file}")

    print("Step 3: Uploading CSV report to Azure Storage container 'reports'...")
    try:
        blob_service_client = BlobServiceClient.from_connection_string(storage_connection_string)
        reports_container = "reports"
        blob_client = blob_service_client.get_blob_client(container=reports_container, blob=csv_file)
        with open(csv_file, "rb") as data:
            blob_client.upload_blob(data, overwrite=True)
        print(f"  CSV report uploaded to Azure Storage container '{reports_container}' as '{csv_file}'")
    except Exception as err:
        print(f"  Failed to upload CSV to Azure Storage: {err}")