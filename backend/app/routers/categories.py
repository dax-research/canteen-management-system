from typing import List
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.db.database import get_db
from app.models.category import Category
from app.models.food_item import FoodItem
from app.schemas.menu import CategoryResponse, CategoryCreate, CategoryUpdate
from app.core.dependencies import get_admin_user
from app.models.user import User

router = APIRouter(prefix="/api/admin/categories", tags=["admin-categories"])

@router.get("/", response_model=List[CategoryResponse])
def get_all_categories(
    db: Session = Depends(get_db),
    admin: User = Depends(get_admin_user)
):
    """
    Get all categories, including inactive ones (ADMIN only).
    """
    categories = db.query(Category).order_by(Category.name.asc()).all()
    return categories

@router.post("/", response_model=CategoryResponse, status_code=status.HTTP_201_CREATED)
def create_category(
    category_in: CategoryCreate,
    db: Session = Depends(get_db),
    admin: User = Depends(get_admin_user)
):
    """
    Create a new category (ADMIN only).
    """
    existing_category = db.query(Category).filter(Category.name == category_in.name).first()
    if existing_category:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Category with this name already exists",
        )

    new_category = Category(
        name=category_in.name,
        description=category_in.description,
        is_active=category_in.is_active
    )
    db.add(new_category)
    db.commit()
    db.refresh(new_category)
    return new_category

@router.patch("/{category_id}", response_model=CategoryResponse)
def update_category(
    category_id: str,
    category_in: CategoryUpdate,
    db: Session = Depends(get_db),
    admin: User = Depends(get_admin_user)
):
    """
    Update a category (ADMIN only).
    """
    category = db.query(Category).filter(Category.id == category_id).first()
    if not category:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Category not found")

    update_data = category_in.model_dump(exclude_unset=True)

    if "name" in update_data and update_data["name"] != category.name:
        existing = db.query(Category).filter(Category.name == update_data["name"]).first()
        if existing:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Category with this name already exists",
            )

    for key, value in update_data.items():
        setattr(category, key, value)

    db.commit()
    db.refresh(category)
    return category

@router.delete("/{category_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_category(
    category_id: str,
    db: Session = Depends(get_db),
    admin: User = Depends(get_admin_user)
):
    """
    Delete a category (ADMIN only).
    """
    category = db.query(Category).filter(Category.id == category_id).first()
    if not category:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Category not found")

    # Check if category has food items
    food_count = db.query(FoodItem).filter(FoodItem.category_id == category_id).count()
    if food_count > 0:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Cannot delete category because it contains food items. Delete or reassign the food items first."
        )

    db.delete(category)
    db.commit()
