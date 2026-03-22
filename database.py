import sqlite3
import json
import os

DB_PATH = 'kali_note.db'

import os

# --- DEV COMMANDS STATE ---
dev_commands = {
    "reset_swift": False
}

def get_db_connection():
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    return conn

def init_db():
    conn = get_db_connection()
    cursor = conn.cursor()
    
    # 1. Table: devices
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS devices (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            uuid TEXT UNIQUE NOT NULL,
            name TEXT,
            local_count INTEGER DEFAULT 0,
            server_count INTEGER DEFAULT 0,
            sync_status TEXT DEFAULT 'IDLE',
            last_heartbeat TEXT DEFAULT CURRENT_TIMESTAMP
        )
    ''')
    
    # [NEW] Migration for existing devices table (V2.5)
    new_cols = [
        ('last_user_email', 'TEXT'),
        ('last_login_at', 'DATETIME'),
        ('last_verified_at', 'DATETIME'),
        ('local_count', 'INTEGER DEFAULT 0'),
        ('server_count', 'INTEGER DEFAULT 0'),
        ('sync_status', "TEXT DEFAULT 'IDLE'"),
        ('last_heartbeat', 'TEXT DEFAULT CURRENT_TIMESTAMP')
    ]
    for col_name, col_type in new_cols:
        try:
            cursor.execute(f'ALTER TABLE devices ADD COLUMN {col_name} {col_type}')
        except sqlite3.OperationalError:
            pass # Column already exists
    
    # 2. Table: users
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            email TEXT UNIQUE NOT NULL,
            name TEXT,
            photo_url TEXT,
            password_hash TEXT
        )
    ''')
    
    # [NEW] Migration for existing users table
    try:
        cursor.execute('ALTER TABLE users ADD COLUMN password_hash TEXT')
    except sqlite3.OperationalError:
        pass # Column already exists
    
    # 3. Table: device_users
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS device_users (
            device_id INTEGER,
            user_id INTEGER,
            last_login DATETIME,
            last_verified_at DATETIME,
            PRIMARY KEY (device_id, user_id),
            FOREIGN KEY (device_id) REFERENCES devices (id),
            FOREIGN KEY (user_id) REFERENCES users (id)
        )
    ''')
    try:
        cursor.execute("ALTER TABLE device_users ADD COLUMN last_verified_at DATETIME")
    except sqlite3.OperationalError:
        pass # Handle already existing column
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS verification_codes (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            email TEXT NOT NULL,
            code TEXT NOT NULL,
            expires_at DATETIME NOT NULL,
            created_at DATETIME DEFAULT CURRENT_TIMESTAMP
        )
    ''')
    
    # 4. Table: notebooks
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS notebooks (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER,
            name TEXT NOT NULL,
            created_at TEXT DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (user_id) REFERENCES users (id)
        )
    ''')
    
    # 5. Table: pages
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS pages (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            notebook_id INTEGER,
            page_number INTEGER NOT NULL,
            created_at TEXT DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (notebook_id) REFERENCES notebooks (id)
        )
    ''')
    
    # 6. Table: objects (Base Table - V2.3)
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS objects (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            page_id INTEGER,
            type TEXT NOT NULL,         -- PHOTO, AUDIO, TEXT, PENCIL, LINK, FORM, FILE, CIRCLE, BENT_FORM
            
            -- Basic Spatial Metadata (Every object has these)
            x REAL DEFAULT 0,
            y REAL DEFAULT 0,
            width REAL DEFAULT 100,
            height REAL DEFAULT 100,
            
            timestamp TEXT DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (page_id) REFERENCES pages (id)
        )
    ''')
    
    # --- SPEZIALISIERTE TABELLEN (NORMALISIERUNG) ---
    
    # 7. Supplemental: object_texts
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS object_texts (
            object_id INTEGER PRIMARY KEY,
            content TEXT,
            is_pencil BOOLEAN DEFAULT 0,
            FOREIGN KEY (object_id) REFERENCES objects (id) ON DELETE CASCADE
        )
    ''')
    
    # 8. Supplemental: object_files
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS object_files (
            object_id INTEGER PRIMARY KEY,
            name TEXT,
            extension TEXT,             -- .pdf, .docx, .png
            size INTEGER,               -- Bytes
            path TEXT,                  -- Storage path
            FOREIGN KEY (object_id) REFERENCES objects (id) ON DELETE CASCADE
        )
    ''')
    
    # 9. Supplemental: object_audio
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS object_audio (
            object_id INTEGER PRIMARY KEY,
            duration REAL,              -- Duration in seconds
            start_time TEXT,            -- For clipping
            end_time TEXT,              -- For clipping
            path TEXT,
            FOREIGN KEY (object_id) REFERENCES objects (id) ON DELETE CASCADE
        )
    ''')
    
    # 10. Supplemental: object_forms
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS object_forms (
            object_id INTEGER PRIMARY KEY,
            shape_type TEXT,            -- RECT, CIRCLE, BENT, TRIANGLE
            start_x REAL,
            start_y REAL,
            end_x REAL,
            end_y REAL,
            metadata TEXT,              -- Extra JSON (Colors, etc.)
            FOREIGN KEY (object_id) REFERENCES objects (id) ON DELETE CASCADE
        )
    ''')
    
    conn.commit()
    import_users_from_json(conn)
    conn.close()
    print("Normalized Content Database (V2.5) initialized successfully.")

def import_users_from_json(conn):
    base_dir = os.getcwd()
    json_path = os.path.join(base_dir, 'private', 'users_db.json')
    if not os.path.exists(json_path):
        base_dir = os.path.dirname(os.path.abspath(__file__))
        json_path = os.path.join(base_dir, 'private', 'users_db.json')
    if not os.path.exists(json_path): return
    try:
        with open(json_path, 'r') as f:
            data = json.load(f)
        cursor = conn.cursor()
        for email, info in data.items():
            cursor.execute('INSERT INTO users (email, name, photo_url) VALUES (?, ?, ?) ON CONFLICT(email) DO NOTHING', (email, info.get('name'), info.get('photoURL')))
        conn.commit()
    except Exception: pass

# --- AUTH & USERS ---

def save_auth_entry(email, name, photo_url, device_uuid, device_name):
    conn = get_db_connection()
    cursor = conn.cursor()
    
    # 1. Ensure Device Exists (Device identity is constant)
    cursor.execute('''
        INSERT INTO devices (uuid, name) 
        VALUES (?, ?) 
        ON CONFLICT(uuid) DO UPDATE SET name = excluded.name
    ''', (device_uuid, device_name))
    
    # 2. Ensure User Exists
    cursor.execute('''
        INSERT INTO users (email, name, photo_url) 
        VALUES (?, ?, ?) 
        ON CONFLICT(email) DO UPDATE SET 
            name = excluded.name, 
            photo_url = excluded.photo_url
    ''', (email, name, photo_url))
    
    # 3. Update User-Device Session (This is where we track login/verification per user)
    cursor.execute('''
        INSERT INTO device_users (device_id, user_id, last_login) 
        VALUES (
            (SELECT id FROM devices WHERE uuid = ?), 
            (SELECT id FROM users WHERE email = ?), 
            datetime("now")
        ) 
        ON CONFLICT(device_id, user_id) DO UPDATE SET last_login = datetime("now")
    ''', (device_uuid, email))
    
    conn.commit()
    conn.close()

def get_hierarchical_users():
    conn = get_db_connection()
    query = 'SELECT d.uuid, d.name as dname, u.email, u.name as uname, u.photo_url, du.last_login FROM devices d JOIN device_users du ON d.id = du.device_id JOIN users u ON du.user_id = u.id'
    rows = conn.execute(query).fetchall()
    conn.close()
    h = {}
    for r in rows:
        uid = r['uuid']
        if uid not in h: h[uid] = {"name": r['dname'], "accounts": {}}
        h[uid]["accounts"][r['email']] = {"name": r['uname'], "photoURL": r['photo_url'], "last_login": r['last_login']}
    return h

# --- NOTEBOOKS & PAGES ---

def create_notebook(email, name):
    conn = get_db_connection()
    cursor = conn.cursor()
    user_res = cursor.execute("SELECT id FROM users WHERE email = ?", (email,)).fetchone()
    if not user_res:
        conn.close()
        return None
    cursor.execute("INSERT INTO notebooks (user_id, name) VALUES (?, ?)", (user_res[0], name))
    nb_id = cursor.lastrowid
    cursor.execute("INSERT INTO pages (notebook_id, page_number) VALUES (?, 1)", (nb_id,))
    conn.commit()
    conn.close()
    return nb_id

def get_user_notebooks(email):
    conn = get_db_connection()
    query = 'SELECT n.id, n.name, n.created_at, (SELECT COUNT(*) FROM pages WHERE notebook_id = n.id) as page_count FROM notebooks n JOIN users u ON n.user_id = u.id WHERE u.email = ?'
    rows = conn.execute(query, (email,)).fetchall()
    conn.close()
    return [dict(r) for r in rows]

# --- NORMALIZED OBJECT LOGIC ---

def get_notebook_content(notebook_id):
    conn = get_db_connection()
    pages = conn.execute("SELECT * FROM pages WHERE notebook_id = ? ORDER BY page_number", (notebook_id,)).fetchall()
    content = []
    for p in pages:
        p_data = dict(p)
        # Consolidated retrieval with LEFT JOINs
        query = '''
            SELECT o.*, 
                   ot.content as text_content, ot.is_pencil,
                   of.name as file_name, of.extension as file_ext, of.size as file_size, of.path as file_path,
                   oa.duration, oa.start_time, oa.end_time, oa.path as audio_path,
                   osm.shape_type, osm.start_x, osm.start_y, osm.end_x, osm.end_y, osm.metadata as form_meta
            FROM objects o
            LEFT JOIN object_texts ot ON o.id = ot.object_id
            LEFT JOIN object_files of ON o.id = of.object_id
            LEFT JOIN object_audio oa ON o.id = oa.object_id
            LEFT JOIN object_forms osm ON o.id = osm.object_id
            WHERE o.page_id = ?
            ORDER BY o.timestamp
        '''
        objs = conn.execute(query, (p['id'],)).fetchall()
        p_data['objects'] = [dict(o) for o in objs]
        content.append(p_data)
    conn.close()
    return content

def save_object(page_id, obj_type, **kwargs):
    conn = get_db_connection()
    cursor = conn.cursor()
    
    # 1. Save Base Object
    cursor.execute('''
        INSERT INTO objects (page_id, type, x, y, width, height)
        VALUES (?, ?, ?, ?, ?, ?)
    ''', (page_id, obj_type, kwargs.get('x', 0), kwargs.get('y', 0), kwargs.get('width', 100), kwargs.get('height', 100)))
    obj_id = cursor.lastrowid
    
    # 2. Save Specialized Extension
    if obj_type in ['TEXT', 'PENCIL']:
        cursor.execute('INSERT INTO object_texts (object_id, content, is_pencil) VALUES (?, ?, ?)', 
                       (obj_id, kwargs.get('content'), 1 if obj_type == 'PENCIL' else 0))
    
    elif obj_type == 'FILE':
        cursor.execute('INSERT INTO object_files (object_id, name, extension, size, path) VALUES (?, ?, ?, ?, ?)',
                       (obj_id, kwargs.get('name'), kwargs.get('extension'), kwargs.get('size'), kwargs.get('path')))
                       
    elif obj_type == 'AUDIO':
        cursor.execute('INSERT INTO object_audio (object_id, duration, start_time, end_time, path) VALUES (?, ?, ?, ?, ?)',
                       (obj_id, kwargs.get('duration'), kwargs.get('start_time'), kwargs.get('end_time'), kwargs.get('path')))
                       
    elif obj_type in ['FORM', 'BENT_FORM', 'CIRCLE']:
        cursor.execute('INSERT INTO object_forms (object_id, shape_type, start_x, start_y, end_x, end_y, metadata) VALUES (?, ?, ?, ?, ?, ?, ?)',
                       (obj_id, obj_type, kwargs.get('start_x'), kwargs.get('start_y'), kwargs.get('end_x'), kwargs.get('end_y'), kwargs.get('metadata')))
                       
    conn.commit()
    conn.close()
    return obj_id

def update_sync_status(device_uuid, local_count):
    conn = get_db_connection()
    cursor = conn.cursor()
    
    # Get server-side count
    server_res = cursor.execute("SELECT COUNT(*) FROM objects").fetchone()
    server_count = server_res[0] if server_res else 0
    
    # Update consolidated devices table
    cursor.execute('''
        UPDATE devices 
        SET last_heartbeat = datetime("now"),
            local_count = ?,
            server_count = ?,
            sync_status = 'IDLE'
        WHERE uuid = ?
    ''', (local_count, server_count, device_uuid))
    
    conn.commit()
    conn.close()
def create_verification_code(email):
    import random
    import string
    from datetime import datetime, timedelta
    
    # Generate 6-char alphanumeric code
    code = ''.join(random.choices(string.ascii_uppercase + string.digits, k=6))
    expires_at = (datetime.now() + timedelta(minutes=2)).strftime('%Y-%m-%d %H:%M:%S')
    
    conn = get_db_connection()
    cursor = conn.cursor()
    # Delete old codes for this email
    cursor.execute('DELETE FROM verification_codes WHERE email = ?', (email,))
    # Insert new code
    cursor.execute('INSERT INTO verification_codes (email, code, expires_at) VALUES (?, ?, ?)',
                   (email, code, expires_at))
    conn.commit()
    conn.close()
    return code

def verify_otp_code(email, code, device_uuid=None):
    conn = get_db_connection()
    cursor = conn.cursor()
    cursor.execute('''
        SELECT id FROM verification_codes 
        WHERE email = ? AND code = ? AND expires_at > datetime("now")
    ''', (email, code.upper()))
    res = cursor.fetchone()
    if res:
        # Code used, delete it
        cursor.execute('DELETE FROM verification_codes WHERE id = ?', (res[0],))
        
        # Mark device-user session as verified for today
        if device_uuid:
            cursor.execute('''
                UPDATE device_users 
                SET last_verified_at = CURRENT_TIMESTAMP
                WHERE device_id = (SELECT id FROM devices WHERE uuid = ?)
                AND user_id = (SELECT id FROM users WHERE email = ?)
            ''', (device_uuid, email))
            
        conn.commit()
        conn.close()
        return True
    conn.close()
    return False

def has_verified_today(email, device_uuid):
    """Checks if this specific user on this specific device has verified in the last 24 hours."""
    conn = get_db_connection()
    cursor = conn.cursor()
    cursor.execute('''
        SELECT du.last_verified_at 
        FROM device_users du
        JOIN devices d ON du.device_id = d.id
        JOIN users u ON du.user_id = u.id
        WHERE d.uuid = ? AND u.email = ?
        AND du.last_verified_at > datetime('now', '-24 hours')
    ''', (device_uuid, email))
    res = cursor.fetchone()
    conn.close()
    return res is not None

if __name__ == '__main__':
    init_db()
