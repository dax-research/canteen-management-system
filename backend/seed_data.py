"""
seed_data.py
============
Populates the Copper Spoon canteen database with realistic menu data
and demo user accounts.

Run from the backend/ directory with the venv active:
    python seed_data.py

Requirements:
    - Backend venv active  (.venv/Scripts/Activate.ps1)
    - .env file present with DATABASE_URL and JWT_SECRET_KEY
    - Alembic migrations already applied  (alembic upgrade head)
    - Backend server does NOT need to be running — we use SQLAlchemy directly
"""

import sys
import uuid

# ── Bootstrap the app's settings so database.py reads .env correctly ─────────
from app.db.database import Base, SessionLocal, engine
from app.models.user import User
from app.models.category import Category
from app.models.food_item import FoodItem
from app.core.security import hash_password

# ─────────────────────────────────────────────────────────────────────────────
# Data
# ─────────────────────────────────────────────────────────────────────────────

USERS = [
    {
        "name": "Admin User",
        "email": "admin@copperspoon.com",
        "password": "Admin@123",
        "role": "ADMIN",
    },
    {
        "name": "Staff Member",
        "email": "staff@copperspoon.com",
        "password": "Staff@123",
        "role": "STAFF",
    },
    {
        "name": "Arjun Sharma",
        "email": "arjun@example.com",
        "password": "Password@123",
        "role": "CUSTOMER",
    },
    {
        "name": "Priya Menon",
        "email": "priya@example.com",
        "password": "Password@123",
        "role": "CUSTOMER",
    },
    {
        "name": "Rohan Verma",
        "email": "rohan@example.com",
        "password": "Password@123",
        "role": "CUSTOMER",
    },
]

# category_name → list of food items
MENU: dict[str, list[dict]] = {
    "Rice & Biryani": [
        {
            "name": "Chicken Biryani",
            "description": "Fragrant basmati rice slow-cooked with tender chicken, whole spices, and caramelised onions. Served with raita.",
            "price": 120.00,
            "stock": 40,
            "image_url": "https://images.unsplash.com/photo-1563379091339-03b21ab4a4f8?w=400&q=80",
        },
        {
            "name": "Veg Biryani",
            "description": "Aromatic basmati rice cooked with seasonal vegetables, saffron, and warming spices.",
            "price": 90.00,
            "stock": 35,
            "image_url": "https://images.unsplash.com/photo-1589302168068-964664d93dc0?w=400&q=80",
        },
        {
            "name": "Egg Fried Rice",
            "description": "Wok-tossed rice with scrambled eggs, spring onions, soy sauce, and sesame oil.",
            "price": 70.00,
            "stock": 30,
            "image_url": "https://images.unsplash.com/photo-1603133872878-684f208fb84b?w=400&q=80",
        },
        {
            "name": "Steamed White Rice",
            "description": "Plain steamed Sona Masoori rice. Perfect with any curry or dal.",
            "price": 30.00,
            "stock": 80,
            "image_url": "https://images.unsplash.com/photo-1536304993881-ff86e0c9f9d4?w=400&q=80",
        },
    ],
    "Breads": [
        {
            "name": "Butter Naan",
            "description": "Soft leavened flatbread baked in a tandoor and finished with butter. Two pieces per serving.",
            "price": 25.00,
            "stock": 60,
            "image_url": "https://images.unsplash.com/photo-1591778702218-8e3cf4a6df22?w=400&q=80",
        },
        {
            "name": "Garlic Naan",
            "description": "Tandoor-baked naan topped with minced garlic, butter, and fresh coriander.",
            "price": 30.00,
            "stock": 50,
            "image_url": "https://images.unsplash.com/photo-1601050690597-df0568f70950?w=400&q=80",
        },
        {
            "name": "Plain Chapati",
            "description": "Freshly made whole-wheat flatbread cooked on a tawa. Served in pairs.",
            "price": 15.00,
            "stock": 100,
            "image_url": "https://images.unsplash.com/photo-1565557623262-b51c2513a641?w=400&q=80",
        },
        {
            "name": "Aloo Paratha",
            "description": "Whole-wheat flatbread stuffed with spiced mashed potato. Served with butter and pickle.",
            "price": 45.00,
            "stock": 25,
            "image_url": "https://images.unsplash.com/photo-1606491956689-2ea866880c84?w=400&q=80",
        },
    ],
    "Curries & Gravies": [
        {
            "name": "Paneer Butter Masala",
            "description": "Velvety tomato-cream gravy with cubes of soft cottage cheese, cashew paste, and aromatic spices.",
            "price": 110.00,
            "stock": 20,
            "image_url": "https://images.unsplash.com/photo-1565557624034-b6b5a4a57558?w=400&q=80",
        },
        {
            "name": "Dal Tadka",
            "description": "Yellow lentils slow-cooked and tempered with ghee, cumin, garlic, and dried red chillies.",
            "price": 70.00,
            "stock": 45,
            "image_url": "https://images.unsplash.com/photo-1585937421612-70a008356fbe?w=400&q=80",
        },
        {
            "name": "Chicken Curry",
            "description": "Bone-in chicken pieces simmered in an onion-tomato masala with freshly ground spices.",
            "price": 130.00,
            "stock": 18,
            "image_url": "https://images.unsplash.com/photo-1588166524941-3bf61a9c41db?w=400&q=80",
        },
        {
            "name": "Palak Paneer",
            "description": "Cottage cheese in a silky purée of blanched spinach with ginger, garlic, and cream.",
            "price": 100.00,
            "stock": 22,
            "image_url": "https://images.unsplash.com/photo-1547592180-85f173990554?w=400&q=80",
        },
        {
            "name": "Rajma Masala",
            "description": "Red kidney beans slow-cooked in a thick, spiced tomato-onion gravy. A Punjabi classic.",
            "price": 80.00,
            "stock": 30,
            "image_url": "https://images.unsplash.com/photo-1545247181-516773cae754?w=400&q=80",
        },
    ],
    "Snacks & Starters": [
        {
            "name": "Samosa (2 pcs)",
            "description": "Crispy pastry filled with spiced potato and peas. Served with mint chutney.",
            "price": 25.00,
            "stock": 50,
            "image_url": "https://images.unsplash.com/photo-1601050690117-94f5f6fa8bd7?w=400&q=80",
        },
        {
            "name": "Veg Spring Roll (4 pcs)",
            "description": "Crunchy golden rolls stuffed with stir-fried cabbage, carrots, and noodles.",
            "price": 55.00,
            "stock": 30,
            "image_url": "https://images.unsplash.com/photo-1606791422814-b32c705e3e2f?w=400&q=80",
        },
        {
            "name": "Chicken 65",
            "description": "Crispy deep-fried chicken marinated in red chilli, curry leaves, and yoghurt. South Indian street favourite.",
            "price": 110.00,
            "stock": 20,
            "image_url": "https://images.unsplash.com/photo-1610057099431-d73a1c9d2f2f?w=400&q=80",
        },
        {
            "name": "Pav Bhaji",
            "description": "Spiced mashed vegetable curry served with toasted butter pav. Mumbai street food staple.",
            "price": 60.00,
            "stock": 25,
            "image_url": "https://images.unsplash.com/photo-1606491956689-2ea866880c84?w=400&q=80",
        },
        {
            "name": "French Fries",
            "description": "Golden-crisp potato fries seasoned with salt and chaat masala. Served with ketchup.",
            "price": 50.00,
            "stock": 40,
            "image_url": "https://images.unsplash.com/photo-1630384060421-cb20d0e0649d?w=400&q=80",
        },
    ],
    "Drinks & Beverages": [
        {
            "name": "Masala Chai",
            "description": "Spiced Indian tea brewed with ginger, cardamom, cinnamon, and full-cream milk.",
            "price": 20.00,
            "stock": 100,
            "image_url": "https://images.unsplash.com/photo-1561336526-2914f13ceb36?w=400&q=80",
        },
        {
            "name": "Cold Coffee",
            "description": "Chilled blended coffee with milk and sugar. Rich, creamy, and refreshing.",
            "price": 55.00,
            "stock": 30,
            "image_url": "https://images.unsplash.com/photo-1461023058943-07fcbe16d735?w=400&q=80",
        },
        {
            "name": "Mango Lassi",
            "description": "Thick yoghurt-based drink blended with Alphonso mango pulp and a hint of cardamom.",
            "price": 50.00,
            "stock": 25,
            "image_url": "https://images.unsplash.com/photo-1571091655789-405eb7a3a3a8?w=400&q=80",
        },
        {
            "name": "Fresh Lime Soda",
            "description": "Freshly squeezed lime with soda water. Available sweet, salted, or mixed.",
            "price": 35.00,
            "stock": 60,
            "image_url": "https://images.unsplash.com/photo-1513558161293-cdaf765ed2fd?w=400&q=80",
        },
        {
            "name": "Bottled Water (500ml)",
            "description": "Chilled packaged mineral water.",
            "price": 15.00,
            "stock": 150,
            "image_url": "https://images.unsplash.com/photo-1548839140-29a749e1cf4d?w=400&q=80",
        },
    ],
    "Desserts": [
        {
            "name": "Gulab Jamun (2 pcs)",
            "description": "Soft milk-solid dumplings soaked in rose-flavoured sugar syrup. Served warm.",
            "price": 40.00,
            "stock": 35,
            "image_url": "https://images.unsplash.com/photo-1601050690597-df0568f70950?w=400&q=80",
        },
        {
            "name": "Kheer",
            "description": "Creamy rice pudding slow-cooked in full-fat milk with sugar, cardamom, and saffron.",
            "price": 45.00,
            "stock": 20,
            "image_url": "https://images.unsplash.com/photo-1590502593747-42a996133562?w=400&q=80",
        },
        {
            "name": "Chocolate Brownie",
            "description": "Dense, fudgy chocolate brownie with a crispy top. Served with a scoop of vanilla ice cream.",
            "price": 80.00,
            "stock": 15,
            "image_url": "https://images.unsplash.com/photo-1564355808539-22fda35bed7e?w=400&q=80",
        },
        {
            "name": "Fruit Custard",
            "description": "Chilled vanilla custard loaded with fresh seasonal fruits — banana, apple, pomegranate, and grapes.",
            "price": 55.00,
            "stock": 18,
            "image_url": "https://images.unsplash.com/photo-1488477181228-c84c0e9e34e1?w=400&q=80",
        },
    ],
}

# ─────────────────────────────────────────────────────────────────────────────
# Seeding
# ─────────────────────────────────────────────────────────────────────────────

def seed():
    db = SessionLocal()
    try:
        # ── Users ────────────────────────────────────────────────
        print("\n👤  Seeding users...")
        created_users, skipped_users = 0, 0
        for u in USERS:
            existing = db.query(User).filter(User.email == u["email"]).first()
            if existing:
                print(f"   ↷  {u['email']} already exists — skipped")
                skipped_users += 1
                continue
            user = User(
                id=str(uuid.uuid4()),
                name=u["name"],
                email=u["email"],
                password=hash_password(u["password"]),
                role=u["role"],
            )
            db.add(user)
            created_users += 1
            print(f"   ✓  Created {u['role']:10s}  {u['email']}")
        db.commit()
        print(f"   → {created_users} created, {skipped_users} skipped\n")

        # ── Categories & Food Items ──────────────────────────────
        print("🍽️   Seeding menu...")
        total_items = 0
        for cat_name, items in MENU.items():
            # Find or create category
            cat = db.query(Category).filter(Category.name == cat_name).first()
            if not cat:
                cat = Category(
                    id=str(uuid.uuid4()),
                    name=cat_name,
                    description=f"{cat_name} served fresh daily",
                    is_active=True,
                )
                db.add(cat)
                db.flush()  # get the ID without full commit
                print(f"   + Category: {cat_name}")
            else:
                print(f"   ↷ Category exists: {cat_name}")

            for item in items:
                existing_item = (
                    db.query(FoodItem)
                    .filter(
                        FoodItem.name == item["name"],
                        FoodItem.category_id == cat.id,
                    )
                    .first()
                )
                if existing_item:
                    print(f"       ↷  {item['name']} already exists — skipped")
                    continue

                food = FoodItem(
                    id=str(uuid.uuid4()),
                    category_id=cat.id,
                    name=item["name"],
                    description=item["description"],
                    price=item["price"],
                    stock=item["stock"],
                    image_url=item.get("image_url"),
                    is_available=item["stock"] > 0,
                )
                db.add(food)
                total_items += 1
                print(f"       ✓  ₹{item['price']:6.2f}  {item['name']}")

        db.commit()
        print(f"\n   → {total_items} food items created across {len(MENU)} categories\n")

        # ── Summary ──────────────────────────────────────────────
        print("=" * 52)
        print("✅  Seed complete!")
        print("=" * 52)
        print("\n📋  Demo credentials:")
        print(f"   Admin   →  admin@copperspoon.com  /  Admin@123")
        print(f"   Staff   →  staff@copperspoon.com  /  Staff@123")
        print(f"   User 1  →  arjun@example.com      /  Password@123")
        print(f"   User 2  →  priya@example.com      /  Password@123")
        print(f"   User 3  →  rohan@example.com      /  Password@123")
        print()

    except Exception as e:
        db.rollback()
        print(f"\n❌  Seeding failed: {e}")
        sys.exit(1)
    finally:
        db.close()


if __name__ == "__main__":
    seed()
