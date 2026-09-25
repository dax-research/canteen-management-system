from sqlalchemy import select
from sqlalchemy.orm import Session
from fastapi import Depends

from app.core.security import hash_password, verify_password
from app.db.database import get_db
from app.models.user import User
from app.core.jwt import create_access_token



from fastapi import APIRouter, HTTPException, status
from app.schemas.auth import UserCreate, UserLogin, TokenResponse, UserResponse


router = APIRouter(prefix="/api/auth", tags=["auth"])



@router.post(
    "/register",
    response_model=UserResponse,
    status_code=status.HTTP_201_CREATED,
)
def register_user(user: UserCreate, db: Session = Depends(get_db)):
    existing_user = db.scalar(
        select(User).where(User.email == user.email)
    )

    if existing_user:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Email already registered",
        )

    new_user = User(
        name=user.name,
        email=user.email,
        password=hash_password(user.password),
    )

    db.add(new_user)
    db.commit()
    db.refresh(new_user)

    return UserResponse(
        id=new_user.id,
        name=new_user.name,
        email=new_user.email,
    )


@router.post("/login", response_model=TokenResponse)
def login_user(user: UserLogin, db: Session = Depends(get_db)):
    db_user = db.scalar(
        select(User).where(User.email == user.email)
    )

    if not db_user or not verify_password(
        user.password,
        db_user.password,
    ):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid email or password",
        )

    access_token = create_access_token(db_user.id)

    return TokenResponse(
        access_token=access_token,
        user=UserResponse(
            id=db_user.id,
            name=db_user.name,
            email=db_user.email,
        ),
    )


@router.post("/logout")
def logout_user():
    # Since we are using stateless mock tokens, logout just returns success
    return {"message": "Successfully logged out"}
