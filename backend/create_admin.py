"""
create_admin.py
===============

Controlled bootstrap for the initial ADMIN account.

Admin registration is deliberately NOT possible through the public API:
`POST /api/auth/register` always creates a CUSTOMER (the `UserCreate`
schema has no `role` field, so a client cannot send one).  This script is the
only supported way to create the first admin.

Usage (from the backend/ directory, venv active):

    python create_admin.py --email admin@college.edu --password "Admin@123"

    # or, to promote an account that already registered normally:
    python create_admin.py --email existing@college.edu --promote

Optional flags:
    --name   Display name for a brand-new account (default: "Admin User")
    --promote  If the email already exists, promote it to ADMIN instead of
              creating a new account.

The script is idempotent for a given email: running it twice will not create
a duplicate, it will report the existing role.
"""

import argparse
import sys

from app.core.security import hash_password
from app.db.database import SessionLocal
from app.models.user import User, UserRole


def create_admin(email: str, password: str, name: str, promote: bool) -> int:
    email = email.strip().lower()

    if "@" not in email or len(email) < 5:
        print("ERROR: --email must be a valid email address.")
        return 1

    db = SessionLocal()
    try:
        existing = db.query(User).filter(User.email == email).first()

        if existing is not None:
            if existing.role == UserRole.ADMIN.value:
                print(f"'{email}' is already an ADMIN. Nothing to do.")
                return 0

            if not promote:
                print(f"ERROR: '{email}' already exists as a {existing.role} account.")
                print("       Re-run with --promote to grant the ADMIN role.")
                return 1

            existing.role = UserRole.ADMIN.value
            db.commit()
            print(f"Promoted '{email}' ({existing.name}) to ADMIN.")
            return 0

        # Only validate the password when we are actually creating an account.
        if len(password) < 8:
            print("ERROR: --password must be at least 8 characters.")
            return 1

        new_admin = User(
            name=name.strip() or "Admin User",
            email=email,
            password=hash_password(password),
            role=UserRole.ADMIN.value,
        )
        db.add(new_admin)
        db.commit()

        print(f"Created ADMIN account: {email}")
        print("Log in with this account to reach the admin dashboard.")
        return 0
    finally:
        db.close()


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Create or promote the initial ADMIN account.",
    )
    parser.add_argument("--email", required=True, help="Admin login email")
    parser.add_argument(
        "--password",
        default="",
        help="Admin password (min 8 chars). Required unless --promote is used.",
    )
    parser.add_argument(
        "--name",
        default="Admin User",
        help="Display name for a newly created account",
    )
    parser.add_argument(
        "--promote",
        action="store_true",
        help="Promote an existing CUSTOMER account to ADMIN",
    )

    args = parser.parse_args()
    return create_admin(
        email=args.email,
        password=args.password,
        name=args.name,
        promote=args.promote,
    )


if __name__ == "__main__":
    sys.exit(main())
