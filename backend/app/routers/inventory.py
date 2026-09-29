from typing import List
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session, joinedload

from app.core.dependencies import get_staff_user
from app.db.database import get_db
from app.models.food_item import FoodItem
from app.models.user import User
from app.schemas.inventory import InventoryUpdate
from app.schemas.menu import FoodItemResponse

router = APIRouter(prefix="/api/inventory", tags=["inventory"])

@router.get("", response_model=List[FoodItemResponse])
def get_inventory(
    db: Session = Depends(get_db),
    staff_user: User = Depends(get_staff_user),
):
    food_items = db.query(FoodItem).options(joinedload(FoodItem.category)).all()
    results = []
    for item in food_items:
        results.append(FoodItemResponse(
            id=item.id,
            category_id=item.category_id,
            category_name=item.category.name if item.category else "",
            name=item.name,
            description=item.description,
            price=float(item.price),
            stock=item.stock,
            image_url=item.image_url,
            is_available=item.is_available,
        ))
    return results

@router.get("/{food_item_id}", response_model=FoodItemResponse)
def get_inventory_item(
    food_item_id: str,
    db: Session = Depends(get_db),
    staff_user: User = Depends(get_staff_user),
):
    item = db.query(FoodItem).options(joinedload(FoodItem.category)).filter(FoodItem.id == food_item_id).first()
    if not item:
        raise HTTPException(status_code=404, detail="Food item not found")

    return FoodItemResponse(
        id=item.id,
        category_id=item.category_id,
        category_name=item.category.name if item.category else "",
        name=item.name,
        description=item.description,
        price=float(item.price),
        stock=item.stock,
        image_url=item.image_url,
        is_available=item.is_available,
    )

@router.patch("/{food_item_id}", response_model=FoodItemResponse)
def update_inventory_stock(
    food_item_id: str,
    update_data: InventoryUpdate,
    db: Session = Depends(get_db),
    staff_user: User = Depends(get_staff_user),
):
    item = db.query(FoodItem).options(joinedload(FoodItem.category)).filter(FoodItem.id == food_item_id).first()
    if not item:
        raise HTTPException(status_code=404, detail="Food item not found")

    item.stock = update_data.stock
    if item.stock == 0:
        item.is_available = False
    elif item.stock > 0:
        item.is_available = True

    db.commit()
    db.refresh(item)

    return FoodItemResponse(
        id=item.id,
        category_id=item.category_id,
        category_name=item.category.name if item.category else "",
        name=item.name,
        description=item.description,
        price=float(item.price),
        stock=item.stock,
        image_url=item.image_url,
        is_available=item.is_available,
    )
