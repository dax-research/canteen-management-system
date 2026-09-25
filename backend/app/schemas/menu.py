from typing import Optional
from pydantic import BaseModel, ConfigDict


class CategoryResponse(BaseModel):
    id: str
    name: str
    description: Optional[str] = None

    model_config = ConfigDict(from_attributes=True)


class FoodItemResponse(BaseModel):
    id: str
    category_id: str
    category_name: str
    name: str
    description: Optional[str] = None
    price: float
    image_url: Optional[str] = None
    is_available: bool

    model_config = ConfigDict(from_attributes=True)
