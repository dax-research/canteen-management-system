from typing import Optional
from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session
from sqlalchemy import func

from app.db.database import get_db
from app.models.category import Category
from app.models.food_item import FoodItem
from app.schemas.menu import CategoryResponse, FoodItemResponse

router = APIRouter(prefix="/api", tags=["menu"])


@router.get("/categories", response_model=list[CategoryResponse])
def get_categories(db: Session = Depends(get_db)):
    """
    Get all active categories ordered by name.
    """
    categories = (
        db.query(Category)
        .filter(Category.is_active == True)
        .order_by(Category.name.asc())
        .all()
    )
    return categories


@router.get("/food-items", response_model=list[FoodItemResponse])
def get_food_items(
    search: Optional[str] = Query(None, description="Search by food item name"),
    category_id: Optional[str] = Query(None, description="Filter by category ID"),
    available_only: bool = Query(True, description="Return only available food items"),
    db: Session = Depends(get_db),
):
    """
    Get food items with optional search and category filters.
    Only returns items from active categories.
    """
    query = (
        db.query(FoodItem, Category)
        .join(Category, FoodItem.category_id == Category.id)
        .filter(Category.is_active == True)
    )

    if available_only:
        query = query.filter(FoodItem.is_available == True)

    if category_id:
        query = query.filter(FoodItem.category_id == category_id)

    if search and search.strip():
        # Case-insensitive matching
        search_term = f"%{search.strip()}%"
        query = query.filter(FoodItem.name.ilike(search_term))

    # Deterministic ordering
    query = query.order_by(Category.name.asc(), FoodItem.name.asc())
    
    results = query.all()

    # Construct the response manually to inject category_name and handle Decimal -> float
    response = []
    for food, cat in results:
        response.append(
            FoodItemResponse(
                id=food.id,
                category_id=food.category_id,
                category_name=cat.name,
                name=food.name,
                description=food.description,
                price=float(food.price),
                image_url=food.image_url,
                is_available=food.is_available,
            )
        )

    return response
