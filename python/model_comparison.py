"""
Model Comparison Script: Standard vs Fine-Tuned NER
This script runs both models on the same test invoices and generates a comparison report
showing the differences in entity extraction between the standard and fine-tuned models.
"""

from dotenv import load_dotenv
import os
import csv
import json
import requests
import time
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

# Get credentials from Key Vault
language_service_key = client_kv.get_secret("language-service-key").value
gpt_5_chat_key = client_kv.get_secret("gpt-5-chat-key").value
gpt_5_chat_endpoint = client_kv.get_secret("gpt-5-chat-endpoint").value
storage_connection_string = Config.get_storage_connection_string()

# Fine-tuned model configuration
LANGUAGE_SERVICE_ENDPOINT = Config.LANGUAGE_SERVICE_ENDPOINT
API_VERSION = "2024-11-15-preview"
PROJECT_NAME = "test-v3"
DEPLOYMENT_NAME = "test"

def fetch_invoices_from_local(test_invoices_dir="../data/test_invoices"):
    """Fetch all test invoice files from local filesystem."""
    try:
        invoices = []
        script_dir = os.path.dirname(os.path.abspath(__file__))
        full_path = os.path.join(script_dir, test_invoices_dir)
        
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
        print(f"Error loading test invoices: {err}")
        return []

# ==================== STANDARD MODEL ====================
def extract_with_standard_model(invoices):
    """Extract entities using Azure standard NER model."""
    print("\n" + "="*70)
    print("STANDARD MODEL - Azure Language Service NER")
    print("="*70)
    
    ta_credential = AzureKeyCredential(gpt_5_chat_key)
    client = TextAnalyticsClient(endpoint=gpt_5_chat_endpoint, credential=ta_credential)
    
    results = {
        "model": "Standard",
        "entity_types": set(),
        "entities_by_invoice": {},
        "total_entities": 0
    }
    
    batch_size = 5
    documents = [inv["content"] for inv in invoices]
    
    for i in range(0, len(documents), batch_size):
        try:
            batch = documents[i:i+batch_size]
            recognition_results = client.recognize_entities(documents=batch)
            
            for idx, result in enumerate(recognition_results):
                invoice_idx = i + idx
                invoice_name = invoices[invoice_idx]["file_name"]
                results["entities_by_invoice"][invoice_name] = []
                
                for entity in result.entities:
                    results["entity_types"].add(entity.category)
                    results["total_entities"] += 1
                    
                    results["entities_by_invoice"][invoice_name].append({
                        "text": entity.text,
                        "category": entity.category,
                        "confidence": f"{entity.confidence_score * 100:.2f}%"
                    })
        except Exception as err:
            print(f"Error processing batch: {err}")
    
    results["entity_types"] = sorted(list(results["entity_types"]))
    return results

# ==================== FINE-TUNED MODEL ====================
def extract_with_fine_tuned_model(invoices):
    """Extract entities using fine-tuned CustomEntityRecognition model."""
    print("\n" + "="*70)
    print("FINE-TUNED MODEL - CustomEntityRecognition (test-v3)")
    print("="*70)
    
    results = {
        "model": "Fine-Tuned",
        "entity_types": set(),
        "entities_by_invoice": {},
        "total_entities": 0
    }
    
    for invoice in invoices:
        file_name = invoice["file_name"]
        content = invoice["content"]
        results["entities_by_invoice"][file_name] = []
        
        # Call fine-tuned API
        url = f"{LANGUAGE_SERVICE_ENDPOINT}language/analyze-text/jobs?api-version={API_VERSION}"
        headers = {
            "Ocp-Apim-Subscription-Key": language_service_key,
            "Content-Type": "application/json"
        }
        
        payload = {
            "displayName": f"Entity extraction for {file_name}",
            "analysisInput": {
                "documents": [{
                    "id": file_name.replace('.txt', ''),
                    "language": "en",
                    "text": content
                }]
            },
            "tasks": [{
                "kind": "CustomEntityRecognition",
                "taskName": "Entity Recognition",
                "parameters": {
                    "projectName": PROJECT_NAME,
                    "deploymentName": DEPLOYMENT_NAME
                }
            }]
        }
        
        try:
            response = requests.post(url, headers=headers, json=payload)
            
            if response.status_code != 202:
                print(f"Error for {file_name}: {response.status_code}")
                continue
            
            job_location = response.headers.get('operation-location')
            max_retries = 30
            retry_count = 0
            
            while retry_count < max_retries:
                time.sleep(2)
                status_response = requests.get(job_location, headers={
                    "Ocp-Apim-Subscription-Key": language_service_key
                })
                
                if status_response.status_code == 200:
                    result = status_response.json()
                    job_status = result.get('status')
                    
                    if job_status == 'succeeded':
                        tasks = result.get('tasks', {}).get('items', [])
                        if tasks:
                            task_result = tasks[0]
                            result_data = task_result.get('results', {})
                            documents = result_data.get('documents', [])
                            
                            if documents:
                                entities_list = documents[0].get('entities', [])
                                
                                for entity in entities_list:
                                    entity_category = entity.get('category', 'Unknown')
                                    results["entity_types"].add(entity_category)
                                    results["total_entities"] += 1
                                    
                                    results["entities_by_invoice"][file_name].append({
                                        "text": entity.get("text", ""),
                                        "category": entity_category,
                                        "confidence": f"{entity.get('confidenceScore', 0)*100:.2f}%"
                                    })
                        break
                    elif job_status == 'failed':
                        print(f"Job failed for {file_name}")
                        break
                
                retry_count += 1
        except Exception as err:
            print(f"Error processing {file_name}: {err}")
    
    results["entity_types"] = sorted(list(results["entity_types"]))
    return results

def generate_comparison_report(standard_results, finetuned_results):
    """Generate a comparison report between the two models."""
    print("\n" + "="*70)
    print("COMPARISON REPORT: Standard vs Fine-Tuned NER")
    print("="*70)
    
    print(f"\n📊 ENTITY TYPES DETECTED:")
    print(f"\nStandard Model ({len(standard_results['entity_types'])} types):")
    print(f"  {', '.join(standard_results['entity_types'])}")
    
    print(f"\nFine-Tuned Model ({len(finetuned_results['entity_types'])} types):")
    print(f"  {', '.join(finetuned_results['entity_types'])}")
    
    # Find differences
    standard_set = set(standard_results['entity_types'])
    finetuned_set = set(finetuned_results['entity_types'])
    
    only_standard = standard_set - finetuned_set
    only_finetuned = finetuned_set - standard_set
    common = standard_set & finetuned_set
    
    print(f"\n📈 ENTITY TYPE DIFFERENCES:")
    print(f"  Only in Standard Model: {only_standard if only_standard else 'None'}")
    print(f"  Only in Fine-Tuned Model: {only_finetuned if only_finetuned else 'None'}")
    print(f"  Common Types: {len(common)}")
    
    print(f"\n📝 TOTAL ENTITIES EXTRACTED:")
    print(f"  Standard Model: {standard_results['total_entities']} entities")
    print(f"  Fine-Tuned Model: {finetuned_results['total_entities']} entities")
    print(f"  Difference: {abs(standard_results['total_entities'] - finetuned_results['total_entities'])}")
    
    # Summary per invoice
    print(f"\n📋 ENTITIES PER INVOICE:")
    print(f"\n{'Invoice':<30} {'Standard':<12} {'Fine-Tuned':<12} {'Diff':<8}")
    print("-" * 62)
    
    for invoice_name in sorted(standard_results['entities_by_invoice'].keys()):
        standard_count = len(standard_results['entities_by_invoice'].get(invoice_name, []))
        finetuned_count = len(finetuned_results['entities_by_invoice'].get(invoice_name, []))
        diff = finetuned_count - standard_count
        
        print(f"{invoice_name:<30} {standard_count:<12} {finetuned_count:<12} {diff:<8}")
    
    # Export detailed comparison to CSV
    print(f"\n💾 Exporting detailed comparison to CSV...")
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    csv_file = f"model_comparison_{timestamp}.csv"
    csv_path = f"/tmp/{csv_file}"
    
    try:
        with open(csv_path, 'w', newline='', encoding='utf-8') as csvfile:
            fieldnames = ["Invoice", "Standard_Entities", "Fine_Tuned_Entities", "Standard_Types", "Fine_Tuned_Types"]
            writer = csv.DictWriter(csvfile, fieldnames=fieldnames)
            writer.writeheader()
            
            for invoice_name in sorted(standard_results['entities_by_invoice'].keys()):
                standard_entities = standard_results['entities_by_invoice'].get(invoice_name, [])
                finetuned_entities = finetuned_results['entities_by_invoice'].get(invoice_name, [])
                
                standard_types = ', '.join(set(e['category'] for e in standard_entities))
                finetuned_types = ', '.join(set(e['category'] for e in finetuned_entities))
                
                writer.writerow({
                    "Invoice": invoice_name,
                    "Standard_Entities": len(standard_entities),
                    "Fine_Tuned_Entities": len(finetuned_entities),
                    "Standard_Types": standard_types,
                    "Fine_Tuned_Types": finetuned_types
                })
        
        print(f"  CSV saved to: {csv_path}")
        
        # Upload to Azure Storage
        blob_service_client = BlobServiceClient.from_connection_string(storage_connection_string)
        reports_container = "reports"
        
        with open(csv_path, 'rb') as data:
            blob_client = blob_service_client.get_blob_client(
                container=reports_container,
                blob=csv_file
            )
            blob_client.upload_blob(data, overwrite=True)
        
        print(f"  CSV uploaded to Azure Storage: {csv_file}")
    except Exception as err:
        print(f"  Error saving comparison CSV: {err}")

if __name__ == "__main__":
    print("="*70)
    print("NER MODEL COMPARISON: Standard vs Fine-Tuned")
    print("="*70)
    
    # Load test invoices
    invoices = fetch_invoices_from_local(test_invoices_dir="../data/test_invoices")
    
    if not invoices:
        print("No invoices found. Exiting.")
        exit(1)
    
    # Run both models
    print(f"\nLoaded {len(invoices)} test invoices for comparison")
    
    standard_results = extract_with_standard_model(invoices)
    print(f"✓ Standard Model: {standard_results['total_entities']} entities in {len(standard_results['entity_types'])} types")
    
    finetuned_results = extract_with_fine_tuned_model(invoices)
    print(f"✓ Fine-Tuned Model: {finetuned_results['total_entities']} entities in {len(finetuned_results['entity_types'])} types")
    
    # Generate comparison
    generate_comparison_report(standard_results, finetuned_results)
    
    print("\n" + "="*70)
    print("✅ Model comparison complete!")
    print("="*70)
