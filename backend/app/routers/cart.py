from decimal import Decimal

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session, joinedload

from app.core.dependencies import get_current_user
from app.db.database import get_db
from app.models.cart import Cart, CartItem
from app.models.food_item import FoodItem
from app.models.user import User
from app.schemas.cart import CartItemAdd, CartItemUpdate, CartResponse, CartItemResponse

router = APIRouter(prefix="/api/cart", tags=["cart"])

def get_cart_response(cart: Cart) -> CartResponse:
    items_response = []
    total = Decimal("0.0")
    for item in cart.items:
        food_item = item.food_item
        subtotal = food_item.price * item.quantity
        total += subtotal
        items_response.append(
            CartItemResponse(
                id=item.id,
                food_item_id=food_item.id,
                name=food_item.name,
                description=food_item.description,
                image_url=food_item.image_url,
                unit_price=float(food_item.price),
                quantity=item.quantity,
                subtotal=float(subtotal),
                is_available=food_item.is_available,
            )
        )
    return CartResponse(id=cart.id, items=items_response, total=float(total))


@router.get("", response_model=CartResponse)
def get_cart(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    cart = (
        db.query(Cart)
        .options(joinedload(Cart.items).joinedload(CartItem.food_item))
        .filter(Cart.user_id == current_user.id)
        .first()
    )

    if not cart:
        cart = Cart(user_id=current_user.id)
        db.add(cart)
        db.commit()
        db.refresh(cart)

    return get_cart_response(cart)


@router.post("/items", response_model=CartResponse)
def add_to_cart(
    item_in: CartItemAdd,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    food_item = (
        db.query(FoodItem)
        .options(joinedload(FoodItem.category))
        .filter(FoodItem.id == item_in.food_item_id)
        .first()
    )
    if not food_item:
        raise HTTPException(status_code=404, detail="Food item not found")
    if not food_item.is_available:
        raise HTTPException(status_code=400, detail="Food item is not available")
    if not food_item.category.is_active:
        raise HTTPException(status_code=400, detail="Food item category is not active")

    cart = (
        db.query(Cart)
        .options(joinedload(Cart.items).joinedload(CartItem.food_item))
        .filter(Cart.user_id == current_user.id)
        .first()
    )

    if not cart:
        cart = Cart(user_id=current_user.id)
        db.add(cart)
        db.commit()
        db.refresh(cart)

    existing_item = next((i for i in cart.items if i.food_item_id == item_in.food_item_id), None)

    if existing_item:
        existing_item.quantity += item_in.quantity
    else:
        new_item = CartItem(
            cart_id=cart.id,
            food_item_id=item_in.food_item_id,
            quantity=item_in.quantity
        )
        db.add(new_item)
        cart.items.append(new_item)

    db.commit()
    db.refresh(cart)

    return get_cart_response(cart)


@router.patch("/items/{cart_item_id}", response_model=CartResponse)
def update_cart_item(
    cart_item_id: str,
    item_in: CartItemUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    cart = (
        db.query(Cart)
        .options(joinedload(Cart.items).joinedload(CartItem.food_item))
        .filter(Cart.user_id == current_user.id)
        .first()
    )

    if not cart:
        raise HTTPException(status_code=404, detail="Cart item not found")

    cart_item = next((i for i in cart.items if i.id == cart_item_id), None)
    if not cart_item:
        raise HTTPException(status_code=404, detail="Cart item not found")

    cart_item.quantity = item_in.quantity
    db.commit()
    db.refresh(cart)

    return get_cart_response(cart)


@router.delete("/items/{cart_item_id}", response_model=CartResponse)
def delete_cart_item(
    cart_item_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    cart = (
        db.query(Cart)
        .options(joinedload(Cart.items).joinedload(CartItem.food_item))
        .filter(Cart.user_id == current_user.id)
        .first()
    )

    if not cart:
        raise HTTPException(status_code=404, detail="Cart item not found")

    cart_item = next((i for i in cart.items if i.id == cart_item_id), None)
    if not cart_item:
        raise HTTPException(status_code=404, detail="Cart item not found")

    db.delete(cart_item)
    db.commit()
    db.refresh(cart)

    return get_cart_response(cart)


@router.delete("", response_model=CartResponse)
def clear_cart(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    cart = (
        db.query(Cart)
        .options(joinedload(Cart.items).joinedload(CartItem.food_item))
        .filter(Cart.user_id == current_user.id)
        .first()
    )

    if not cart:
        cart = Cart(user_id=current_user.id)
        db.add(cart)
        db.commit()
        db.refresh(cart)
        return get_cart_response(cart)

    for item in cart.items:
        db.delete(item)

    db.commit()
    db.refresh(cart)

    return get_cart_response(cart)
