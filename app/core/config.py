import os

class Settings:
    APP_NAME: str = "FastAPI App"
    DEBUG: bool = os.getenv("DEBUG", "False").lower() == "true"

    # API settings
    API_V1_STR: str = "/api"

    # CORS
    ALLOWED_HOSTS: list = ["*"]

settings = Settings()