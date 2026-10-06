import pytest
from pydantic import ValidationError

from app.models.user import UserRole
from app.schemas.auth import UserCreate, UserResponse


def test_staff_role_is_supported_in_authenticated_user_responses():
    response = UserResponse(
        id="5e27406f-4dc8-4aec-92c0-f45d2d303adb",
        name="Staff Member",
        email="staff@example.com",
        role=UserRole.STAFF,
    )

    assert response.role is UserRole.STAFF


def test_staff_role_cannot_be_selected_during_public_registration():
    with pytest.raises(ValidationError):
        UserCreate(
            name="Staff Member",
            email="staff@example.com",
            password="strong-password",
            role="STAFF",
        )
