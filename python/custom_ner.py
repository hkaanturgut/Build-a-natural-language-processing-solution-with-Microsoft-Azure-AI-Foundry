from dotenv import load_dotenv
import os
import csv
from datetime import datetime
from azure.identity import DefaultAzureCredential
from azure.keyvault.secrets import SecretClient
from azure.storage.blob import BlobServiceClient
from azure.ai.textanalytics import TextAnalyticsClient
from azure.core.credentials import AzureKeyCredential
from config import Config

# Initialize configuration (automatically resolves Key Vault URI)
Config.validate(strict=True)

credential = DefaultAzureCredential()
client_kv = Config.get_key_vault_client()

# Retrieve secrets from Key Vault
gpt_5_chat_key = client_kv.get_secret("gpt-5-chat-key").value
gpt_5_chat_endpoint = client_kv.get_secret("gpt-5-chat-endpoint").value
storage_connection_string = Config.get_storage_connection_string()

def authenticate_client():
    ta_credential = AzureKeyCredential(gpt_5_chat_key)
    text_analytics_client = TextAnalyticsClient(
        endpoint=gpt_5_chat_endpoint,
        credential=ta_credential)
    return text_analytics_client

client = authenticate_client()

# Fetch invoice files from local filesystem
def fetch_invoices_from_local(test_invoices_dir="../data/test_invoices"):
    """Fetch all test invoice files from local filesystem."""
    try:
        invoices = []
        
        # Get the directory path relative to the script location
        script_dir = os.path.dirname(os.path.abspath(__file__))
        full_path = os.path.join(script_dir, test_invoices_dir)
        
        # List all .txt files in the test_invoices directory
        if not os.path.exists(full_path):
            print(f"Error: Test invoices directory not found at {full_path}")
            return []
        
        txt_files = sorted([f for f in os.listdir(full_path) if f.endswith('.txt')])
        
        for file_name in txt_files:
            file_path = os.path.join(full_path, file_name)
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()
                invoices.append(content)
        
        print(f"Loaded {len(invoices)} test invoice files from {full_path}")
        return invoices
    except Exception as err:
        print(f"Error loading test invoices from local filesystem: {err}")
        return []

# Entities will be dynamically extracted from API response
CUSTOM_ENTITIES = []  # Will be populated based on actual entity types found

def entity_recognition_example(client, documents):
    print("Step 1: Starting entity extraction from invoice documents...")
    batch_size = 5
    csv_rows = []
    detected_entity_types = set()  # Track all entity types found
    
    for i in range(0, len(documents), batch_size):
        try:
            print(f"  Processing batch {i//batch_size + 1} (documents {i+1} to {min(i+batch_size, len(documents))})...")
            batch = documents[i:i+batch_size]
            results = client.recognize_entities(documents=batch)
            import re
            invoice_pattern = re.compile(r"INV-\d+")
            for idx, result in enumerate(results):
                doc_num = i + idx + 1
                # Track found invoice numbers for this document
                found_invoice = False
                for entity in result.entities:
                    # Check if entity matches invoice number pattern
                    if invoice_pattern.fullmatch(entity.text):
                        found_invoice = True
                        entity_type = "InvoiceNumber"
                    # If misclassified as quantity but matches invoice pattern, fix type
                    elif entity.category.lower() in ["quantity", "number"] and invoice_pattern.fullmatch(entity.text):
                        entity_type = "InvoiceNumber"
                    else:
                        entity_type = entity.category
                    
                    # Track detected entity types dynamically
                    detected_entity_types.add(entity_type)
                    if entity.subcategory:
                        detected_entity_types.add(entity.subcategory)
                    
                    print(f"    Extracted entity: {entity.text} (Type: {entity_type}, Confidence: {entity.confidence_score * 100:.2f}%)")
                    tags = [entity_type]
                    if entity.subcategory:
                        tags.append(entity.subcategory)
                    tags_str = ", ".join([f"{tag} ({entity.confidence_score * 100:.0f}%)" for tag in tags])
                    csv_rows.append({
                        "Document Number": doc_num,
                        "Entity Text": entity.text,
                        "Type": entity_type,
                        "Offset": entity.offset,
                        "Length": entity.length,
                        "Confidence": f"{entity.confidence_score * 100:.2f}%",
                        "Tags": tags_str,
                    })
                # If no invoice number was found, try to extract from document text
                if not found_invoice and invoice_pattern.search(documents[idx]):
                    inv_num = invoice_pattern.search(documents[idx]).group(0)
                    print(f"    Post-processed: Found invoice number {inv_num} in document text.")
                    detected_entity_types.add("InvoiceNumber")
                    csv_rows.append({
                        "Document Number": doc_num,
                        "Entity Text": inv_num,
                        "Type": "InvoiceNumber",
                        "Offset": documents[idx].find(inv_num),
                        "Length": len(inv_num),
                        "Confidence": "N/A",
                        "Tags": "InvoiceNumber",
                    })
        except Exception as err:
            print(f"  Encountered exception in batch {i//batch_size + 1}: {err}")
    
    # Update global CUSTOM_ENTITIES with dynamically detected types
    global CUSTOM_ENTITIES
    CUSTOM_ENTITIES = sorted(list(detected_entity_types))

    print("Step 2: Writing extracted entities to CSV and uploading to Azure Storage...")
    import io
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    csv_file = f"entity_extraction_results_{timestamp}.csv"
    csv_buffer = io.StringIO()
    writer = csv.DictWriter(csv_buffer, fieldnames=[
        "Document Number", "Entity Text", "Type", "Offset", "Length", "Confidence", "Tags"
    ])
    writer.writeheader()
    writer.writerows(csv_rows)
    csv_data = csv_buffer.getvalue().encode("utf-8")
    print("Step 3: Uploading CSV report to Azure Storage container 'reports'...")
    try:
        blob_service_client = BlobServiceClient.from_connection_string(storage_connection_string)
        reports_container = "reports"
        blob_client = blob_service_client.get_blob_client(container=reports_container, blob=csv_file)
        blob_client.upload_blob(csv_data, overwrite=True)
        print(f"  CSV report uploaded to Azure Storage container '{reports_container}' as '{csv_file}'")
    except Exception as err:
        print(f"  Failed to upload CSV to Azure Storage: {err}")

if __name__ == "__main__":
    print("=" * 70)
    print("Azure Standard Model - Invoice Entity Extraction (Test Mode)")
    print("=" * 70)
    print("This uses the standard Azure Language Service NER model")
    print("Entity types will be automatically detected from the API response")
    print("=" * 70)
    invoices = fetch_invoices_from_local(test_invoices_dir="../data/test_invoices")
    print(f"\nLoaded {len(invoices)} invoice documents from local filesystem.")
    entity_recognition_example(client, invoices)
    print(f"\n" + "=" * 70)
    print(f"Detected Entity Types (Standard Model): {CUSTOM_ENTITIES}")
    print("=" * 70)