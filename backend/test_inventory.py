import json
import urllib.request
import urllib.error
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
    print("Registering users...")
    customer_data = {
        "name": "Inventory Customer",
        "email": f"customer_{uuid.uuid4()}@example.com",
        "password": "password123"
    }
    staff_data = {
        "name": "Inventory Staff",
        "email": f"staff_{uuid.uuid4()}@example.com",
        "password": "password123"
    }
    admin_data = {
        "name": "Inventory Admin",
        "email": f"admin_{uuid.uuid4()}@example.com",
        "password": "password123"
    }

    request("POST", "/api/auth/register", data=customer_data)
    request("POST", "/api/auth/register", data=staff_data)
    request("POST", "/api/auth/register", data=admin_data)

    print("Logging in...")
    login_cust = request("POST", "/api/auth/login", data={"email": customer_data["email"], "password": "password123"})
    login_staff = request("POST", "/api/auth/login", data={"email": staff_data["email"], "password": "password123"})
    login_admin = request("POST", "/api/auth/login", data={"email": admin_data["email"], "password": "password123"})

    token_cust = login_cust["access_token"]
    user_cust_id = login_cust["user"]["id"]
    headers_cust = {"Authorization": f"Bearer {token_cust}"}

    token_staff = login_staff["access_token"]
    user_staff_id = login_staff["user"]["id"]
    headers_staff = {"Authorization": f"Bearer {token_staff}"}

    token_admin = login_admin["access_token"]
    user_admin_id = login_admin["user"]["id"]
    headers_admin = {"Authorization": f"Bearer {token_admin}"}

    from app.db.database import SessionLocal
    from app.models.category import Category
    from app.models.food_item import FoodItem
    from app.models.user import User

    db = SessionLocal()

    try:
        # Elevate staff and admin users
        staff_user = db.query(User).filter(User.id == user_staff_id).first()
        staff_user.role = "STAFF"
        admin_user = db.query(User).filter(User.id == user_admin_id).first()
        admin_user.role = "ADMIN"
        db.commit()

        # Seed data
        cat = Category(name=f"Cat_{uuid.uuid4()}", description="Test", is_active=True)
        db.add(cat)
        db.commit()
        db.refresh(cat)

        food = FoodItem(category_id=cat.id, name="Test Food", price=10.0, is_available=True, stock=5)
        db.add(food)
        db.commit()
        db.refresh(food)

        cat_id = cat.id
        food_id = food.id

        # Authentication tests
        print("Testing auth...")
        res = request("GET", "/api/inventory")
        assert res.get("error") is True and res["status"] == 401

        res = request("GET", "/api/inventory", headers=headers_cust)
        assert res.get("error") is True and res["status"] == 403

        # ADMIN must be allowed (same as STAFF)
        res = request("GET", "/api/inventory", headers=headers_admin)
        assert isinstance(res, list), f"ADMIN should get 200 list, got: {res}"

        # Retrieve inventory
        print("Testing retrieve...")
        res = request("GET", "/api/inventory", headers=headers_staff)
        assert type(res) is list
        assert any(item["id"] == food_id for item in res)

        res = request("GET", f"/api/inventory/{food_id}", headers=headers_staff)
        assert res["id"] == food_id
        assert res["stock"] == 5
        assert res["is_available"] is True

        res = request("GET", "/api/inventory/nonexistent_id", headers=headers_staff)
        assert res.get("error") is True and res["status"] == 404

        # Update stock
        print("Testing update...")
        res = request("PATCH", f"/api/inventory/{food_id}", data={"stock": 10}, headers=headers_staff)
        assert res["stock"] == 10
        assert res["is_available"] is True

        res = request("PATCH", f"/api/inventory/{food_id}", data={"stock": 0}, headers=headers_staff)
        assert res["stock"] == 0
        assert res["is_available"] is False

        # Reset stock for checkout test
        request("PATCH", f"/api/inventory/{food_id}", data={"stock": 2}, headers=headers_staff)

        # Checkout integration
        print("Testing checkout validation...")
        request("POST", "/api/cart/items", data={"food_item_id": food_id, "quantity": 3}, headers=headers_cust)
        res = request("POST", "/api/orders", headers=headers_cust)
        assert res.get("error") is True and res["status"] == 400

        # Verify no partial deduction
        res = request("GET", f"/api/inventory/{food_id}", headers=headers_staff)
        assert res["stock"] == 2

        # Success checkout
        # empty cart first, wait cart api doesnt have a clear cart item, actually DELETE /api/cart does
        request("DELETE", "/api/cart", headers=headers_cust)
        request("POST", "/api/cart/items", data={"food_item_id": food_id, "quantity": 2}, headers=headers_cust)
        res = request("POST", "/api/orders", headers=headers_cust)
        assert res.get("error") is None
        assert res["status"] == "PLACED"

        # Verify deduction
        res = request("GET", f"/api/inventory/{food_id}", headers=headers_staff)
        assert res["stock"] == 0
        assert res["is_available"] is False

        # Negative stock test
        print("Testing negative stock...")
        res = request("PATCH", f"/api/inventory/{food_id}", data={"stock": -5}, headers=headers_staff)
        assert res.get("error") is True and res["status"] == 422

        print("All inventory tests passed!")

    finally:
        # Cleanup
        print("Cleaning up test data...")
        db.rollback()

        from app.models.order import Order, OrderItem
        from app.models.cart import Cart, CartItem

        # We need to manually query the items created.
        db.query(OrderItem).filter(
            OrderItem.order_id.in_(db.query(Order.id).filter(Order.user_id.in_([user_cust_id, user_staff_id, user_admin_id])))
        ).delete(synchronize_session=False)
        db.query(Order).filter(Order.user_id.in_([user_cust_id, user_staff_id, user_admin_id])).delete(synchronize_session=False)

        db.query(CartItem).filter(
            CartItem.cart_id.in_(db.query(Cart.id).filter(Cart.user_id.in_([user_cust_id, user_staff_id, user_admin_id])))
        ).delete(synchronize_session=False)
        db.query(Cart).filter(Cart.user_id.in_([user_cust_id, user_staff_id, user_admin_id])).delete(synchronize_session=False)

        db.query(FoodItem).filter(FoodItem.id == food_id).delete(synchronize_session=False)
        db.query(Category).filter(Category.id == cat_id).delete(synchronize_session=False)
        db.query(User).filter(User.id.in_([user_cust_id, user_staff_id, user_admin_id])).delete(synchronize_session=False)

        db.commit()
        db.close()

if __name__ == "__main__":
    test_api()
