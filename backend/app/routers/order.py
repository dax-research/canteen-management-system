from decimal import Decimal
from typing import List

from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session, joinedload
from sqlalchemy import desc

from app.core.dependencies import get_current_user, get_staff_user
from app.db.database import get_db
from app.models.cart import Cart, CartItem
from app.models.order import Order, OrderItem
from app.models.user import User
from app.models.food_item import FoodItem
from app.schemas.order import OrderCreate, OrderResponse, OrderStatusUpdate, OrderStatus

VALID_TRANSITIONS = {
    "PLACED": {"ACCEPTED", "CANCELLED"},
    "ACCEPTED": {"PREPARING", "CANCELLED"},
    "PREPARING": {"READY", "CANCELLED"},
    "READY": {"COMPLETED"},
    "COMPLETED": set(),
    "CANCELLED": set(),
}

router = APIRouter(prefix="/api/orders", tags=["orders"])


def _default_pickup_time() -> str:
    return "ASAP"


def _default_eta_minutes(pickup_time: str | None) -> int:
    return 15 if pickup_time is None or pickup_time.upper() == "ASAP" else 20


@router.post("", response_model=OrderResponse, status_code=status.HTTP_201_CREATED)
def place_order(
    order_in: OrderCreate | None = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    cart = (
        db.query(Cart)
        .options(joinedload(Cart.items).joinedload(CartItem.food_item).joinedload(FoodItem.category))
        .filter(Cart.user_id == current_user.id)
        .first()
    )

    if not cart or not cart.items:
        raise HTTPException(status_code=400, detail="Cart is empty")

    if order_in is None:
        order_in = OrderCreate()

    pickup_time = order_in.pickup_time or _default_pickup_time()
    eta_minutes = order_in.eta_minutes or _default_eta_minutes(pickup_time)

    total_amount = Decimal("0.00")
    order_items = []

    for item in cart.items:
        food_item = item.food_item
        if not food_item:
            raise HTTPException(status_code=400, detail="A food item in the cart no longer exists")
        if not food_item.is_available:
            raise HTTPException(status_code=400, detail=f"Food item '{food_item.name}' is not available")
        if not food_item.category.is_active:
            raise HTTPException(status_code=400, detail=f"Category for '{food_item.name}' is not active")
        if item.quantity > food_item.stock:
            raise HTTPException(status_code=400, detail=f"Requested quantity for '{food_item.name}' exceeds available stock")

        unit_price = food_item.price
        subtotal = unit_price * item.quantity
        total_amount += subtotal

        # Deduct stock
        food_item.stock -= item.quantity
        if food_item.stock == 0:
            food_item.is_available = False

        order_item = OrderItem(
            food_item_id=food_item.id,
            item_name=food_item.name,
            unit_price=unit_price,
            quantity=item.quantity,
            subtotal=subtotal,
        )
        order_items.append(order_item)

    # Create Order
    order = Order(
        user_id=current_user.id,
        status="PLACED",
        order_type=order_in.order_type,
        pickup_time=pickup_time,
        eta_minutes=eta_minutes,
        total_amount=total_amount,
        items=order_items,
    )
    db.add(order)

    # Clear CartItems
    for item in cart.items:
        db.delete(item)

    # Commit as one transaction
    db.commit()
    db.refresh(order)

    return order


@router.get("", response_model=List[OrderResponse])
def get_orders(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    orders = (
        db.query(Order)
        .options(joinedload(Order.items))
        .filter(Order.user_id == current_user.id)
        .order_by(desc(Order.created_at))
        .all()
    )
    return orders


@router.get("/staff", response_model=List[OrderResponse])
def get_staff_orders(
    status_filter: OrderStatus | None = Query(default=None, alias="status"),
    db: Session = Depends(get_db),
    staff_user: User = Depends(get_staff_user),
):
    query = db.query(Order).options(joinedload(Order.items))
    if status_filter:
        query = query.filter(Order.status == status_filter)

    orders = query.order_by(desc(Order.created_at)).all()
    return orders

@router.get("/staff/{order_id}", response_model=OrderResponse)
def get_staff_order(
    order_id: str,
    db: Session = Depends(get_db),
    staff_user: User = Depends(get_staff_user),
):
    order = (
        db.query(Order)
        .options(joinedload(Order.items))
        .filter(Order.id == order_id)
        .first()
    )

    if not order:
        raise HTTPException(status_code=404, detail="Order not found")

    return order

@router.patch("/staff/{order_id}/status", response_model=OrderResponse)
def update_order_status(
    order_id: str,
    status_update: OrderStatusUpdate,
    db: Session = Depends(get_db),
    staff_user: User = Depends(get_staff_user),
):
    order = (
        db.query(Order)
        .options(joinedload(Order.items))
        .filter(Order.id == order_id)
        .first()
    )

    if not order:
        raise HTTPException(status_code=404, detail="Order not found")

    current_status = order.status
    new_status = status_update.status

    if current_status == new_status:
        return order

    allowed_next = VALID_TRANSITIONS.get(current_status, set())
    if new_status not in allowed_next:
        raise HTTPException(
            status_code=400,
            detail=f"Invalid transition from {current_status} to {new_status}"
        )

    order.status = new_status
    db.commit()
    db.refresh(order)
    return order


@router.get("/{order_id}", response_model=OrderResponse)
def get_order(
    order_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    order = (
        db.query(Order)
        .options(joinedload(Order.items))
        .filter(Order.id == order_id)
        .first()
    )

    if not order:
        raise HTTPException(status_code=404, detail="Order not found")

    if order.user_id != current_user.id:
        raise HTTPException(status_code=404, detail="Order not found")

    return order
