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
        "name": "Customer User",
        "email": f"customer_{uuid.uuid4()}@example.com",
        "password": "password123"
    }
    u2_data = {
        "name": "Staff User",
        "email": f"staff_{uuid.uuid4()}@example.com",
        "password": "password123"
    }

    # Register users
    request("POST", "/api/auth/register", data=u1_data)
    request("POST", "/api/auth/register", data=u2_data)

    print("Logging in...")
    login1 = request("POST", "/api/auth/login", data={"email": u1_data["email"], "password": "password123"})
    login2 = request("POST", "/api/auth/login", data={"email": u2_data["email"], "password": "password123"})

    token1 = login1["access_token"]
    user1_id = login1["user"]["id"]
    headers_customer = {"Authorization": f"Bearer {token1}"}

    token2 = login2["access_token"]
    user2_id = login2["user"]["id"]
    headers_staff = {"Authorization": f"Bearer {token2}"}

    from app.db.database import SessionLocal
    from app.models.category import Category
    from app.models.food_item import FoodItem
    from app.models.order import Order, OrderItem
    from app.models.user import User

    db = SessionLocal()
    category_ids = []
    food_ids = []

    try:
        # A. Role defaults
        print("A. Verify role defaults...")
        customer_user = db.query(User).filter(User.id == user1_id).first()
        assert customer_user.role == "CUSTOMER", f"Expected CUSTOMER role, got {customer_user.role}"

        # Escalate user2 to STAFF manually in DB for testing
        staff_user = db.query(User).filter(User.id == user2_id).first()
        staff_user.role = "STAFF"
        db.commit()

        # Create test categories and food items
        cat1 = Category(name=f"Cat_Active_{uuid.uuid4()}", description="Active Category", is_active=True)
        db.add(cat1)
        db.commit()
        db.refresh(cat1)
        category_ids.append(cat1.id)

        food1 = FoodItem(category_id=cat1.id, name="Test Pizza", price=10.00, is_available=True, stock=100)
        db.add(food1)
        db.commit()
        db.refresh(food1)
        food_ids.append(food1.id)

        # Place an order as customer
        request("POST", "/api/cart/items", data={"food_item_id": food1.id, "quantity": 1}, headers=headers_customer)
        order1 = request("POST", "/api/orders", headers=headers_customer)
        assert order1.get("error") is None, f"Checkout failed: {order1}"
        order1_id = order1["id"]

        time.sleep(0.1)

        request("POST", "/api/cart/items", data={"food_item_id": food1.id, "quantity": 2}, headers=headers_customer)
        order2 = request("POST", "/api/orders", headers=headers_customer)
        order2_id = order2["id"]

        # B. Authorization
        print("B. Verify Authorization...")
        res = request("GET", "/api/orders/staff")
        assert res.get("error") is True and res["status"] == 401, "Unauthenticated access should be rejected"

        res = request("GET", "/api/orders/staff", headers=headers_customer)
        assert res.get("error") is True and res["status"] == 403, "CUSTOMER access should be forbidden"

        # C. Staff order listing
        print("C. Verify Staff order listing...")
        res = request("GET", "/api/orders/staff", headers=headers_staff)
        assert type(res) is list, "Staff should get a list of orders"
        assert len(res) >= 2
        # Check newest first
        assert res[0]["id"] == order2_id
        assert res[1]["id"] == order1_id

        # Check status filter
        res = request("GET", "/api/orders/staff?status=PLACED", headers=headers_staff)
        assert all(o["status"] == "PLACED" for o in res), "Filter by status failed"

        # Check invalid status filter
        res = request("GET", "/api/orders/staff?status=INVALID", headers=headers_staff)
        assert res.get("error") is True and res["status"] == 422, "Invalid status filter should return 422"

        # D. Staff order detail
        print("D. Verify Staff order detail...")
        res = request("GET", f"/api/orders/staff/{order1_id}", headers=headers_staff)
        assert res["id"] == order1_id, "Should fetch specific order detail"

        res = request("GET", f"/api/orders/staff/nonexistent_id", headers=headers_staff)
        assert res.get("error") is True and res["status"] == 404, "Nonexistent order returns 404"

        # E. Valid transitions
        print("E. Verify valid transitions...")
        # PLACED -> ACCEPTED
        res = request("PATCH", f"/api/orders/staff/{order1_id}/status", data={"status": "ACCEPTED"}, headers=headers_staff)
        assert res["status"] == "ACCEPTED"

        # ACCEPTED -> PREPARING
        res = request("PATCH", f"/api/orders/staff/{order1_id}/status", data={"status": "PREPARING"}, headers=headers_staff)
        assert res["status"] == "PREPARING"

        # PREPARING -> READY
        res = request("PATCH", f"/api/orders/staff/{order1_id}/status", data={"status": "READY"}, headers=headers_staff)
        assert res["status"] == "READY"

        # READY -> COMPLETED
        res = request("PATCH", f"/api/orders/staff/{order1_id}/status", data={"status": "COMPLETED"}, headers=headers_staff)
        assert res["status"] == "COMPLETED"

        # Cancellation transition
        res = request("PATCH", f"/api/orders/staff/{order2_id}/status", data={"status": "CANCELLED"}, headers=headers_staff)
        assert res["status"] == "CANCELLED"

        # F. Invalid transitions
        print("F. Verify invalid transitions...")
        # PLACED -> PREPARING
        request("POST", "/api/cart/items", data={"food_item_id": food1.id, "quantity": 1}, headers=headers_customer)
        order3 = request("POST", "/api/orders", headers=headers_customer)
        order3_id = order3["id"]

        res = request("PATCH", f"/api/orders/staff/{order3_id}/status", data={"status": "PREPARING"}, headers=headers_staff)
        assert res.get("error") is True and res["status"] == 400

        # COMPLETED -> PREPARING
        res = request("PATCH", f"/api/orders/staff/{order1_id}/status", data={"status": "PREPARING"}, headers=headers_staff)
        assert res.get("error") is True and res["status"] == 400

        # CANCELLED -> ACCEPTED
        res = request("PATCH", f"/api/orders/staff/{order2_id}/status", data={"status": "ACCEPTED"}, headers=headers_staff)
        assert res.get("error") is True and res["status"] == 400

        # Invalid string
        res = request("PATCH", f"/api/orders/staff/{order3_id}/status", data={"status": "INVALID"}, headers=headers_staff)
        assert res.get("error") is True and res["status"] == 422 # Pydantic validation error

        # G. Data integrity
        print("G. Verify data integrity...")
        order3_detail = request("GET", f"/api/orders/staff/{order3_id}", headers=headers_staff)
        # Update status
        request("PATCH", f"/api/orders/staff/{order3_id}/status", data={"status": "ACCEPTED"}, headers=headers_staff)
        order3_updated = request("GET", f"/api/orders/staff/{order3_id}", headers=headers_staff)

        assert order3_detail["total_amount"] == order3_updated["total_amount"]
        assert len(order3_detail["items"]) == len(order3_updated["items"])
        assert order3_detail["items"][0]["item_name"] == order3_updated["items"][0]["item_name"]
        assert order3_detail["items"][0]["unit_price"] == order3_updated["items"][0]["unit_price"]

        # H. Security
        print("H. Verify Customer isolation...")
        res = request("PATCH", f"/api/orders/staff/{order3_id}/status", data={"status": "PREPARING"}, headers=headers_customer)
        assert res.get("error") is True and res["status"] == 403

        print("All requirements verified successfully!")

    finally:
        # Cleanup
        print("Cleaning up test data...")
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
