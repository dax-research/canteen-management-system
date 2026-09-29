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
        print(f"HTTP Error {e.code}: {e.read().decode('utf-8')}")
        raise

def test_api():
    # 1. Register a new user
    print("Registering user...")
    user_data = {
        "name": "Test User",
        "email": f"testuser_{uuid.uuid4()}@example.com",
        "password": "password123"
    }
    request("POST", "/api/auth/register", data=user_data)

    # 2. Login
    print("Logging in...")
    login_res = request("POST", "/api/auth/login", data={"email": user_data["email"], "password": "password123"})
    token = login_res["access_token"]
    user_id = login_res["user"]["id"]
    headers = {"Authorization": f"Bearer {token}"}

    # 3. Create a category
    print("Creating category...")
    from app.db.database import SessionLocal
    from app.models.category import Category
    from app.models.food_item import FoodItem

    db = SessionLocal()
    cat = Category(name=f"Cat_{uuid.uuid4()}", description="Test", is_active=True)
    db.add(cat)
    db.commit()
    db.refresh(cat)

    food = FoodItem(category_id=cat.id, name="Test Food", price=10.50, is_available=True, stock=100)
    db.add(food)
    db.commit()
    db.refresh(food)

    cat_id = cat.id
    food_id = food.id
    db.close()

    # 4. GET empty cart
    print("Getting empty cart...")
    cart = request("GET", "/api/cart", headers=headers)
    assert len(cart["items"]) == 0
    assert cart["total"] == 0.0

    # 5. POST add item
    print("Adding item...")
    cart = request("POST", "/api/cart/items", data={"food_item_id": food_id, "quantity": 2}, headers=headers)
    assert len(cart["items"]) == 1
    assert cart["items"][0]["quantity"] == 2
    assert cart["total"] == 21.0

    # 6. POST same item again -> quantity increases
    print("Adding same item...")
    cart = request("POST", "/api/cart/items", data={"food_item_id": food_id, "quantity": 3}, headers=headers)
    assert len(cart["items"]) == 1
    assert cart["items"][0]["quantity"] == 5
    assert cart["total"] == 52.5

    cart_item_id = cart["items"][0]["id"]

    # 7. PATCH quantity
    print("Updating quantity...")
    cart = request("PATCH", f"/api/cart/items/{cart_item_id}", data={"quantity": 1}, headers=headers)
    assert cart["items"][0]["quantity"] == 1
    assert cart["total"] == 10.5

    # 8. DELETE cart item
    print("Deleting cart item...")
    cart = request("DELETE", f"/api/cart/items/{cart_item_id}", headers=headers)
    assert len(cart["items"]) == 0
    assert cart["total"] == 0.0

    # 9. POST add item again to test clear cart
    print("Adding item for clear cart test...")
    request("POST", "/api/cart/items", data={"food_item_id": food_id, "quantity": 1}, headers=headers)

    # 10. DELETE entire cart
    print("Clearing cart...")
    cart = request("DELETE", "/api/cart", headers=headers)
    assert len(cart["items"]) == 0

    print("All tests passed!")

    # Cleanup
    db = SessionLocal()
    from app.models.user import User
    from app.models.cart import Cart, CartItem
    db.query(CartItem).filter(CartItem.food_item_id == food_id).delete(synchronize_session=False)
    db.query(Cart).filter(Cart.user_id == user_id).delete(synchronize_session=False)
    db.query(FoodItem).filter(FoodItem.id == food_id).delete(synchronize_session=False)
    db.query(Category).filter(Category.id == cat_id).delete(synchronize_session=False)
    db.query(User).filter(User.email == user_data["email"]).delete(synchronize_session=False)
    db.commit()
    db.close()

if __name__ == "__main__":
    test_api()
