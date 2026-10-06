import uuid
from datetime import datetime, timezone
from decimal import Decimal

from sqlalchemy import CheckConstraint, DateTime, ForeignKey, Integer, Numeric, String
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.database import Base


class Order(Base):
    __tablename__ = "orders"

    __table_args__ = (
        CheckConstraint(
            "total_amount >= 0",
            name="ck_orders_total_amount_non_negative",
        ),
    )

    id: Mapped[str] = mapped_column(
        String(36),
        primary_key=True,
        default=lambda: str(uuid.uuid4()),
    )
    user_id: Mapped[str] = mapped_column(
        String(36),
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    status: Mapped[str] = mapped_column(
        String(50),
        default="PLACED",
        nullable=False,
    )
    order_type: Mapped[str] = mapped_column(
        String(20),
        default="PICKUP",
        nullable=False,
    )
    pickup_time: Mapped[str | None] = mapped_column(
        String(50),
        nullable=True,
    )
    eta_minutes: Mapped[int | None] = mapped_column(
        Integer,
        nullable=True,
    )
    payment_method: Mapped[str] = mapped_column(
        String(20),
        default="CASH",
        nullable=False,
    )
    payment_status: Mapped[str] = mapped_column(
        String(20),
        default="PENDING",
        nullable=False,
    )
    payment_reference: Mapped[str | None] = mapped_column(
        String(50),
        nullable=True,
    )
    paid_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True),
        nullable=True,
    )
    total_amount: Mapped[Decimal] = mapped_column(Numeric(10, 2), nullable=False)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc),
        nullable=False,
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc),
        onupdate=lambda: datetime.now(timezone.utc),
        nullable=False,
    )

    user: Mapped["User"] = relationship(back_populates="orders")
    items: Mapped[list["OrderItem"]] = relationship(
        back_populates="order",
        cascade="all, delete-orphan",
    )


class OrderItem(Base):
    __tablename__ = "order_items"

    __table_args__ = (
        CheckConstraint("quantity > 0", name="ck_order_items_quantity_positive"),
        CheckConstraint("unit_price >= 0", name="ck_order_items_unit_price_non_negative"),
        CheckConstraint("subtotal >= 0", name="ck_order_items_subtotal_non_negative"),
    )

    id: Mapped[str] = mapped_column(
        String(36),
        primary_key=True,
        default=lambda: str(uuid.uuid4()),
    )
    order_id: Mapped[str] = mapped_column(
        String(36),
        ForeignKey("orders.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    food_item_id: Mapped[str | None] = mapped_column(
        String(36),
        ForeignKey("food_items.id", ondelete="SET NULL"),
        nullable=True,
        index=True,
    )
    item_name: Mapped[str] = mapped_column(String(150), nullable=False)
    unit_price: Mapped[Decimal] = mapped_column(Numeric(10, 2), nullable=False)
    quantity: Mapped[int] = mapped_column(Integer, nullable=False)
    subtotal: Mapped[Decimal] = mapped_column(Numeric(10, 2), nullable=False)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc),
        nullable=False,
    )

    order: Mapped["Order"] = relationship(back_populates="items")
    food_item: Mapped["FoodItem"] = relationship()
