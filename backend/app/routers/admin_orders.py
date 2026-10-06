"""Admin order management.

ADMIN-only.  These routes deliberately mirror the existing `/api/orders/staff`
handlers (same state machine, same filters) but resolve the caller through
`get_admin_user` and attach the customer snapshot an admin needs to act on
an order.  The user-facing `/api/orders` handlers are untouched, so a
customer's view of their own order is unchanged.

Status transitions are imported from `app.routers.order` rather than
re-declared, so admin and staff cannot drift apart.
"""

from typing import List, Optional

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import desc
from sqlalchemy.orm import Session, joinedload

from app.core.dependencies import get_admin_user
from app.db.database import get_db
from app.models.order import Order, OrderItem
from app.models.user import User
from app.routers.order import VALID_TRANSITIONS
from app.schemas.admin import (
    AdminOrderCustomer,
    AdminOrderItem,
    AdminOrderResponse,
)
from app.schemas.order import OrderStatus, OrderStatusUpdate

router = APIRouter(prefix="/api/admin/orders", tags=["admin-orders"])


def _to_admin_order(order: Order, customer: User) -> AdminOrderResponse:
    return AdminOrderResponse(
        id=order.id,
        user_id=order.user_id,
        status=order.status,
        order_type=order.order_type,
        pickup_time=order.pickup_time,
        eta_minutes=order.eta_minutes,
        payment_method=order.payment_method,
        payment_status=order.payment_status,
        payment_reference=order.payment_reference,
        paid_at=order.paid_at,
        total_amount=float(order.total_amount),
        created_at=order.created_at,
        updated_at=order.updated_at,
        items=[
            AdminOrderItem(
                id=item.id,
                order_id=item.order_id,
                food_item_id=item.food_item_id,
                item_name=item.item_name,
                unit_price=float(item.unit_price),
                quantity=item.quantity,
                subtotal=float(item.subtotal),
                created_at=item.created_at,
            )
            for item in order.items
        ],
        customer=AdminOrderCustomer(
            id=customer.id,
            name=customer.name,
            email=customer.email,
        ),
    )


@router.get("/", response_model=List[AdminOrderResponse])
def list_all_orders(
    status_filter: Optional[OrderStatus] = Query(default=None, alias="status"),
    customer_id: Optional[str] = Query(default=None),
    db: Session = Depends(get_db),
    admin: User = Depends(get_admin_user),
):
    """
    List every customer's orders, newest first, optionally filtered by status
    or by customer (ADMIN only).
    """
    query = db.query(Order).options(
        joinedload(Order.items),
        joinedload(Order.user),
    )

    if status_filter:
        query = query.filter(Order.status == status_filter)

    if customer_id:
        query = query.filter(Order.user_id == customer_id)

    orders = query.order_by(desc(Order.created_at)).all()
    return [_to_admin_order(o, o.user) for o in orders]


@router.get("/{order_id}", response_model=AdminOrderResponse)
def get_admin_order(
    order_id: str,
    db: Session = Depends(get_db),
    admin: User = Depends(get_admin_user),
):
    """
    Open a single order with its customer details and line items (ADMIN only).
    """
    order = (
        db.query(Order)
        .options(joinedload(Order.items), joinedload(Order.user))
        .filter(Order.id == order_id)
        .first()
    )

    if not order:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Order not found",
        )

    return _to_admin_order(order, order.user)


@router.patch("/{order_id}/status", response_model=AdminOrderResponse)
def update_admin_order_status(
    order_id: str,
    status_update: OrderStatusUpdate,
    db: Session = Depends(get_db),
    admin: User = Depends(get_admin_user),
):
    """
    Advance an order's status through the canonical lifecycle
    PLACED → ACCEPTED → PREPARING → READY → COMPLETED, with CANCELLED
    permitted where the existing state machine allows it (ADMIN only).

    The customer's own order endpoint reads the same row, so a status change
    here is immediately visible in their My Orders / Order Details screen.
    """
    order = (
        db.query(Order)
        .options(joinedload(Order.items), joinedload(Order.user))
        .filter(Order.id == order_id)
        .first()
    )

    if not order:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Order not found",
        )

    current_status = order.status
    new_status = status_update.status

    # Idempotent: re-sending the current status is a no-op, not an error.
    if current_status == new_status:
        return _to_admin_order(order, order.user)

    if new_status == "COMPLETED" and order.payment_status != "PAID":
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Cash payment must be confirmed before completing the order",
        )

    allowed_next = VALID_TRANSITIONS.get(current_status, set())
    if new_status not in allowed_next:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Invalid transition from {current_status} to {new_status}",
        )

    order.status = new_status
    db.commit()
    db.refresh(order)

    # Restore stock when an order is cancelled before completion.
    if new_status == "CANCELLED":
        for item in order.items:
            if item.food_item is not None:
                item.food_item.stock += item.quantity
                if item.food_item.stock > 0:
                    item.food_item.is_available = True
        db.commit()
        db.refresh(order)

    return _to_admin_order(order, order.user)
