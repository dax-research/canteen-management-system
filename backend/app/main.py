from fastapi import FastAPI

app = FastAPI(
    title="Canteen Management System API",
    version="1.0.0"
)


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