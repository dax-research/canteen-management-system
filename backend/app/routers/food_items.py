from typing import List
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.db.database import get_db
from app.models.category import Category
from app.models.food_item import FoodItem
from app.models.cart import CartItem
from app.schemas.menu import FoodItemResponse, FoodItemCreate, FoodItemUpdate
from app.core.dependencies import get_admin_user
from app.models.user import User

router = APIRouter(prefix="/api/admin/food-items", tags=["admin-food-items"])

@router.get("/", response_model=List[FoodItemResponse])
def get_all_food_items(
    db: Session = Depends(get_db),
    admin: User = Depends(get_admin_user)
):
    """
    Get all food items, including unavailable ones (ADMIN only).
    """
    results = db.query(FoodItem, Category).join(Category).order_by(Category.name.asc(), FoodItem.name.asc()).all()

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
                stock=food.stock,
                image_url=food.image_url,
                is_available=food.is_available,
            )
        )
    return response

@router.get("/{food_item_id}", response_model=FoodItemResponse)
def get_food_item(
    food_item_id: str,
    db: Session = Depends(get_db),
    admin: User = Depends(get_admin_user)
):
    """
    Get a single food item by ID (ADMIN only).
    """
    result = db.query(FoodItem, Category).join(Category).filter(FoodItem.id == food_item_id).first()
    if not result:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Food item not found")

    food, cat = result
    return FoodItemResponse(
        id=food.id,
        category_id=food.category_id,
        category_name=cat.name,
        name=food.name,
        description=food.description,
        price=float(food.price),
        stock=food.stock,
        image_url=food.image_url,
        is_available=food.is_available,
    )

@router.post("/", response_model=FoodItemResponse, status_code=status.HTTP_201_CREATED)
def create_food_item(
    food_in: FoodItemCreate,
    db: Session = Depends(get_db),
    admin: User = Depends(get_admin_user)
):
    """
    Create a new food item (ADMIN only).
    """
    category = db.query(Category).filter(Category.id == food_in.category_id).first()
    if not category:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Category not found")

    is_available = food_in.is_available
    if food_in.stock == 0:
        is_available = False

    new_food = FoodItem(
        category_id=food_in.category_id,
        name=food_in.name,
        description=food_in.description,
        price=food_in.price,
        stock=food_in.stock,
        image_url=food_in.image_url,
        is_available=is_available,
    )
    db.add(new_food)
    db.commit()
    db.refresh(new_food)

    return FoodItemResponse(
        id=new_food.id,
        category_id=new_food.category_id,
        category_name=category.name,
        name=new_food.name,
        description=new_food.description,
        price=float(new_food.price),
        stock=new_food.stock,
        image_url=new_food.image_url,
        is_available=new_food.is_available,
    )

@router.patch("/{food_item_id}", response_model=FoodItemResponse)
def update_food_item(
    food_item_id: str,
    food_in: FoodItemUpdate,
    db: Session = Depends(get_db),
    admin: User = Depends(get_admin_user)
):
    """
    Update a food item (ADMIN only).
    """
    food = db.query(FoodItem).filter(FoodItem.id == food_item_id).first()
    if not food:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Food item not found")

    update_data = food_in.model_dump(exclude_unset=True)

    if "category_id" in update_data and update_data["category_id"] != food.category_id:
        category = db.query(Category).filter(Category.id == update_data["category_id"]).first()
        if not category:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Category not found")

    new_stock = update_data.get("stock", food.stock)

    if new_stock == 0:
        if "is_available" in update_data and update_data["is_available"] is True:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Cannot set available when stock is 0")
        update_data["is_available"] = False

    for key, value in update_data.items():
        setattr(food, key, value)

    db.commit()
    db.refresh(food)

    # Refresh category name
    category = db.query(Category).filter(Category.id == food.category_id).first()

    return FoodItemResponse(
        id=food.id,
        category_id=food.category_id,
        category_name=category.name,
        name=food.name,
        description=food.description,
        price=float(food.price),
        stock=food.stock,
        image_url=food.image_url,
        is_available=food.is_available,
    )

@router.delete("/{food_item_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_food_item(
    food_item_id: str,
    db: Session = Depends(get_db),
    admin: User = Depends(get_admin_user)
):
    """
    Delete a food item (ADMIN only).
    Deletes cart items referring to this food item to prevent foreign key constraint failures.
    Historical orders referencing this food item will have food_item_id set to NULL due to SET NULL constraint on order_items.
    """
    food = db.query(FoodItem).filter(FoodItem.id == food_item_id).first()
    if not food:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Food item not found")

    # Delete cart items first to respect RESTRICT foreign key
    db.query(CartItem).filter(CartItem.food_item_id == food_item_id).delete()

    # Now we can safely delete the food item.
    db.delete(food)
    db.commit()
