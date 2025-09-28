from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.api.endpoints import router as api_router
from app.core.config import settings

<<<<<<< HEAD
class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        self.send_response(200)
        self.end_headers()
        self.wfile.write(b"Hello from myapp!\n")
        print("done")

if __name__ == "__main__":
    HTTPServer(("0.0.0.0", 8080), Handler).serve_forever()
#testinggsadasd
=======
app = FastAPI(
    title="Your FastAPI App",
    description="A simple FastAPI application",
    version="1.0.0"
)

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include API routes
app.include_router(api_router, prefix="/api")

@app.get("/")
async def root():
    return {"message": "Welcome to FastAPI", "status": "healthy"}

@app.get("/health")
async def health_check():
    return {"status": "healthy", "service": "fastapi-app"}

@app.get("/api/version")
async def version():
    return {"version": "1.0.0", "framework": "FastAPI"}
>>>>>>> 34e9938 (changing workflow)
