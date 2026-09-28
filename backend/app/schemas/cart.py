from decimal import Decimal
from pydantic import BaseModel, ConfigDict, Field


class CartItemAdd(BaseModel):
    food_item_id: str
    quantity: int = Field(gt=0, description="Quantity must be greater than 0")


class CartItemUpdate(BaseModel):
    quantity: int = Field(gt=0, description="Quantity must be greater than 0")


class CartItemResponse(BaseModel):
    id: str
    food_item_id: str
    name: str
    description: str | None = None
    image_url: str | None = None
    unit_price: float
    quantity: int
    subtotal: float
    is_available: bool

    model_config = ConfigDict(from_attributes=True)


class CartResponse(BaseModel):
    id: str
    items: list[CartItemResponse]
    total: float

    model_config = ConfigDict(from_attributes=True)
