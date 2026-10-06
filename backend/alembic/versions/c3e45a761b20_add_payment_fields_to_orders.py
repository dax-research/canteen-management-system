"""Add payment details to orders.

Revision ID: c3e45a761b20
Revises: a8c5f8d3d1a1
Create Date: 2026-10-06 08:10:00.000000
"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


revision: str = "c3e45a761b20"
down_revision: Union[str, Sequence[str], None] = "a8c5f8d3d1a1"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column(
        "orders",
        sa.Column(
            "payment_method",
            sa.String(length=20),
            nullable=False,
            server_default="CASH",
        ),
    )
    op.add_column(
        "orders",
        sa.Column(
            "payment_status",
            sa.String(length=20),
            nullable=False,
            server_default="PENDING",
        ),
    )
    op.add_column(
        "orders",
        sa.Column("payment_reference", sa.String(length=50), nullable=True),
    )
    op.add_column(
        "orders",
        sa.Column("paid_at", sa.DateTime(timezone=True), nullable=True),
    )
    op.alter_column("orders", "payment_method", server_default=None)
    op.alter_column("orders", "payment_status", server_default=None)


def downgrade() -> None:
    op.drop_column("orders", "paid_at")
    op.drop_column("orders", "payment_reference")
    op.drop_column("orders", "payment_status")
    op.drop_column("orders", "payment_method")
