import os
import json
import csv
import requests
from datetime import datetime
from azure.storage.blob import BlobServiceClient
from config import Config

# Validate configuration on startup
Config.validate(strict=True)

# Load configuration from centralized config module
LANGUAGE_SERVICE_ENDPOINT = Config.LANGUAGE_SERVICE_ENDPOINT
API_VERSION = Config.LANGUAGE_SERVICE_API_VERSION
PROJECT_NAME = Config.AI_FOUNDRY_PROJECT_NAME
DEPLOYMENT_NAME = Config.AI_FOUNDRY_DEPLOYMENT_NAME

# Get credentials from Key Vault
language_service_key = Config.get_language_service_key()
storage_connection_string = Config.get_storage_connection_string()

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
                invoices.append({
                    "file_name": file_name,
                    "content": content
                })
        
        print(f"Loaded {len(invoices)} test invoice files from {full_path}")
        return invoices
    except Exception as err:
        print(f"Error loading test invoices from local filesystem: {err}")
        return []

def extract_entities_with_fine_tuned_model(invoice_text, file_name):
    """
    Send invoice text to fine-tuned NER model via async API.
    Returns extracted entities.
    """
    import time
    
    # Use async API endpoint for CustomEntityRecognition
    url = f"{LANGUAGE_SERVICE_ENDPOINT}language/analyze-text/jobs?api-version={API_VERSION}"
    
    headers = {
        "Ocp-Apim-Subscription-Key": language_service_key,
        "Content-Type": "application/json"
    }
    
    # Async API requires 'tasks' array format
    payload = {
        "displayName": f"Entity extraction for {file_name}",
        "analysisInput": {
            "documents": [
                {
                    "id": file_name.replace('.txt', ''),
                    "language": "en",
                    "text": invoice_text
                }
            ]
        },
        "tasks": [
            {
                "kind": "CustomEntityRecognition",
                "taskName": "Entity Recognition",
                "parameters": {
                    "projectName": PROJECT_NAME,
                    "deploymentName": DEPLOYMENT_NAME
                }
            }
        ]
    }
    
    try:
        print(f"  [DEBUG] Submitting async job to {url}")
        response = requests.post(url, headers=headers, json=payload)
        print(f"  [DEBUG] Response status code: {response.status_code}")
        
        if response.status_code != 202:
            print(f"  [ERROR] API request error for file {file_name}: {response.status_code}")
            print(f"  [ERROR] Response body: {response.text}")
            return None
        
        # Get the job location from the response headers
        job_location = response.headers.get('operation-location')
        print(f"  [DEBUG] Job submitted, polling location: {job_location}")
        
        # Poll for the job result
        max_retries = 30
        retry_count = 0
        
        while retry_count < max_retries:
            time.sleep(2)  # Wait 2 seconds before checking
            
            status_response = requests.get(job_location, headers={
                "Ocp-Apim-Subscription-Key": language_service_key
            })
            
            if status_response.status_code == 200:
                result = status_response.json()
                job_status = result.get('status')
                print(f"  [DEBUG] Job status: {job_status}")
                print(f"  [DEBUG] Result keys: {result.keys() if isinstance(result, dict) else 'Not a dict'}")
                
                if job_status == 'succeeded':
                    print(f"  [DEBUG] Job succeeded, extracting results")
                    # Results are in tasks[0] (items array)
                    tasks = result.get('tasks', {})
                    items = tasks.get('items', [])
                    if items:
                        task_result = items[0]
                        result_data = task_result.get('results', {})
                        print(f"  [DEBUG] Extracted result_data with keys: {result_data.keys() if isinstance(result_data, dict) else 'Not a dict'}")
                        return result_data
                    else:
                        print(f"  [DEBUG] No items in tasks")
                        return None
                elif job_status == 'failed':
                    errors = result.get('errors', [])
                    print(f"  [ERROR] Job failed: {errors}")
                    return None
            else:
                print(f"  [DEBUG] Status check returned {status_response.status_code}")
            
            retry_count += 1
        
        print(f"  [ERROR] Job polling timed out for {file_name}")
        return None
        
    except requests.exceptions.RequestException as err:
        print(f"  [ERROR] API request error for file {file_name}: {err}")
        if hasattr(err, 'response') and err.response is not None:
            print(f"  [ERROR] Response status: {err.response.status_code}")
            print(f"  [ERROR] Response body: {err.response.text}")
        return None

def parse_entities_from_response(response_json, file_name=""):
    """
    Parse entities from the fine-tuned CustomEntityRecognition model async API response.
    Extracts recognized entities and their classifications.
    """
    entities = []
    
    if not response_json:
        print(f"  [DEBUG] No response JSON for {file_name}")
        return entities
    
    # Debug: print the response structure
    print(f"  [DEBUG] Response keys: {response_json.keys() if isinstance(response_json, dict) else 'Not a dict'}")
    
    try:
        # Async API response structure wraps results in tasks array
        # Path: tasks[0].results.documents[].entities
        
        if "tasks" in response_json:
            tasks = response_json.get("tasks", [])
            print(f"  [DEBUG] Found {len(tasks)} tasks")
            
            if tasks:
                task_result = tasks[0]
                print(f"  [DEBUG] Task result keys: {task_result.keys()}")
                
                if "results" in task_result:
                    results = task_result["results"]
                    print(f"  [DEBUG] Found results, keys: {results.keys() if isinstance(results, dict) else 'Not a dict'}")
                    
                    if "documents" in results:
                        documents = results["documents"]
                        print(f"  [DEBUG] Found {len(documents)} documents in results")
                        
                        for doc in documents:
                            print(f"  [DEBUG] Document keys: {doc.keys() if isinstance(doc, dict) else 'Not a dict'}")
                            
                            if "entities" in doc:
                                entities_list = doc["entities"]
                                print(f"  [DEBUG] Found {len(entities_list)} entities in this document")
                                
                                for entity in entities_list:
                                    entities.append({
                                        "text": entity.get("text", ""),
                                        "category": entity.get("category", "Unknown"),
                                        "confidence": entity.get("confidenceScore", 0),
                                        "offset": entity.get("offset", -1),
                                        "length": entity.get("length", 0),
                                        "subcategory": entity.get("subcategory", "")
                                    })
        
        # Fallback for direct results path (in case API returns differently)
        elif "documents" in response_json:
            print(f"  [DEBUG] Found 'documents' at top level")
            documents = response_json["documents"]
            
            for doc in documents:
                if "entities" in doc:
                    for entity in doc["entities"]:
                        entities.append({
                            "text": entity.get("text", ""),
                            "category": entity.get("category", "Unknown"),
                            "confidence": entity.get("confidenceScore", 0),
                            "offset": entity.get("offset", -1),
                            "length": entity.get("length", 0),
                            "subcategory": entity.get("subcategory", "")
                        })
        
        else:
            print(f"  [DEBUG] No recognized entity path found. Response preview: {str(response_json)[:300]}")
            
    except (KeyError, TypeError) as err:
        print(f"  [DEBUG] Error parsing response: {err}")
        print(f"  [DEBUG] Response type: {type(response_json)}")
    
    return entities

def extract_custom_entities(invoice_content, file_name):
    """
    Extract specific entities from invoice content using fine-tuned model.
    Returns structured invoice data.
    """
    print(f"Extracting entities from {file_name}...")
    
    # Call the fine-tuned model
    response = extract_entities_with_fine_tuned_model(invoice_content, file_name)
    entities = parse_entities_from_response(response, file_name)
    
    # Print extracted entities
    if entities:
        print(f"  Found {len(entities)} entities:")
        for entity in entities:
            print(f"    - {entity['text']} ({entity['category']}, confidence: {entity['confidence']*100:.2f}%)")
    else:
        print(f"  No entities extracted or API error.")
    
    return entities

def process_invoices_and_export(invoices):
    """
    Process all invoices through the fine-tuned NER model and export results to CSV.
    """
    print("\nStarting fine-tuned NER extraction workflow...\n")
    
    csv_rows = []
    
    for invoice in invoices:
        file_name = invoice["file_name"]
        content = invoice["content"]
        
        print(f"\n--- Processing {file_name} ---")
        
        # Extract entities using fine-tuned model
        entities = extract_custom_entities(content, file_name)
        
        # Add to CSV rows
        for idx, entity in enumerate(entities):
            csv_rows.append({
                "File Name": file_name,
                "Entity Text": entity.get("text", ""),
                "Category": entity.get("category", ""),
                "Subcategory": entity.get("subcategory", ""),
                "Confidence": f"{entity.get('confidence', 0)*100:.2f}%",
                "Offset": entity.get("offset", ""),
                "Length": entity.get("length", ""),
            })
    
    # Write results to CSV file
    print("\n\n=== Exporting Results ===")
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    csv_file_name = f"fine_tuned_ner_results_{timestamp}.csv"
    csv_path = f"/tmp/{csv_file_name}"
    
    try:
        with open(csv_path, 'w', newline='', encoding='utf-8') as csvfile:
            fieldnames = ["File Name", "Entity Text", "Category", "Subcategory", "Confidence", "Offset", "Length"]
            writer = csv.DictWriter(csvfile, fieldnames=fieldnames)
            writer.writeheader()
            writer.writerows(csv_rows)
        
        print(f"CSV report created locally: {csv_path}")
        print(f"Total rows written: {len(csv_rows)}")
        
        # Upload to Azure Storage
        print("\nUploading CSV report to Azure Storage...")
        blob_service_client = BlobServiceClient.from_connection_string(storage_connection_string)
        reports_container = "reports"
        
        with open(csv_path, 'rb') as data:
            blob_client = blob_service_client.get_blob_client(
                container=reports_container,
                blob=csv_file_name
            )
            blob_client.upload_blob(data, overwrite=True)
        
        print(f"CSV report uploaded to Azure Storage container '{reports_container}' as '{csv_file_name}'")
        print(f"Report URL: https://<storage-account>.blob.core.windows.net/{reports_container}/{csv_file_name}")
        
    except Exception as err:
        print(f"Error writing or uploading CSV: {err}")
    
    print("\n=== Extraction Complete ===")
    return csv_rows

if __name__ == "__main__":
    print("=" * 60)
    print("Fine-Tuned NER Model - Invoice Entity Extraction (Test Mode)")
    print("=" * 60)
    print(f"Endpoint: {LANGUAGE_SERVICE_ENDPOINT}")
    print(f"Project: {PROJECT_NAME}")
    print(f"Deployment: {DEPLOYMENT_NAME}")
    print("=" * 60)
    
    # Load test invoices from local filesystem
    invoices = fetch_invoices_from_local(test_invoices_dir="../data/test_invoices")
    
    if invoices:
        # Process invoices through fine-tuned model
        results = process_invoices_and_export(invoices)
        print(f"\nFinal Summary: Extracted {len(results)} total entities from {len(invoices)} invoice files.")
    else:
        print("No test invoices found in local filesystem. Exiting.")
