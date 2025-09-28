from fastapi import APIRouter

router = APIRouter()

@router.get("/hello")
async def hello_world():
    return {"message": "Hello World from FastAPI!"}

@router.get("/items/{item_id}")
async def read_item(item_id: int, q: str = None):
    return {"item_id": item_id, "q": q}

@router.post("/items")
async def create_item(item: dict):
    return {"message": "Item created", "item": item}
    #teeeestr