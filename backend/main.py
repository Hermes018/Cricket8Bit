import asyncio
import jwt
import uuid
import random
from typing import Dict, List
from fastapi import FastAPI, WebSocket, WebSocketDisconnect, Depends, HTTPException, status
from fastapi.responses import JSONResponse
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from pydantic import BaseModel
from sqlmodel import Session, select

from .database import create_db_and_tables, get_session, User, CardTemplate, UserInventory

app = FastAPI()

SECRET_KEY = "cricket8bit_super_secret"
ALGORITHM = "HS256"
security = HTTPBearer()

@app.on_event("startup")
def on_startup():
    create_db_and_tables()

# Mock Database / State
class PlayerState:
    def __init__(self, username: str):
        self.username = username
        self.status = "idle" # idle, matchmaking, playing
        self.match_id = None

players: Dict[str, PlayerState] = {}
matchmaking_queue: List[str] = []
active_matches: Dict[str, dict] = {} # match_id -> {p1, p2, port}

next_server_port = 7000 

class LoginRequest(BaseModel):
    username: str

def get_current_user(credentials: HTTPAuthorizationCredentials = Depends(security), session: Session = Depends(get_session)) -> User:
    try:
        payload = jwt.decode(credentials.credentials, SECRET_KEY, algorithms=[ALGORITHM])
        username: str = payload.get("sub")
        if username is None:
            raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid token")
    except jwt.PyJWTError:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid token")
        
    user = session.exec(select(User).where(User.username == username)).first()
    if not user:
        user = User(username=username)
        session.add(user)
        session.commit()
        session.refresh(user)
    return user

@app.post("/token")
async def login(req: LoginRequest, session: Session = Depends(get_session)):
    token = jwt.encode({"sub": req.username}, SECRET_KEY, algorithm=ALGORITHM)
    if req.username not in players:
        players[req.username] = PlayerState(req.username)
        
    # Ensure user is in DB
    user = session.exec(select(User).where(User.username == req.username)).first()
    if not user:
        user = User(username=req.username)
        session.add(user)
        session.commit()
        
    return {"access_token": token, "token_type": "bearer"}

@app.get("/inventory")
def get_inventory(current_user: User = Depends(get_current_user), session: Session = Depends(get_session)):
    inventory = session.exec(select(UserInventory).where(UserInventory.user_id == current_user.id)).all()
    cards = []
    for item in inventory:
        card = session.exec(select(CardTemplate).where(CardTemplate.id == item.card_template_id)).first()
        if card:
            cards.append({"player_id": card.player_id, "rarity": card.rarity_tier})
    
    return {
        "balance": current_user.virtual_currency_balance,
        "cards": cards
    }

@app.post("/store/buy_pack")
def buy_pack(current_user: User = Depends(get_current_user), session: Session = Depends(get_session)):
    PACK_COST = 100
    if current_user.virtual_currency_balance < PACK_COST:
        raise HTTPException(status_code=400, detail="Insufficient funds")
        
    # RNG Logic
    roll = random.random()
    if roll < 0.05:
        target_rarity = "Epic"
    elif roll < 0.30:
        target_rarity = "Rare"
    else:
        target_rarity = "Common"
        
    # Pick a random card of that rarity
    cards_of_rarity = session.exec(select(CardTemplate).where(CardTemplate.rarity_tier == target_rarity)).all()
    if not cards_of_rarity:
        # Fallback if no cards of rarity exist
        cards_of_rarity = session.exec(select(CardTemplate)).all()
        
    if not cards_of_rarity:
        raise HTTPException(status_code=500, detail="No card templates in database")
        
    pulled_card = random.choice(cards_of_rarity)
    
    # Update DB
    current_user.virtual_currency_balance -= PACK_COST
    session.add(current_user)
    
    inv_item = UserInventory(user_id=current_user.id, card_template_id=pulled_card.id)
    session.add(inv_item)
    
    session.commit()
    
    return {
        "success": True,
        "balance": current_user.virtual_currency_balance,
        "card": {
            "player_id": pulled_card.player_id,
            "rarity": pulled_card.rarity_tier
        }
    }

@app.websocket("/matchmake")
async def matchmake(websocket: WebSocket, token: str):
    await websocket.accept()
    # (Matchmaking logic remains the same...)
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        username = payload.get("sub")
        if not username or username not in players:
            await websocket.close(code=1008)
            return
    except jwt.PyJWTError:
        await websocket.close(code=1008)
        return
        
    player = players[username]
    player.status = "matchmaking"
    matchmaking_queue.append(username)
    
    await websocket.send_json({"status": "queued", "message": "Waiting for opponent..."})
    
    try:
        while True:
            if player.status == "playing" and player.match_id:
                match = active_matches[player.match_id]
                await websocket.send_json({
                    "status": "matched",
                    "match_id": player.match_id,
                    "server_ip": "127.0.0.1",
                    "server_port": match["port"],
                    "opponent": match["p2"] if match["p1"] == username else match["p1"]
                })
                break
                
            if len(matchmaking_queue) >= 2 and matchmaking_queue[0] == username:
                p1 = matchmaking_queue.pop(0)
                p2 = matchmaking_queue.pop(0)
                
                match_id = str(uuid.uuid4())
                global next_server_port
                port = next_server_port
                next_server_port += 1
                
                active_matches[match_id] = {"p1": p1, "p2": p2, "port": port}
                
                players[p1].status = "playing"
                players[p1].match_id = match_id
                players[p2].status = "playing"
                players[p2].match_id = match_id
                
            await asyncio.sleep(1)
            
    except WebSocketDisconnect:
        if username in matchmaking_queue:
            matchmaking_queue.remove(username)
        player.status = "idle"
        
    await websocket.close()
