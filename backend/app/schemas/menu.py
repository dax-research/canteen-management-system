from typing import Optional
from pydantic import BaseModel, ConfigDict, Field, field_validator

class CategoryResponse(BaseModel):
    id: str
    name: str
    description: Optional[str] = None
    # Exposed so the admin category screen can show and toggle availability.
    # Defaults to True so a payload without it (e.g. from an older client)
    # still validates.
    is_active: bool = True

    model_config = ConfigDict(from_attributes=True)


class FoodItemResponse(BaseModel):
    id: str
    category_id: str
    category_name: str
    name: str
    description: Optional[str] = None
    price: float
    stock: int
    image_url: Optional[str] = None
    is_available: bool

    model_config = ConfigDict(from_attributes=True)


class CategoryCreate(BaseModel):
    name: str = Field(..., min_length=1)
    description: Optional[str] = None
    is_active: bool = True

    @field_validator("name")
    @classmethod
    def name_not_blank(cls, v: str):
        if not v.strip():
            raise ValueError("Name cannot be empty or whitespace-only")
        return v

class CategoryUpdate(BaseModel):
    name: Optional[str] = Field(None, min_length=1)
    description: Optional[str] = None
    is_active: Optional[bool] = None

    @field_validator("name")
    @classmethod
    def name_not_blank_or_null(cls, v: Optional[str]):
        if v is None:
            raise ValueError("name cannot be null")
        if not v.strip():
            raise ValueError("Name cannot be empty or whitespace-only")
        return v

    @field_validator("is_active")
    @classmethod
    def is_active_not_null(cls, v: Optional[bool]):
        if v is None:
            raise ValueError("is_active cannot be null")
        return v

class FoodItemCreate(BaseModel):
    category_id: str
    name: str = Field(..., min_length=1)
    description: Optional[str] = None
    price: float = Field(..., ge=0)
    stock: int = Field(..., ge=0)
    image_url: Optional[str] = None
    is_available: bool = True

    @field_validator("name")
    @classmethod
    def name_not_blank(cls, v: str):
        if not v.strip():
            raise ValueError("Name cannot be empty or whitespace-only")
        return v

class FoodItemUpdate(BaseModel):
    category_id: Optional[str] = None
    name: Optional[str] = Field(None, min_length=1)
    description: Optional[str] = None
    price: Optional[float] = Field(None, ge=0)
    stock: Optional[int] = Field(None, ge=0)
    image_url: Optional[str] = None
    is_available: Optional[bool] = None

    @field_validator("category_id", "price", "stock", "is_available")
    @classmethod
    def not_null(cls, v):
        if v is None:
            raise ValueError("This field cannot be null")
        return v

    @field_validator("name")
    @classmethod
    def name_not_blank_or_null(cls, v: Optional[str]):
        if v is None:
            raise ValueError("name cannot be null")
        if not v.strip():
            raise ValueError("Name cannot be empty or whitespace-only")
        return v
