import asyncio
import jwt
import uuid
from typing import Dict, List
from fastapi import FastAPI, WebSocket, WebSocketDisconnect
from fastapi.responses import JSONResponse
from pydantic import BaseModel

app = FastAPI()

SECRET_KEY = "cricket8bit_super_secret"
ALGORITHM = "HS256"

# Mock Database / State
class PlayerState:
    def __init__(self, username: str):
        self.username = username
        self.status = "idle" # idle, matchmaking, playing
        self.match_id = None

players: Dict[str, PlayerState] = {}
matchmaking_queue: List[str] = []
active_matches: Dict[str, dict] = {} # match_id -> {p1, p2, port}

# Next available port for Godot headless instances to run on
# (In a real system, you'd have an orchestrator like Agones or Docker spinning these up)
next_server_port = 7000 

class LoginRequest(BaseModel):
    username: str

@app.post("/token")
async def login(req: LoginRequest):
    token = jwt.encode({"sub": req.username}, SECRET_KEY, algorithm=ALGORITHM)
    if req.username not in players:
        players[req.username] = PlayerState(req.username)
    return {"access_token": token, "token_type": "bearer"}

@app.websocket("/matchmake")
async def matchmake(websocket: WebSocket, token: str):
    await websocket.accept()
    
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
            # Check if we got matched
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
                
            # Try to matchmake if we are the first in queue and there's someone else
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
                
                # Note: In a real system, you'd `subprocess.Popen` the Godot Headless server here,
                # passing the `port` and `match_id` as CLI arguments!
                print(f"Spawning Headless Server on port {port} for match {match_id}")
                
            await asyncio.sleep(1)
            
    except WebSocketDisconnect:
        if username in matchmaking_queue:
            matchmaking_queue.remove(username)
        player.status = "idle"
        
    await websocket.close()
