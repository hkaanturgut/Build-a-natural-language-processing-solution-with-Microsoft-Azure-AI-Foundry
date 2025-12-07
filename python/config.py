"""
Centralized configuration management for Azure NLP Solution.
Loads all configuration from environment variables and Key Vault.
"""

import os
import sys
from pathlib import Path
from dotenv import load_dotenv
from azure.identity import DefaultAzureCredential
from azure.keyvault.secrets import SecretClient


class Config:
    """Centralized configuration class for Azure NLP Solution."""
    
    # Load environment variables from .env file
    _env_path = Path(__file__).parent / ".env"
    if _env_path.exists():
        load_dotenv(_env_path)
    
    # Azure Identity & Key Vault
    KEY_VAULT_URI = os.getenv("KEY_VAULT_URI")
    LANGUAGE_SERVICE_ENDPOINT = os.getenv("LANGUAGE_SERVICE_ENDPOINT")
    LANGUAGE_SERVICE_API_VERSION = os.getenv("LANGUAGE_SERVICE_API_VERSION", "2024-11-15-preview")
    AI_FOUNDRY_PROJECT_NAME = os.getenv("AI_FOUNDRY_PROJECT_NAME")
    AI_FOUNDRY_DEPLOYMENT_NAME = os.getenv("AI_FOUNDRY_DEPLOYMENT_NAME")
    STORAGE_ACCOUNT_NAME = os.getenv("STORAGE_ACCOUNT_NAME")
    STORAGE_CONNECTION_STRING = os.getenv("STORAGE_CONNECTION_STRING")
    
    # Credentials
    _credential = None
    _key_vault_client = None
    _language_service_key = None
    _storage_connection_string_from_kv = None
    
    @classmethod
    def validate(cls, strict=True):
        """
        Validate that all required configuration is present.
        
        Args:
            strict (bool): If True, exit on missing configuration. If False, warn only.
        
        Returns:
            bool: True if validation passed, False otherwise.
        """
        required_vars = [
            "KEY_VAULT_URI",
            "LANGUAGE_SERVICE_ENDPOINT",
            "AI_FOUNDRY_PROJECT_NAME",
            "AI_FOUNDRY_DEPLOYMENT_NAME",
        ]
        
        missing = []
        for var in required_vars:
            if not getattr(cls, var, None):
                missing.append(var)
        
        if missing:
            error_msg = f"\n❌ Missing required configuration variables:\n"
            for var in missing:
                error_msg += f"   - {var}\n"
            error_msg += f"\n💡 Make sure python/.env file is populated with Terraform outputs.\n"
            error_msg += f"   Run: ../update-env.sh\n"
            
            if strict:
                print(error_msg, file=sys.stderr)
                sys.exit(1)
            else:
                print(error_msg, file=sys.stderr)
                return False
        
        return True
    
    @classmethod
    def get_credential(cls):
        """Get Azure credential for authentication."""
        if cls._credential is None:
            cls._credential = DefaultAzureCredential()
        return cls._credential
    
    @classmethod
    def get_key_vault_client(cls):
        """Get Key Vault client for retrieving secrets."""
        if cls._key_vault_client is None:
            if not cls.KEY_VAULT_URI:
                raise ValueError("KEY_VAULT_URI not set in configuration")
            
            credential = cls.get_credential()
            cls._key_vault_client = SecretClient(
                vault_url=cls.KEY_VAULT_URI,
                credential=credential
            )
        return cls._key_vault_client
    
    @classmethod
    def get_language_service_key(cls):
        """Get language service API key from Key Vault."""
        if cls._language_service_key is None:
            try:
                kv_client = cls.get_key_vault_client()
                secret = kv_client.get_secret("language-service-key")
                cls._language_service_key = secret.value
            except Exception as e:
                print(f"❌ Error retrieving language-service-key from Key Vault: {e}", file=sys.stderr)
                sys.exit(1)
        return cls._language_service_key
    
    @classmethod
    def get_storage_connection_string(cls):
        """Get storage connection string from Key Vault."""
        if cls._storage_connection_string_from_kv is None:
            try:
                kv_client = cls.get_key_vault_client()
                secret = kv_client.get_secret("storage-connection-string")
                cls._storage_connection_string_from_kv = secret.value
            except Exception as e:
                print(f"❌ Error retrieving storage-connection-string from Key Vault: {e}", file=sys.stderr)
                sys.exit(1)
        return cls._storage_connection_string_from_kv
    
    @classmethod
    def to_dict(cls):
        """Return configuration as dictionary."""
        return {
            "KEY_VAULT_URI": cls.KEY_VAULT_URI,
            "LANGUAGE_SERVICE_ENDPOINT": cls.LANGUAGE_SERVICE_ENDPOINT,
            "LANGUAGE_SERVICE_API_VERSION": cls.LANGUAGE_SERVICE_API_VERSION,
            "AI_FOUNDRY_PROJECT_NAME": cls.AI_FOUNDRY_PROJECT_NAME,
            "AI_FOUNDRY_DEPLOYMENT_NAME": cls.AI_FOUNDRY_DEPLOYMENT_NAME,
            "STORAGE_ACCOUNT_NAME": cls.STORAGE_ACCOUNT_NAME,
        }
    
    @classmethod
    def print_status(cls):
        """Print configuration status."""
        config_dict = cls.to_dict()
        print("\n" + "=" * 60)
        print("Configuration Status")
        print("=" * 60)
        
        for key, value in config_dict.items():
            status = "✅" if value else "❌"
            display_value = value if value else "NOT SET"
            print(f"{status} {key}: {display_value}")
        
        print("=" * 60 + "\n")


def get_config():
    """Convenience function to get Config class."""
    return Config
