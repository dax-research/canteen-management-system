import uuid
from enum import Enum

from sqlalchemy import String
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.database import Base


class UserRole(str, Enum):
    """
    Application roles.

    CUSTOMER — normal canteen user (browse, cart, orders).
    ADMIN    — canteen staff / administrator (manage menu, inventory, orders).

    The STAFF role that existed in an earlier iteration is intentionally
    removed.  Any previously-stored 'STAFF' rows should be promoted to
    'ADMIN' via the migration in this task set.
    """
    CUSTOMER = "CUSTOMER"
    ADMIN    = "ADMIN"


class User(Base):
    __tablename__ = "users"

    id: Mapped[str] = mapped_column(
        String(36),
        primary_key=True,
        default=lambda: str(uuid.uuid4()),
    )

    name: Mapped[str] = mapped_column(
        String(100),
        nullable=False,
    )

    email: Mapped[str] = mapped_column(
        String(255),
        unique=True,
        nullable=False,
        index=True,
    )

    password: Mapped[str] = mapped_column(
        String(255),
        nullable=False,
    )

    # Stored as a plain VARCHAR so that Alembic migrations remain simple.
    # We use UserRole for all application-level checks; the DB column
    # keeps server_default='CUSTOMER' so existing rows are unchanged.
    role: Mapped[str] = mapped_column(
        String(20),
        nullable=False,
        default=UserRole.CUSTOMER.value,
        server_default=UserRole.CUSTOMER.value,
    )

    # ── helpers ────────────────────────────────────────────────
    @property
    def role_enum(self) -> UserRole:
        """Return the role as a typed enum value."""
        return UserRole(self.role)

    @property
    def is_admin(self) -> bool:
        return self.role == UserRole.ADMIN.value

    @property
    def is_customer(self) -> bool:
        return self.role == UserRole.CUSTOMER.value

    # ── relationships ──────────────────────────────────────────
    orders: Mapped[list["Order"]] = relationship(
        back_populates="user",
        cascade="all, delete-orphan",
    )
