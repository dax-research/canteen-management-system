"""Admin user management.

ADMIN-only.  Exposes registered accounts for the admin to review.

There is deliberately **no** enable/disable endpoint here: the `users` table
has no `is_active` column, so there is no server-side flag to flip.  Adding
one means a schema migration plus enforcement in `get_current_user`, which is
out of scope for this change — see the project README note on account status.
"""

from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import func
from sqlalchemy.orm import Session

from app.core.dependencies import get_admin_user
from app.db.database import get_db
from app.models.order import Order
from app.models.user import User
from app.schemas.admin import (
    AdminUserDetail,
    AdminUserListResponse,
    AdminUserResponse,
)

router = APIRouter(prefix="/api/admin/users", tags=["admin-users"])


def _to_admin_user(db: Session, user: User) -> AdminUserResponse:
    order_count = (
        db.query(func.count(Order.id))
        .filter(Order.user_id == user.id)
        .scalar()
        or 0
    )
    return AdminUserResponse(
        id=user.id,
        name=user.name,
        email=user.email,
        role=user.role,
        order_count=order_count,
    )


@router.get("/", response_model=AdminUserListResponse)
def list_users(
    search: Optional[str] = Query(None, description="Search by name or email"),
    role: Optional[str] = Query(None, description="Filter by role"),
    db: Session = Depends(get_db),
    admin: User = Depends(get_admin_user),
):
    """
    List registered users with their order counts (ADMIN only).
    """
    query = db.query(User)

    if search and search.strip():
        term = f"%{search.strip()}%"
        query = query.filter(User.name.ilike(term) | User.email.ilike(term))

    if role and role.strip():
        query = query.filter(User.role == role.strip().upper())

    users = query.order_by(User.name.asc()).all()

    return AdminUserListResponse(
        users=[_to_admin_user(db, u) for u in users],
        total=len(users),
    )


@router.get("/{user_id}", response_model=AdminUserDetail)
def get_user_detail(
    user_id: str,
    db: Session = Depends(get_db),
    admin: User = Depends(get_admin_user),
):
    """
    Get one user's details plus lifetime spend (ADMIN only).
    """
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found",
        )

    base = _to_admin_user(db, user)

    total_spent = (
        db.query(func.coalesce(func.sum(Order.total_amount), 0))
        .filter(
            Order.user_id == user.id,
            Order.status != "CANCELLED",
        )
        .scalar()
        or 0
    )

    return AdminUserDetail(
        id=base.id,
        name=base.name,
        email=base.email,
        role=base.role,
        order_count=base.order_count,
        total_spent=float(total_spent),
    )
