import json
import time
import urllib.error
import urllib.request
import uuid

BASE_URL = "http://localhost:8000"

def request(method, path, data=None, headers=None):
    if headers is None:
        headers = {}

    req_data = None
    if data is not None:
        req_data = json.dumps(data).encode("utf-8")
        headers["Content-Type"] = "application/json"

    req = urllib.request.Request(f"{BASE_URL}{path}", data=req_data, headers=headers, method=method)

    try:
        with urllib.request.urlopen(req) as response:
            res_body = response.read()
            if res_body:
                return json.loads(res_body)
            return {}
    except urllib.error.HTTPError as e:
        body = e.read().decode("utf-8")
        try:
            body = json.loads(body)
        except Exception:
            pass
        return {"error": True, "status": e.code, "body": body}

def test_api():
    print("Registering test users...")
    u1_data = {
        "name": "Test User 1",
        "email": f"testuser1_{uuid.uuid4()}@example.com",
        "password": "password123"
    }
    u2_data = {
        "name": "Test User 2",
        "email": f"testuser2_{uuid.uuid4()}@example.com",
        "password": "password123"
    }

    request("POST", "/api/auth/register", data=u1_data)
    request("POST", "/api/auth/register", data=u2_data)

    print("Logging in...")
    login1 = request("POST", "/api/auth/login", data={"email": u1_data["email"], "password": "password123"})
    login2 = request("POST", "/api/auth/login", data={"email": u2_data["email"], "password": "password123"})

    token1 = login1["access_token"]
    user1_id = login1["user"]["id"]
    headers1 = {"Authorization": f"Bearer {token1}"}

    token2 = login2["access_token"]
    user2_id = login2["user"]["id"]
    headers2 = {"Authorization": f"Bearer {token2}"}

    from sqlalchemy.exc import IntegrityError
    from app.db.database import SessionLocal
    from app.models.category import Category
    from app.models.food_item import FoodItem
    from app.models.order import Order, OrderItem
    from app.models.user import User

    db = SessionLocal()
    category_ids = []
    food_ids = []

    try:
        # Create test categories
        cat1 = Category(name=f"Cat_Active_{uuid.uuid4()}", description="Active Category", is_active=True)
        cat2 = Category(name=f"Cat_Inactive_{uuid.uuid4()}", description="Will become inactive", is_active=True)
        db.add_all([cat1, cat2])
        db.commit()
        db.refresh(cat1)
        db.refresh(cat2)
        category_ids.extend([cat1.id, cat2.id])

        # Create test food items
        food1 = FoodItem(category_id=cat1.id, name="Test Pizza", price=12.50, is_available=True)
        food2 = FoodItem(category_id=cat1.id, name="Test Burger", price=8.00, is_available=True)
        food3 = FoodItem(category_id=cat1.id, name="Test Salad", price=5.00, is_available=True)
        food4 = FoodItem(category_id=cat2.id, name="Test Soda", price=2.00, is_available=True)

        db.add_all([food1, food2, food3, food4])
        db.commit()
        for f in [food1, food2, food3, food4]:
            db.refresh(f)
        food_ids.extend([food1.id, food2.id, food3.id, food4.id])

        # 1. Empty cart checkout
        print("1. Empty cart checkout...")
        res = request("POST", "/api/orders", headers=headers1)
        assert res.get("error") is True and res["status"] == 400, f"Expected 400 for empty cart, got {res}"

        # 2. Unavailable item checkout (Cart API only allows adding available items, so we mutate it after adding)
        print("2. Unavailable item checkout...")
        request("POST", "/api/cart/items", data={"food_item_id": food3.id, "quantity": 1}, headers=headers1)
        db.query(FoodItem).filter(FoodItem.id == food3.id).update({"is_available": False})
        db.commit()

        res = request("POST", "/api/orders", headers=headers1)
        assert res.get("error") is True and res["status"] == 400, "Should reject checkout if an item became unavailable"

        # 10. Failed checkout leaves cart intact
        print("10. Failed checkout leaves cart intact...")
        cart = request("GET", "/api/cart", headers=headers1)
        assert len(cart["items"]) == 1, "Cart should remain intact after failed checkout"
        assert cart["items"][0]["food_item_id"] == food3.id

        # 3. Inactive category checkout
        print("3. Inactive category checkout...")
        request("DELETE", "/api/cart", headers=headers1) # clear cart
        request("POST", "/api/cart/items", data={"food_item_id": food4.id, "quantity": 1}, headers=headers1)
        db.query(Category).filter(Category.id == cat2.id).update({"is_active": False})
        db.commit()

        res = request("POST", "/api/orders", headers=headers1)
        assert res.get("error") is True and res["status"] == 400, "Should reject checkout if an item's category became inactive"

        # Build a fresh, valid cart for the main successful checkout
        request("DELETE", "/api/cart", headers=headers1)
        request("POST", "/api/cart/items", data={"food_item_id": food1.id, "quantity": 2}, headers=headers1) # 2 * 12.50 = 25.0
        request("POST", "/api/cart/items", data={"food_item_id": food2.id, "quantity": 1}, headers=headers1) # 1 * 8.00 = 8.0

        # 4. Successful checkout creates an order with status PLACED
        print("4, 8, 9. Successful checkout & Cart Clear...")
        order1 = request("POST", "/api/orders", headers=headers1)
        assert order1.get("error") is None, f"Checkout failed: {order1}"
        assert order1["status"] == "PLACED"

        # 8. Order total and item subtotal are calculated correctly
        assert order1["total_amount"] == 33.0
        assert len(order1["items"]) == 2

        # 9. CartItems are cleared after successful checkout
        cart = request("GET", "/api/cart", headers=headers1)
        assert len(cart["items"]) == 0
        assert cart["total"] == 0.0

        # 5, 6, 7. Snapshotting Verification
        print("5, 6, 7. Item name/price snapshotting...")
        db.query(FoodItem).filter(FoodItem.id == food1.id).update({"name": "Altered Pizza", "price": 99.99})
        db.commit()

        fetched_order1 = request("GET", f"/api/orders/{order1['id']}", headers=headers1)
        snapshot_item = next(item for item in fetched_order1["items"] if item["food_item_id"] == food1.id)
        assert snapshot_item["item_name"] == "Test Pizza", "Order item name was NOT snapshotted!"
        assert snapshot_item["unit_price"] == 12.50, "Order item unit_price was NOT snapshotted!"

        # Prepare a second order to test retrieving lists
        time.sleep(0.1) # Ensure ordering by timestamp works correctly if timestamps round
        request("POST", "/api/cart/items", data={"food_item_id": food2.id, "quantity": 1}, headers=headers1)
        order2 = request("POST", "/api/orders", headers=headers1)

        # 11, 13. User can retrieve their own orders, newest-first
        print("11, 13. Retrieve orders newest-first...")
        orders = request("GET", "/api/orders", headers=headers1)
        assert len(orders) >= 2
        assert orders[0]["id"] == order2["id"], "Orders are not sorted newest-first"
        assert orders[1]["id"] == order1["id"]

        # 12. User cannot retrieve another user's order
        print("12. Authorization isolation...")
        res = request("GET", f"/api/orders/{order1['id']}", headers=headers2)
        assert res.get("error") is True and res["status"] == 404

        # 14. Database constraints
        print("14. Database constraints (negative values)...")
        try:
            invalid_order = Order(user_id=user1_id, status="PLACED", total_amount=-5.0)
            db.add(invalid_order)
            db.commit()
            assert False, "Should have rejected negative total_amount"
        except IntegrityError:
            db.rollback()

        try:
            valid_order = Order(user_id=user1_id, status="PLACED", total_amount=10.0)
            db.add(valid_order)
            db.flush()
            invalid_item = OrderItem(
                order_id=valid_order.id,
                item_name="Test",
                unit_price=10.0,
                quantity=-1,
                subtotal=10.0
            )
            db.add(invalid_item)
            db.commit()
            assert False, "Should have rejected negative quantity"
        except IntegrityError:
            db.rollback()

        print("All requirements verified successfully!")

    finally:
        # 15. Cleanup
        print("15. Cleaning up test data...")
        db.rollback()

        db.query(OrderItem).filter(
            OrderItem.order_id.in_(db.query(Order.id).filter(Order.user_id.in_([user1_id, user2_id])))
        ).delete(synchronize_session=False)
        db.query(Order).filter(Order.user_id.in_([user1_id, user2_id])).delete(synchronize_session=False)

        from app.models.cart import Cart, CartItem
        db.query(CartItem).filter(
            CartItem.cart_id.in_(db.query(Cart.id).filter(Cart.user_id.in_([user1_id, user2_id])))
        ).delete(synchronize_session=False)
        db.query(Cart).filter(Cart.user_id.in_([user1_id, user2_id])).delete(synchronize_session=False)

        if food_ids:
            db.query(FoodItem).filter(FoodItem.id.in_(food_ids)).delete(synchronize_session=False)
        if category_ids:
            db.query(Category).filter(Category.id.in_(category_ids)).delete(synchronize_session=False)

        db.query(User).filter(User.id.in_([user1_id, user2_id])).delete(synchronize_session=False)

        db.commit()
        db.close()

if __name__ == "__main__":
    test_api()
