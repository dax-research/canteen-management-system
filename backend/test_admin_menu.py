import pytest
from fastapi.testclient import TestClient
import uuid

from app.main import app
from app.db.database import SessionLocal
from app.models.user import User
from app.models.cart import Cart, CartItem
from app.models.category import Category
from app.models.food_item import FoodItem

@pytest.fixture(scope="module")
def client():
    return TestClient(app)

@pytest.fixture(scope="module")
def test_db():
    db = SessionLocal()
    yield db
    db.close()

@pytest.fixture(scope="module")
def admin_user(test_db):
    email = f"admin_{uuid.uuid4()}@example.com"
    user = User(email=email, name="Admin User", role="ADMIN", password="hashedpassword")
    test_db.add(user)
    test_db.commit()
    test_db.refresh(user)
    yield user
    test_db.delete(user)
    test_db.commit()

@pytest.fixture(scope="module")
def customer_user(test_db):
    email = f"customer_{uuid.uuid4()}@example.com"
    user = User(email=email, name="Customer User", role="CUSTOMER", password="hashedpassword")
    test_db.add(user)
    test_db.commit()
    test_db.refresh(user)
    yield user
    test_db.delete(user)
    test_db.commit()

@pytest.fixture(scope="module")
def staff_user(test_db):
    email = f"staff_{uuid.uuid4()}@example.com"
    user = User(email=email, name="Staff User", role="STAFF", password="hashedpassword")
    test_db.add(user)
    test_db.commit()
    test_db.refresh(user)
    yield user
    test_db.delete(user)
    test_db.commit()

# We will generate tokens manually to avoid relying on auth routes which hash passwords
def get_token(user):
    from app.core.jwt import create_access_token
    return create_access_token(user.id)

@pytest.fixture(scope="module")
def admin_headers(admin_user):
    return {"Authorization": f"Bearer {get_token(admin_user)}"}

@pytest.fixture(scope="module")
def customer_headers(customer_user):
    return {"Authorization": f"Bearer {get_token(customer_user)}"}

@pytest.fixture(scope="module")
def staff_headers(staff_user):
    return {"Authorization": f"Bearer {get_token(staff_user)}"}

# --- AUTHENTICATION/AUTHORIZATION TESTS ---

def test_auth_unauthenticated(client):
    res = client.get("/api/admin/categories/")
    assert res.status_code == 401

def test_auth_customer(client, customer_headers):
    res = client.get("/api/admin/categories/", headers=customer_headers)
    assert res.status_code == 403

def test_auth_staff(client, staff_headers):
    res = client.get("/api/admin/categories/", headers=staff_headers)
    assert res.status_code == 403

def test_auth_admin(client, admin_headers):
    res = client.get("/api/admin/categories/", headers=admin_headers)
    assert res.status_code == 200

# --- CATEGORY TESTS ---

def test_admin_create_category(client, admin_headers):
    cat_name = f"Test Cat {uuid.uuid4()}"
    res = client.post("/api/admin/categories/", json={"name": cat_name, "description": "Desc"}, headers=admin_headers)
    assert res.status_code == 201
    assert res.json()["name"] == cat_name

def test_duplicate_category_rejected(client, admin_headers):
    cat_name = f"Dup Cat {uuid.uuid4()}"
    client.post("/api/admin/categories/", json={"name": cat_name}, headers=admin_headers)
    res = client.post("/api/admin/categories/", json={"name": cat_name}, headers=admin_headers)
    assert res.status_code == 400

def test_update_category(client, admin_headers):
    cat_name = f"Cat {uuid.uuid4()}"
    res = client.post("/api/admin/categories/", json={"name": cat_name}, headers=admin_headers)
    cat_id = res.json()["id"]

    # PATCH
    res = client.patch(f"/api/admin/categories/{cat_id}", json={"description": "Updated"}, headers=admin_headers)
    assert res.status_code == 200
    assert res.json()["description"] == "Updated"

def test_update_nonexistent_category(client, admin_headers):
    res = client.patch(f"/api/admin/categories/{uuid.uuid4()}", json={"name": "New"}, headers=admin_headers)
    assert res.status_code == 404

def test_delete_nonexistent_category(client, admin_headers):
    res = client.delete(f"/api/admin/categories/{uuid.uuid4()}", headers=admin_headers)
    assert res.status_code == 404

def test_delete_category_with_food_items(client, admin_headers):
    res = client.post("/api/admin/categories/", json={"name": f"Del Cat {uuid.uuid4()}"}, headers=admin_headers)
    cat_id = res.json()["id"]
    # create food item
    food_data = {"category_id": cat_id, "name": "Food", "price": 10, "stock": 10}
    client.post("/api/admin/food-items/", json=food_data, headers=admin_headers)

    # attempt delete category
    res = client.delete(f"/api/admin/categories/{cat_id}", headers=admin_headers)
    assert res.status_code == 400

def test_delete_empty_category(client, admin_headers):
    res = client.post("/api/admin/categories/", json={"name": f"Del Cat Empty {uuid.uuid4()}"}, headers=admin_headers)
    cat_id = res.json()["id"]
    res = client.delete(f"/api/admin/categories/{cat_id}", headers=admin_headers)
    assert res.status_code == 204

# --- FOOD ITEMS TESTS ---

@pytest.fixture(scope="module")
def base_category(client, admin_headers):
    res = client.post("/api/admin/categories/", json={"name": f"Base Cat {uuid.uuid4()}"}, headers=admin_headers)
    return res.json()["id"]

def test_create_valid_food_item(client, admin_headers, base_category):
    res = client.post("/api/admin/food-items/", json={
        "category_id": base_category,
        "name": "Valid Food",
        "price": 15.5,
        "stock": 10
    }, headers=admin_headers)
    assert res.status_code == 201

def test_invalid_category(client, admin_headers):
    res = client.post("/api/admin/food-items/", json={
        "category_id": str(uuid.uuid4()),
        "name": "Invalid Cat",
        "price": 10,
        "stock": 10
    }, headers=admin_headers)
    assert res.status_code == 400

def test_negative_price_rejected(client, admin_headers, base_category):
    res = client.post("/api/admin/food-items/", json={
        "category_id": base_category,
        "name": "Bad Price",
        "price": -5,
        "stock": 10
    }, headers=admin_headers)
    assert res.status_code == 422 # Pydantic validation

def test_negative_stock_rejected(client, admin_headers, base_category):
    res = client.post("/api/admin/food-items/", json={
        "category_id": base_category,
        "name": "Bad Stock",
        "price": 10,
        "stock": -1
    }, headers=admin_headers)
    assert res.status_code == 422

def test_stock_0_forces_unavailable(client, admin_headers, base_category):
    res = client.post("/api/admin/food-items/", json={
        "category_id": base_category,
        "name": "Zero Stock",
        "price": 10,
        "stock": 0,
        "is_available": True # Should be forced to False
    }, headers=admin_headers)
    assert res.status_code == 201
    assert res.json()["is_available"] is False

def test_update_food_item(client, admin_headers, base_category):
    # Create
    res = client.post("/api/admin/food-items/", json={
        "category_id": base_category,
        "name": "To Update",
        "price": 10,
        "stock": 10
    }, headers=admin_headers)
    food_id = res.json()["id"]

    # Update
    res = client.patch(f"/api/admin/food-items/{food_id}", json={
        "price": 20,
        "description": "New desc"
    }, headers=admin_headers)
    assert res.status_code == 200
    assert res.json()["price"] == 20.0
    assert res.json()["description"] == "New desc"
    assert res.json()["stock"] == 10 # Unchanged

def test_update_stock_0_forces_unavailable(client, admin_headers, base_category):
    res = client.post("/api/admin/food-items/", json={
        "category_id": base_category,
        "name": "Update Zero Stock",
        "price": 10,
        "stock": 10,
        "is_available": True
    }, headers=admin_headers)
    food_id = res.json()["id"]

    res = client.patch(f"/api/admin/food-items/{food_id}", json={
        "stock": 0
    }, headers=admin_headers)
    assert res.status_code == 200
    assert res.json()["is_available"] is False

def test_update_availability_true_while_stock_0_fails(client, admin_headers, base_category):
    res = client.post("/api/admin/food-items/", json={
        "category_id": base_category,
        "name": "Fail Avail",
        "price": 10,
        "stock": 0
    }, headers=admin_headers)
    food_id = res.json()["id"]

    res = client.patch(f"/api/admin/food-items/{food_id}", json={
        "is_available": True
    }, headers=admin_headers)
    assert res.status_code == 400
    assert "Cannot set available when stock is 0" in res.json()["detail"]

def test_delete_food_item_removes_cart_reference(client, admin_headers, customer_headers, base_category, test_db, customer_user):
    # Admin create food item
    res = client.post("/api/admin/food-items/", json={
        "category_id": base_category,
        "name": "Cart Delete Test",
        "price": 10,
        "stock": 10
    }, headers=admin_headers)
    food_id = res.json()["id"]

    # Customer add to cart
    res = client.post("/api/cart/items", json={
        "food_item_id": food_id,
        "quantity": 1
    }, headers=customer_headers)
    assert res.status_code == 200

    # Verify cart item exists in db
    cart = test_db.query(Cart).filter(Cart.user_id == customer_user.id).first()
    assert any(item.food_item_id == food_id for item in cart.items)

    # Admin delete food item
    res = client.delete(f"/api/admin/food-items/{food_id}", headers=admin_headers)
    assert res.status_code == 204

    # Verify cart item was deleted (FK restrict avoided)
    test_db.refresh(cart)
    assert not any(item.food_item_id == food_id for item in cart.items)

def test_null_fields(client, admin_headers, base_category):
    res = client.post("/api/admin/food-items/", json={
        "category_id": base_category,
        "name": "Null Field Test",
        "description": "Initial",
        "price": 10,
        "stock": 10
    }, headers=admin_headers)
    food_id = res.json()["id"]

    # PATCH with explicit null
    res = client.patch(f"/api/admin/food-items/{food_id}", json={"description": None}, headers=admin_headers)
    assert res.status_code == 200
    assert res.json()["description"] is None

def test_blank_category_name_rejected(client, admin_headers):
    res = client.post("/api/admin/categories/", json={"name": "   "}, headers=admin_headers)
    assert res.status_code == 422

def test_blank_food_name_rejected(client, admin_headers, base_category):
    res = client.post("/api/admin/food-items/", json={
        "category_id": base_category,
        "name": "   ",
        "price": 10,
        "stock": 10
    }, headers=admin_headers)
    assert res.status_code == 422

def test_null_image_url(client, admin_headers, base_category):
    res = client.post("/api/admin/food-items/", json={
        "category_id": base_category,
        "name": "Image Test",
        "price": 10,
        "stock": 10,
        "image_url": "http://example.com/image.png"
    }, headers=admin_headers)
    food_id = res.json()["id"]

    res = client.patch(f"/api/admin/food-items/{food_id}", json={"image_url": None}, headers=admin_headers)
    assert res.status_code == 200
    assert res.json()["image_url"] is None

def test_historical_order_deletion(client, admin_headers, customer_headers, base_category, test_db, customer_user):
    from app.models.order import Order, OrderItem

    # 1. Create a food item with stock
    res = client.post("/api/admin/food-items/", json={
        "category_id": base_category,
        "name": "Historical Food",
        "price": 10.5,
        "stock": 5
    }, headers=admin_headers)
    food_id = res.json()["id"]

    # 2. Create an order containing that food item using existing customer order flow
    # Add to cart
    res = client.post("/api/cart/items", json={
        "food_item_id": food_id,
        "quantity": 2
    }, headers=customer_headers)
    assert res.status_code == 200

    # Checkout
    res = client.post("/api/orders/", headers=customer_headers)
    assert res.status_code == 201
    order_id = res.json()["id"]

    # 3. Record OrderItem
    test_db.expire_all() # Ensure fresh read
    order = test_db.query(Order).filter(Order.id == order_id).first()
    assert len(order.items) == 1
    order_item = order.items[0]

    item_name = order_item.item_name
    unit_price = order_item.unit_price
    quantity = order_item.quantity
    subtotal = order_item.subtotal
    assert order_item.food_item_id == food_id

    # 4. Admin deletes the food item
    res = client.delete(f"/api/admin/food-items/{food_id}", headers=admin_headers)
    assert res.status_code == 204

    # 5. Verify Order and OrderItem still exist, details unchanged, food_item_id is NULL
    test_db.expire_all()
    order_after = test_db.query(Order).filter(Order.id == order_id).first()
    assert order_after is not None
    assert len(order_after.items) == 1

    order_item_after = order_after.items[0]
    assert order_item_after.item_name == item_name
    assert order_item_after.unit_price == unit_price
    assert order_item_after.quantity == quantity
    assert order_item_after.subtotal == subtotal
    assert order_item_after.food_item_id is None

    # 6. Verify food item no longer exists
    res = client.get(f"/api/admin/food-items/{food_id}", headers=admin_headers)
    assert res.status_code == 404

def test_category_update_null_validation(client, admin_headers):
    # Create category first
    res = client.post("/api/admin/categories/", json={"name": f"Null Cat {uuid.uuid4()}"}, headers=admin_headers)
    cat_id = res.json()["id"]

    # Test explicit null on non-nullable fields
    res = client.patch(f"/api/admin/categories/{cat_id}", json={"name": None}, headers=admin_headers)
    assert res.status_code == 422

    res = client.patch(f"/api/admin/categories/{cat_id}", json={"is_active": None}, headers=admin_headers)
    assert res.status_code == 422

    # Null description still allowed
    res = client.patch(f"/api/admin/categories/{cat_id}", json={"description": None}, headers=admin_headers)
    assert res.status_code == 200

def test_food_item_update_null_validation(client, admin_headers, base_category):
    res = client.post("/api/admin/food-items/", json={
        "category_id": base_category,
        "name": f"Null Food {uuid.uuid4()}",
        "price": 10,
        "stock": 10
    }, headers=admin_headers)
    food_id = res.json()["id"]

    # Test explicit null on non-nullable fields
    res = client.patch(f"/api/admin/food-items/{food_id}", json={"name": None}, headers=admin_headers)
    assert res.status_code == 422

    res = client.patch(f"/api/admin/food-items/{food_id}", json={"category_id": None}, headers=admin_headers)
    assert res.status_code == 422

    res = client.patch(f"/api/admin/food-items/{food_id}", json={"price": None}, headers=admin_headers)
    assert res.status_code == 422

    res = client.patch(f"/api/admin/food-items/{food_id}", json={"stock": None}, headers=admin_headers)
    assert res.status_code == 422

    res = client.patch(f"/api/admin/food-items/{food_id}", json={"is_available": None}, headers=admin_headers)
    assert res.status_code == 422

    # Null description/image_url still allowed
    res = client.patch(f"/api/admin/food-items/{food_id}", json={"description": None, "image_url": None}, headers=admin_headers)
    assert res.status_code == 200
