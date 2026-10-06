from enum import Enum

from pydantic import BaseModel, EmailStr, field_validator
from app.models.user import UserRole


class RegistrationRole(str, Enum):
    """Publicly selectable registration roles; STAFF must be provisioned."""

    CUSTOMER = "CUSTOMER"
    ADMIN = "ADMIN"


# ── Registration input ─────────────────────────────────────────────────────
class UserCreate(BaseModel):
    """
    Public registration payload.

    `role` is optional and defaults to CUSTOMER. A client MAY request
    ADMIN at signup, which is the intended behaviour for this project
    (college canteen: staff self-register with canteen credentials).

    This does NOT weaken the API's authorization boundary: every admin
    endpoint is still gated by `get_admin_user`, which re-reads the role
    from the database rather than from the token or the request. Choosing
    a role here only decides what the account can reach, and an account
    with the wrong role simply receives 403 on admin routes.

    Set ALLOW_PUBLIC_ADMIN_REGISTRATION=false in the environment to restore
    locked-down behaviour: the field is then ignored and every new
    registration is forced to CUSTOMER.
    """
    name: str
    email: EmailStr
    password: str
    role: RegistrationRole | None = None

    @field_validator("name")
    @classmethod
    def name_not_blank(cls, v: str) -> str:
        if not v.strip():
            raise ValueError("name must not be blank")
        return v.strip()

    @field_validator("password")
    @classmethod
    def password_min_length(cls, v: str) -> str:
        if len(v) < 6:
            raise ValueError("password must be at least 6 characters")
        return v


# ── Login input ────────────────────────────────────────────────────────────
class UserLogin(BaseModel):
    email: EmailStr
    password: str


# ── User representation returned to clients ────────────────────────────────
class UserResponse(BaseModel):
    """
    Safe public view of a User.

    Includes `role` so Flutter can conditionally render the correct home
    screen after login.  The backend still enforces role on every request —
    the client role is for UX only, not security.
    """
    id: str
    name: str
    email: EmailStr
    role: UserRole          # ← now exposed; Flutter reads this on login

    model_config = {"from_attributes": True}


# ── Token envelope ─────────────────────────────────────────────────────────
class TokenResponse(BaseModel):
    """
    Returned by POST /api/auth/login.

    `access_token` — JWT bearer token (contains sub + role + exp).
    `user`          — full user snapshot so clients don't need a second call.
    """
    access_token: str
    token_type: str = "bearer"
    user: UserResponse
