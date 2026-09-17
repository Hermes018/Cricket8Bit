import json
import os
from typing import Optional, List
from sqlmodel import SQLModel, Field, Session, create_engine, select

# Models
class User(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    username: str = Field(index=True, unique=True)
    virtual_currency_balance: int = Field(default=1000)

class CardTemplate(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    player_id: str = Field(index=True, unique=True)
    rarity_tier: str = Field(index=True) # "Common", "Rare", "Epic"

class UserInventory(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    user_id: int = Field(foreign_key="user.id")
    card_template_id: int = Field(foreign_key="cardtemplate.id")

# Database Setup
sqlite_file_name = "backend/database.db"
sqlite_url = f"sqlite:///{sqlite_file_name}"
engine = create_engine(sqlite_url, echo=False)

def create_db_and_tables():
    SQLModel.metadata.create_all(engine)
    _seed_card_templates()

def _seed_card_templates():
    # Load roster.json and populate CardTemplates if empty
    with Session(engine) as session:
        existing = session.exec(select(CardTemplate)).first()
        if existing:
            return # Already seeded
            
        roster_path = "src/data/db/roster.json"
        if not os.path.exists(roster_path):
            print(f"Cannot seed DB, missing {roster_path}")
            return
            
        with open(roster_path, 'r') as f:
            data = json.load(f)
            
        # Assign rarity based on skill rating
        for p in data.get("players", []):
            skill = p.get("skill_rating", 70)
            if skill >= 85:
                rarity = "Epic"
            elif skill >= 78:
                rarity = "Rare"
            else:
                rarity = "Common"
                
            card = CardTemplate(player_id=p["id"], rarity_tier=rarity)
            session.add(card)
            
        session.commit()
        print("Seeded CardTemplates from roster.json")

def get_session():
    with Session(engine) as session:
        yield session
