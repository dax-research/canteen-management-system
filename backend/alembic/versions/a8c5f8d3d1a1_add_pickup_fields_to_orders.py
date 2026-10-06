"""add pickup fields to orders

Revision ID: a8c5f8d3d1a1
Revises: 5d717db219d2
Create Date: 2026-10-06 07:45:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'a8c5f8d3d1a1'
down_revision: Union[str, Sequence[str], None] = '5d717db219d2'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column(
        'orders',
        sa.Column('order_type', sa.String(length=20), nullable=False, server_default='PICKUP'),
    )
    op.add_column('orders', sa.Column('pickup_time', sa.String(length=50), nullable=True))
    op.add_column('orders', sa.Column('eta_minutes', sa.Integer(), nullable=True))
    op.alter_column('orders', 'order_type', server_default=None)


def downgrade() -> None:
    op.drop_column('orders', 'eta_minutes')
    op.drop_column('orders', 'pickup_time')
    op.drop_column('orders', 'order_type')
