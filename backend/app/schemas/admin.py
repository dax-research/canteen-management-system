"""Schemas for the admin-only surface (dashboard, users, order management)."""

from datetime import datetime
from typing import List, Optional

from pydantic import BaseModel, ConfigDict, EmailStr


# ── Dashboard ──────────────────────────────────────────────────────────────
class DashboardStats(BaseModel):
    """Aggregate canteen counters shown on the admin dashboard."""

    total_food_items: int
    total_users: int
    total_customers: int
    pending_orders: int          # PLACED
    active_orders: int           # ACCEPTED + PREPARING + READY
    completed_orders: int
    cancelled_orders: int
    low_stock_items: int         # stock > 0 and below the low-stock threshold
    out_of_stock_items: int      # stock == 0

    model_config = ConfigDict(from_attributes=True)


# ── User management ────────────────────────────────────────────────────────
class AdminUserResponse(BaseModel):
    """Admin view of a registered account.

    Deliberately omits `password`.  There is no `is_active` column on the
    users table in this schema, so account enable/disable is not offered —
    see routers/users.py for why it is left out rather than faked.
    """

    id: str
    name: str
    email: EmailStr
    role: str
    order_count: int = 0

    model_config = ConfigDict(from_attributes=True)


class AdminUserDetail(AdminUserResponse):
    """Admin view of one account, including order history summary."""

    total_spent: float = 0.0

    model_config = ConfigDict(from_attributes=True)


class AdminUserListResponse(BaseModel):
    users: List[AdminUserResponse]
    total: int


# ── Admin order management ─────────────────────────────────────────────────
class AdminOrderCustomer(BaseModel):
    id: str
    name: str
    email: EmailStr


class AdminOrderResponse(BaseModel):
    """Order plus the customer snapshot an admin needs to act on it."""

    id: str
    user_id: str
    status: str
    total_amount: float
    created_at: datetime
    updated_at: datetime
    items: List["AdminOrderItem"]
    customer: AdminOrderCustomer


class AdminOrderItem(BaseModel):
    # `order_id` and `created_at` are included so the existing client-side
    # `OrderItem.fromJson` can parse these rows unchanged — the admin order
    # list reuses the customer-facing item model rather than duplicating it.
    id: str
    order_id: str
    food_item_id: Optional[str] = None
    item_name: str
    unit_price: float
    quantity: int
    subtotal: float
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)


AdminOrderResponse.model_rebuild()
