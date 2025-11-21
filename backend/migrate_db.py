"""
Database migration script to add organizer_secret column to existing groups table.
Run this once after deploying the new code.
"""
from sqlalchemy import text
from database import engine

def migrate():
    """Add organizer_secret column if it doesn't exist"""
    with engine.connect() as conn:
        # Check if column exists
        result = conn.execute(text("""
            SELECT column_name 
            FROM information_schema.columns 
            WHERE table_name='groups' AND column_name='organizer_secret'
        """))
        
        if result.fetchone() is None:
            print("Adding organizer_secret column to groups table...")
            conn.execute(text("""
                ALTER TABLE groups 
                ADD COLUMN organizer_secret VARCHAR
            """))
            conn.commit()
            print("✅ Migration complete! organizer_secret column added.")
        else:
            print("✅ organizer_secret column already exists. No migration needed.")

if __name__ == "__main__":
    migrate()
