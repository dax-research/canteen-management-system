from datetime import datetime
from decimal import Decimal
from typing import List, Optional

from pydantic import BaseModel, ConfigDict

from typing import Literal, Optional

OrderStatus = Literal[
    "PLACED", "ACCEPTED", "PREPARING", "READY", "COMPLETED", "CANCELLED"
]


class OrderCreate(BaseModel):
    order_type: Literal["PICKUP"] = "PICKUP"
    pickup_time: Optional[str] = None
    eta_minutes: Optional[int] = None


class OrderStatusUpdate(BaseModel):
    status: OrderStatus


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
    order_type: str = "PICKUP"
    pickup_time: Optional[str] = None
    eta_minutes: Optional[int] = None
    total_amount: float
    created_at: datetime
    updated_at: datetime
    items: List[OrderItemResponse]

    model_config = ConfigDict(from_attributes=True)
