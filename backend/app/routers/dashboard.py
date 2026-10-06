"""Admin dashboard statistics.

ADMIN-only.  Every figure is a single aggregate COUNT against the live tables
so the dashboard reflects real data rather than anything cached client-side.
"""

from fastapi import APIRouter, Depends
from sqlalchemy import func
from sqlalchemy.orm import Session

from app.core.dependencies import get_admin_user
from app.db.database import get_db
from app.models.food_item import FoodItem
from app.models.order import Order
from app.models.user import User
from app.schemas.admin import DashboardStats

router = APIRouter(prefix="/api/admin", tags=["admin-dashboard"])

# A food item at or below this stock level is surfaced as "low stock" on the
# dashboard.  Kept as a module constant so it is easy to tune for the canteen.
LOW_STOCK_THRESHOLD = 5

# Statuses that represent an order the kitchen still has work to do on.
ACTIVE_STATUSES = ("ACCEPTED", "PREPARING", "READY")


def _count_orders(db: Session, statuses: tuple[str, ...]) -> int:
    return (
        db.query(func.count(Order.id))
        .filter(Order.status.in_(statuses))
        .scalar()
        or 0
    )


@router.get("/dashboard", response_model=DashboardStats)
def get_dashboard_stats(
    db: Session = Depends(get_db),
    admin: User = Depends(get_admin_user),
):
    """
    Aggregate canteen statistics for the admin dashboard (ADMIN only).
    """
    total_food_items = db.query(func.count(FoodItem.id)).scalar() or 0
    total_users = db.query(func.count(User.id)).scalar() or 0
    total_customers = (
        db.query(func.count(User.id))
        .filter(User.role != "ADMIN")
        .scalar()
        or 0
    )

    low_stock_items = (
        db.query(func.count(FoodItem.id))
        .filter(FoodItem.stock > 0, FoodItem.stock <= LOW_STOCK_THRESHOLD)
        .scalar()
        or 0
    )
    out_of_stock_items = (
        db.query(func.count(FoodItem.id))
        .filter(FoodItem.stock == 0)
        .scalar()
        or 0
    )

    return DashboardStats(
        total_food_items=total_food_items,
        total_users=total_users,
        total_customers=total_customers,
        pending_orders=_count_orders(db, ("PLACED",)),
        active_orders=_count_orders(db, ACTIVE_STATUSES),
        completed_orders=_count_orders(db, ("COMPLETED",)),
        cancelled_orders=_count_orders(db, ("CANCELLED",)),
        low_stock_items=low_stock_items,
        out_of_stock_items=out_of_stock_items,
    )
