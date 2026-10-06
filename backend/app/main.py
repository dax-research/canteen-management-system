from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.routers import auth, menu, cart, order, inventory, categories, food_items
from app.routers import dashboard, admin_orders, users

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
app.include_router(menu.router)
app.include_router(cart.router)
app.include_router(order.router)
app.include_router(inventory.router)
app.include_router(categories.router)
app.include_router(food_items.router)
app.include_router(dashboard.router)
app.include_router(admin_orders.router)
app.include_router(users.router)


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
