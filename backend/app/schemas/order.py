from datetime import datetime
from decimal import Decimal
from typing import List, Optional

from pydantic import BaseModel, ConfigDict, Field


class OrderItemResponse(BaseModel):
    id: str
    order_id: str
    food_item_id: Optional[str] = None
    item_name: str
    unit_price: float
    quantity: int
    subtotal: float
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)


class OrderResponse(BaseModel):
    id: str
    user_id: str
    status: str
    total_amount: float
    created_at: datetime
    updated_at: datetime
    items: List[OrderItemResponse]

    model_config = ConfigDict(from_attributes=True)
