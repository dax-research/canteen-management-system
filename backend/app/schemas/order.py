from datetime import datetime
from decimal import Decimal
from typing import List, Literal, Optional

from pydantic import BaseModel, ConfigDict

OrderStatus = Literal[
    "PLACED", "ACCEPTED", "PREPARING", "READY", "COMPLETED", "CANCELLED"
]


class OrderCreate(BaseModel):
    order_type: Literal["PICKUP"] = "PICKUP"
    pickup_time: Optional[str] = None
    eta_minutes: Optional[int] = None
    payment_method: Literal["CASH", "MOCK_ONLINE"] = "CASH"


class OrderStatusUpdate(BaseModel):
    status: OrderStatus


class PaymentStatusUpdate(BaseModel):
    status: Literal["PAID"]


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
    payment_method: str = "CASH"
    payment_status: str = "PENDING"
    payment_reference: Optional[str] = None
    paid_at: Optional[datetime] = None
    total_amount: float
    created_at: datetime
    updated_at: datetime
    items: List[OrderItemResponse]

    model_config = ConfigDict(from_attributes=True)
