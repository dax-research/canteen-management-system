from decimal import Decimal
from typing import List

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session, joinedload
from sqlalchemy import desc

from app.core.dependencies import get_current_user
from app.db.database import get_db
from app.models.cart import Cart, CartItem
from app.models.order import Order, OrderItem
from app.models.user import User
from app.models.food_item import FoodItem
from app.schemas.order import OrderResponse

router = APIRouter(prefix="/api/orders", tags=["orders"])


@router.post("", response_model=OrderResponse, status_code=status.HTTP_201_CREATED)
def place_order(
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

        unit_price = food_item.price
        subtotal = unit_price * item.quantity
        total_amount += subtotal

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
