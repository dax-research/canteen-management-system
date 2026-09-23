from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.routers import auth

app = FastAPI(
    title="Canteen Management System API",
    version="1.0.0"
)

# Add CORS middleware to allow Flutter app to communicate
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Allows all origins for development
    allow_credentials=True,
    allow_methods=["*"],  # Allows all methods
    allow_headers=["*"],  # Allows all headers
)

# Include routers
app.include_router(auth.router)

@app.get("/")
def root():
    return {
        "message": "Canteen Management System API is running"
    }


@app.get("/api/test")
def test():
    return {
        "message": "FastAPI is working"
    }