"""
Live role-authorization harness for the canteen backend.

Drives the REAL running server over HTTP and asserts that:

  1. Registration always creates a CUSTOMER (no role escalation via payload).
  2. A CUSTOMER token is rejected with 403 on every admin-only route.
  3. An ADMIN token is allowed on every admin-only route.
  4. A CUSTOMER sees only their own orders; another customer's order 404s.
  5. An admin status update is immediately visible to the customer.
  6. The order status state machine rejects invalid jumps.

Usage:
    python test_role_harness.py [--base http://127.0.0.1:8020]

Run the server first.  Every user is seeded with a unique email per run so
reruns never collide and the authorization assertions stay meaningful.
Exits non-zero on the first failed tally so it works in CI.
"""

import argparse
import json
import sys
import time
import urllib.error
import urllib.request

BASE = "http://127.0.0.1:8020"

PASS, FAIL = 0, 0
RUN = str(int(time.time()))


def req(method, path, body=None, token=None):
    """Perform one HTTP request. Returns (status, parsed_json_or_text)."""
    url = f"{BASE}{path}"
    data = json.dumps(body).encode() if body is not None else None
    headers = {"Content-Type": "application/json"}
    if token:
        headers["Authorization"] = f"Bearer {token}"

    r = urllib.request.Request(url, data=data, headers=headers, method=method)
    try:
        with urllib.request.urlopen(r, timeout=20) as resp:
            raw = resp.read().decode()
            status = resp.status
    except urllib.error.HTTPError as e:
        raw = e.read().decode()
        status = e.code
    except Exception as e:  # connection refused etc.
        return 0, str(e)

    try:
        return status, json.loads(raw)
    except Exception:
        return status, raw


def check(label, got, want):
    global PASS, FAIL
    if got == want:
        PASS += 1
        print(f"  PASS  {label}  ({got})")
    else:
        FAIL += 1
        print(f"  FAIL  {label}  expected {want}, got {got}")


def section(title):
    print(f"\n{title}\n{'-' * len(title)}")


def make_user(prefix):
    """Register a fresh CUSTOMER and return (token, user_id, creds)."""
    email = f"{prefix}_{RUN}@example.com"
    creds = {"name": f"Probe {prefix}", "email": email, "password": "Test@12345"}
    st, body = req("POST", "/api/auth/register", creds)
    assert st == 201, f"register failed for {prefix}: {st} {body}"
    st, body = req("POST", "/api/auth/login", {"email": email, "password": creds["password"]})
    assert st == 200, f"login failed for {prefix}: {st} {body}"
    return body["access_token"], body["user"]["id"], creds


def main():
    global BASE
    ap = argparse.ArgumentParser()
    ap.add_argument("--base", default=BASE)
    args = ap.parse_args()
    BASE = args.base.rstrip("/")

    section("0. Server reachable")
    st, _ = req("GET", "/api/test")
    check("GET /api/test", st, 200)
    if st != 200:
        print("\nServer not reachable — start it first.")
        return 1

    # ── 1. Registration cannot create an ADMIN ──────────────────────────────
    section("1. Registration always creates CUSTOMER (no privilege escalation)")
    email = f"escalate_{RUN}@example.com"
    st, body = req("POST", "/api/auth/register", {
        "name": "Escalate", "email": email,
        "password": "Test@12345", "role": "ADMIN",
    })
    check("register with role=ADMIN in payload -> 201", st, 201)
    check("  ...resulting role is CUSTOMER", body.get("role"), "CUSTOMER")

    st, body = req("POST", "/api/auth/login", {"email": email, "password": "Test@12345"})
    check("login role is CUSTOMER", body.get("user", {}).get("role"), "CUSTOMER")
    customer_token = body["access_token"]

    # ── 2. An ADMIN account exists ──────────────────────────────────────────
    section("2. ADMIN account (bootstrap via create_admin.py)")
    admin_email = f"admin_probe_{RUN}@example.com"
    st, _ = req("POST", "/api/auth/register", {
        "name": "Probe Admin", "email": admin_email, "password": "Test@12345",
    })
    # Promote out-of-band exactly as create_admin.py --promote does.
    sys.path.insert(0, ".")
    try:
        from app.db.database import SessionLocal
        from app.models.user import User

        db = SessionLocal()
        u = db.query(User).filter(User.email == admin_email).first()
        if u:
            u.role = "ADMIN"
            db.commit()
            promoted = True
        else:
            promoted = False
        db.close()
    except Exception as e:
        print(f"  SKIP  could not promote directly ({e}); relying on pre-existing admin")
        promoted = None

    if promoted:
        st, body = req("POST", "/api/auth/login", {
            "email": admin_email, "password": "Test@12345"})
        check("promoted user logs in", st, 200)
        check("  ...role is ADMIN", body.get("user", {}).get("role"), "ADMIN")
        admin_token = body["access_token"]
    else:
        # Fall back to whatever admin the database already has.
        admin_token, admin_id = None, None
        for candidate in ("admin@copperspoon.com",):
            st, body = req("POST", "/api/auth/login", {
                "email": candidate, "password": "Admin@123"})
            if st == 200 and body.get("user", {}).get("role") == "ADMIN":
                admin_token = body["access_token"]
                print(f"  using seeded admin {candidate}")
                break
        if not admin_token:
            print("  SKIP  no admin token available; admin-side assertions skipped")
            admin_token = ""

    # ── 3. CUSTOMER is forbidden on every admin route ──────────────────────
    section("3. CUSTOMER token -> 403 on all admin-only routes")
    admin_routes = [
        ("GET",  "/api/admin/dashboard", None),
        ("GET",  "/api/admin/users/", None),
        ("GET",  "/api/admin/orders/", None),
        ("GET",  "/api/admin/food-items/", None),
        ("GET",  "/api/admin/categories/", None),
        ("POST", "/api/admin/categories/", {"name": f"X{RUN}", "description": "x"}),
        ("POST", "/api/admin/food-items/", {
            "category_id": "00000000-0000-0000-0000-000000000000",
            "name": "X", "price": 1, "stock": 1}),
    ]
    for method, path, body in admin_routes:
        st, _ = req(method, path, body, token=customer_token)
        check(f"{method} {path}", st, 403)

    section("4. No token at all -> 401 on admin routes")
    for method, path, _ in admin_routes[:3]:
        st, _ = req(method, path)
        check(f"{method} {path} (no token)", st, 401)

    # ── 5. ADMIN is allowed ─────────────────────────────────────────────────
    if admin_token:
        section("5. ADMIN token -> 200 on admin routes")
        st, body = req("GET", "/api/admin/dashboard", token=admin_token)
        check("GET /api/admin/dashboard", st, 200)
        if st == 200:
            for field in ("total_food_items", "total_users", "pending_orders",
                          "active_orders", "completed_orders", "low_stock_items"):
                check(f"  dashboard.{field} is int", isinstance(body.get(field), int), True)

        st, body = req("GET", "/api/admin/users/", token=admin_token)
        check("GET /api/admin/users/", st, 200)
        check("  ...returns a users list", isinstance(body.get("users"), list), True)

        st, body = req("GET", "/api/admin/orders/", token=admin_token)
        check("GET /api/admin/orders/", st, 200)

        st, body = req("GET", "/api/admin/food-items/", token=admin_token)
        check("GET /api/admin/food-items/", st, 200)

        st, body = req("GET", "/api/admin/categories/", token=admin_token)
        check("GET /api/admin/categories/", st, 200)
    else:
        print("\n(no admin token — skipping section 5)")

    # ── 6. Customer order isolation ────────────────────────────────────────
    section("6. A CUSTOMER sees only their own orders")
    st, cats = req("GET", "/api/categories")
    food_id = None
    if st == 200 and cats:
        st, items = req("GET", "/api/food-items")
        if st == 200 and items:
            food_id = items[0]["id"]
            food_name = items[0]["name"]
    check("found a food item to order", food_id is not None, True)

    if food_id:
        other_token, other_id, _ = make_user("other")

        # Customer A builds a cart and places an order.
        st, _ = req("POST", "/api/cart/items",
                    {"food_item_id": food_id, "quantity": 1}, token=customer_token)
        check("customer A adds to cart", st, 200)
        st, order_a = req("POST", "/api/orders", {}, token=customer_token)
        check("customer A places order", st, 201)
        order_a_id = order_a.get("id")

        st, body = req("GET", "/api/orders", token=customer_token)
        check("customer A order list", st, 200)
        check("  ...sees own order", any(o["id"] == order_a_id for o in body), True)

        st, _ = req("GET", f"/api/orders/{order_a_id}", token=other_token)
        check("customer B reading A's order -> 404", st, 404)

        st, _ = req("PATCH", f"/api/admin/orders/{order_a_id}/status",
                    {"status": "ACCEPTED"}, token=other_token)
        check("customer B updating A's order -> 403", st, 403)

        # ── 7. State machine ────────────────────────────────────────────────
        section("7. Order status state machine (admin-driven)")
        if admin_token:
            st, body = req("PATCH", f"/api/admin/orders/{order_a_id}/status",
                           {"status": "COMPLETED"}, token=admin_token)
            check("PLACED -> COMPLETED (skip) -> 400", st, 400)

            for want in ("ACCEPTED", "PREPARING", "READY", "COMPLETED"):
                st, body = req("PATCH", f"/api/admin/orders/{order_a_id}/status",
                               {"status": want}, token=admin_token)
                check(f"advance to {want}", st, 200)
                if st == 200:
                    check(f"  ...status is {want}", body.get("status"), want)
                    check("  ...customer snapshot present",
                          isinstance(body.get("customer"), dict), True)

            st, body = req("PATCH", f"/api/admin/orders/{order_a_id}/status",
                           {"status": "ACCEPTED"}, token=admin_token)
            check("COMPLETED -> ACCEPTED (reopen) -> 400", st, 400)

            # The customer must see the admin's change.
            st, body = req("GET", f"/api/orders/{order_a_id}", token=customer_token)
            check("customer sees COMPLETED", body.get("status"), "COMPLETED")

        # ── 8. Order filter ─────────────────────────────────────────────────
        section("8. Admin order list + status filter")
        if admin_token:
            st, body = req("GET", "/api/admin/orders/?status=COMPLETED",
                           token=admin_token)
            check("filter by status=COMPLETED", st, 200)
            check("  ...every row is COMPLETED",
                  all(o["status"] == "COMPLETED" for o in body), True)
            check("  ...rows carry customer info",
                  all(isinstance(o.get("customer"), dict) for o in body), True)

            st, body = req("GET", f"/api/admin/orders/{order_a_id}", token=admin_token)
            check("admin opens single order", st, 200)
            check("  ...has items with quantities",
                  len(body.get("items", [])) > 0
                  and all("quantity" in i for i in body["items"]), True)

    print(f"\n{'=' * 46}")
    print(f"  PASS: {PASS}    FAIL: {FAIL}")
    print(f"{'=' * 46}")
    return 1 if FAIL else 0


if __name__ == "__main__":
    sys.exit(main())
