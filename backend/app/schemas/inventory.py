from pydantic import BaseModel, Field

class InventoryUpdate(BaseModel):
    stock: int = Field(..., ge=0)
