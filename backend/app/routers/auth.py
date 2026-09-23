from fastapi import APIRouter, HTTPException, status
from typing import Dict
from app.schemas.auth import UserCreate, UserLogin, TokenResponse, UserResponse
import uuid

router = APIRouter(prefix="/api/auth", tags=["auth"])

# In-memory mock database for users
# Key: email, Value: User Dict
mock_users_db: Dict[str, dict] = {}

@router.post("/register", response_model=UserResponse, status_code=status.HTTP_201_CREATED)
def register_user(user: UserCreate):
    if user.email in mock_users_db:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Email already registered"
        )
    
    user_id = str(uuid.uuid4())
    # In a real app, password must be hashed. For this mock, we store it plain.
    new_user = {
        "id": user_id,
        "name": user.name,
        "email": user.email,
        "password": user.password
    }
    
    mock_users_db[user.email] = new_user
    
    return UserResponse(
        id=user_id,
        name=user.name,
        email=user.email
    )


@router.post("/login", response_model=TokenResponse)
def login_user(user: UserLogin):
    db_user = mock_users_db.get(user.email)
    
    if not db_user or db_user["password"] != user.password:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid email or password"
        )
        
    # Generate a mock token
    access_token = f"mock_token_{uuid.uuid4().hex}"
    
    return TokenResponse(
        access_token=access_token,
        user=UserResponse(
            id=db_user["id"],
            name=db_user["name"],
            email=db_user["email"]
        )
    )


@router.post("/logout")
def logout_user():
    # Since we are using stateless mock tokens, logout just returns success
    return {"message": "Successfully logged out"}
