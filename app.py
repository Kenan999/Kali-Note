import os
import json
import base64
import urllib.request
import urllib.parse
import subprocess
import time
import random
import string
from datetime import datetime, timedelta
from flask import Flask, request, jsonify, render_template, send_from_directory
from flask_cors import CORS
import database

# Manual .env loader (zero-dependency)
def load_env():
    env_path = os.path.join(os.path.dirname(__file__), '.env')
    if os.path.exists(env_path):
        with open(env_path) as f:
            for line in f:
                line = line.strip()
                if line and not line.startswith('#') and '=' in line:
                    key, value = line.split('=', 1)
                    os.environ[key.strip()] = value.strip()

load_env()

app = Flask(__name__)
CORS(app)

# CONFIGURATION (loaded from .env)
GOOGLE_CLIENT_ID = os.getenv('GOOGLE_CLIENT_ID')
GOOGLE_CLIENT_SECRET = os.getenv('GOOGLE_CLIENT_SECRET')
NGROK_SUBDOMAIN = os.getenv('NGROK_SUBDOMAIN', 'nonprovided-bunglingly-roxane')
REDIRECT_URI = f"https://{NGROK_SUBDOMAIN}.ngrok-free.dev/oauth2redirect"

# Initialize DB on startup
database.init_db()

def start_ngrok():
    """Start ngrok in the background if it's not already running."""
    token = os.getenv('NGROK_AUTH_TOKEN')
    if not token:
        print("WARNING: NGROK_AUTH_TOKEN not found in .env")
        return
        
    try:
        # Check if already running
        running = subprocess.run(["pgrep", "ngrok"], capture_output=True)
        if running.returncode == 0:
            print("INFO: ngrok is already running.")
            return

        print("INFO: Starting ngrok background process...")
        # Start ngrok on port 3000 with the provided authtoken
        subprocess.Popen(
            ["ngrok", "http", "3000", "--authtoken", token],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL
        )
        time.sleep(2)  # Give it a moment to initialize
    except FileNotFoundError:
        print("WARNING: 'ngrok' command not found. Please install it to enable automated tunneling.")
    except Exception as e:
        print(f"WARNING: Error starting ngrok: {e}")

@app.route('/')
def home():
    return jsonify({"status": "Kali Note Backend Running", "version": "2.0 (Notebooks)"})

@app.route('/dashboard')
def dashboard():
    return send_from_directory('private', 'Auth_Dashboard.html')

@app.route('/oauth2redirect')
def oauth2_redirect():
    # Capture the code specifically for the redirect
    code = request.args.get('code')
    target_url = f"com.kenan.Kali-Note://oauth2redirect?code={code}" if code else f"com.kenan.Kali-Note://oauth2redirect?{request.query_string.decode('utf-8')}"
    
    return f"""
    <html>
        <body style="font-family: sans-serif; text-align: center; padding-top: 50px; background: #0a0a0a; color: white;">
            <h3>Success! Redirecting back to Kali Note...</h3>
            <p>If you are not redirected automatically, <a href="{target_url}" style="color: #8b5cf6;">click here</a>.</p>
            <script>
                // Direct redirect
                window.location.href = "{target_url}";
                // Fallback for some browsers
                setTimeout(function() {{
                    window.location.href = "{target_url}";
                }}, 500);
            </script>
        </body>
    </html>
    """

@app.route('/api/sync/heartbeat', methods=['POST'])
def sync_heartbeat():
    data = request.json
    device_id = data.get('device_id')
    local_count = data.get('local_count', 0)
    
    if not device_id:
        return jsonify({"error": "device_id required"}), 400
        
    database.update_sync_status(device_id, local_count)
    return jsonify({"status": "success", "server_time": time.ctime()})

@app.route('/api/sync/status', methods=['GET'])
def get_sync_status():
    conn = database.get_db_connection()
    query = '''
        SELECT d.name, s.last_heartbeat, s.local_count, s.server_count, s.status 
        FROM sync_status s 
        JOIN devices d ON s.device_id = d.id
    '''
    rows = conn.execute(query).fetchall()
    conn.close()
    return jsonify([dict(r) for r in rows])

@app.route('/update_config', methods=['POST'])
def update_config():
    data = request.json
    return jsonify({"status": "success", "message": "Config update triggered"})

@app.route('/users', methods=['GET'])
def get_users():
    return jsonify(database.get_hierarchical_users())

@app.route('/api/db/<table_name>', methods=['GET'])
def get_raw_table(table_name):
    allowed_tables = ['devices', 'users', 'device_users', 'notebooks', 'pages', 'objects']
    if table_name not in allowed_tables:
        return jsonify({"error": "Table access not allowed"}), 403
    
    conn = database.get_db_connection()
    try:
        rows = conn.execute(f'SELECT * FROM {table_name} LIMIT 100').fetchall()
        return jsonify([dict(r) for r in rows])
    except Exception as e:
        return jsonify({"error": str(e)}), 500
    finally:
        conn.close()

@app.route('/api/dev/reset-db', methods=['POST'])
def dev_reset_db():
    try:
        conn = database.get_db_connection()
        cursor = conn.cursor()
        cursor.execute("DELETE FROM verification_codes")
        cursor.execute("DELETE FROM device_users")
        cursor.execute("DELETE FROM devices")
        cursor.execute("DELETE FROM users")
        cursor.execute("DELETE FROM notebooks")
        cursor.execute("DELETE FROM pages")
        cursor.execute("DELETE FROM objects")
        conn.commit()
        conn.close()
        return jsonify({"message": "Backend database cleared successfully"}), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/api/dev/trigger-swift-reset', methods=['POST'])
def trigger_swift_reset():
    database.dev_commands["reset_swift"] = True
    return jsonify({"message": "Swift reset triggered"}), 200

@app.route('/api/dev/check-commands', methods=['GET'])
def check_commands():
    command = "none"
    if database.dev_commands["reset_swift"]:
        command = "reset_swift"
        database.dev_commands["reset_swift"] = False # Reset flag after consumption
        
    return jsonify({"command": command}), 200

# --- NOTEBOOK ENDPOINTS ---

@app.route('/notebooks', methods=['GET'])
def get_notebooks():
    email = request.args.get('email')
    if not email:
        return jsonify({"error": "Email required"}), 400
    return jsonify(database.get_user_notebooks(email))

@app.route('/notebooks', methods=['POST'])
def add_notebook():
    data = request.json
    email = data.get('email')
    name = data.get('name')
    if not email or not name:
        return jsonify({"error": "Email and name required"}), 400
    nb_id = database.create_notebook(email, name)
    if nb_id is None:
        return jsonify({"error": "User not found"}), 404
    return jsonify({"status": "success", "notebook_id": nb_id})

@app.route('/notebooks/<int:nb_id>', methods=['GET'])
def get_notebook_content(nb_id):
    return jsonify(database.get_notebook_content(nb_id))

@app.route('/objects', methods=['POST'])
def add_object():
    data = request.json
    page_id = data.get('page_id')
    obj_type = data.get('type')
    content = data.get('content')
    
    if not page_id or not obj_type:
        return jsonify({"error": "page_id and type required"}), 400
        
    # Extract optional high-precision fields
    kwargs = {
        "content": content,
        "name": data.get('name'),
        "x": data.get('x'),
        "y": data.get('y'),
        "width": data.get('width'),
        "height": data.get('height'),
        "start_x": data.get('start_x'),
        "start_y": data.get('start_y'),
        "end_x": data.get('end_x'),
        "end_y": data.get('end_y'),
        "file_extension": data.get('file_extension'),
        "file_size": data.get('file_size'),
        "duration": data.get('duration'),
        "start_time": data.get('start_time'),
        "end_time": data.get('end_time'),
        "metadata": data.get('metadata') # Flexible JSON string
    }
    
    database.save_object(page_id, obj_type, **kwargs)
    return jsonify({"status": "Object saved successfully"})

# --- AUTH ENDPOINT ---

@app.route('/auth/google', methods=['POST'])
def auth_google():
    data = request.json
    code = data.get('code')
    device_name = data.get('device_name', 'Unknown Device')
    device_id = data.get('device_id', 'unknown_id')
    
    if not code:
        return jsonify({"error": "Code required"}), 400
    
    try:
        # 1. Exchange Code for Tokens
        token_url = 'https://oauth2.googleapis.com/token'
        payload = urllib.parse.urlencode({
            'code': code,
            'client_id': GOOGLE_CLIENT_ID,
            'client_secret': GOOGLE_CLIENT_SECRET,
            'redirect_uri': REDIRECT_URI,
            'grant_type': 'authorization_code'
        }).encode()
        
        req = urllib.request.Request(token_url, data=payload)
        with urllib.request.urlopen(req) as response:
            token_data = json.loads(response.read().decode())
            id_token = token_data.get('id_token')
            
        # 2. Decode ID Token (JWT)
        body = id_token.split('.')[1]
        body += '=' * (4 - len(body) % 4)
        user_info = json.loads(base64.b64decode(body).decode())
        
        email = user_info.get('email')
        name = user_info.get('name')
        photo_url = user_info.get('picture')
        
        # 3. Save Entry & CHECK BYPASS (Unified Security)
        database.save_auth_entry(email, name, photo_url, device_id, device_name)
        
        if database.has_verified_today(email, device_id):
            return jsonify({
                "requires_verification": False,
                "email": email,
                "name": name,
                "photoURL": photo_url,
                "token": f"session_{email}_verified_bypass"
            })
        
        code = database.create_verification_code(email)
        print(f"\n{'='*40}")
        print(f"🔑 [GOOGLE] OTP FOR {email}: {code}")
        print(f"{'='*40}\n")
        
        return jsonify({
            "requires_verification": True,
            "email": email,
            "name": name,
            "photoURL": photo_url
        })
        
    except Exception as e:
        print(f"Auth Error: {e}")
        return jsonify({"error": str(e)}), 500

@app.route('/auth/apple', methods=['POST'])
def auth_apple():
    # SIMULATED APPLE FLOW (Similar to Google)
    data = request.json
    email = data.get('email', 'apple_user@example.com')
    name = data.get('name', 'Apple User')
    device_id = data.get('device_id', 'unknown_ios_device')
    device_name = data.get('device_name', 'Apple Device') # Added device_name extraction
    
    # Save Entry & CHECK BYPASS
    database.save_auth_entry(email, name, None, device_id, device_name) # Used device_name
    
    if database.has_verified_today(email, device_id):
        return jsonify({
            "requires_verification": False,
            "email": email,
            "name": name,
            "photoURL": None,
            "token": f"session_{email}_verified_bypass"
        })
    
    code = database.create_verification_code(email)
    print(f"\n{'='*40}")
    print(f"🔑 [APPLE] OTP FOR {email}: {code}")
    print(f"{'='*40}\n")
    
    return jsonify({
        "requires_verification": True,
        "email": email,
        "name": name,
        "photoURL": None
    })

# --- 2FA EMAIL OTP FLOW ---

@app.route('/api/auth/register', methods=['POST'])
def register():
    data = request.json
    email = data.get('email')
    password = data.get('password')
    name = data.get('name')
    photo_url = data.get('photo_url', '')
    
    if not email or not password:
        return jsonify({"error": "Email and password required"}), 400
        
    conn = database.get_db_connection()
    cursor = conn.cursor()
    
    # Check if user exists
    cursor.execute('SELECT id FROM users WHERE email = ?', (email,))
    if cursor.fetchone():
        conn.close()
        return jsonify({"error": "User already exists"}), 409
        
    # Create user (simulated password hashing for now)
    password_hash = f"hashed_{password}"
    cursor.execute('''
        INSERT INTO users (email, name, photo_url, password_hash) 
        VALUES (?, ?, ?, ?)
    ''', (email, name, photo_url, password_hash))
    
    # Generate OTP
    otp_code = ''.join(random.choices(string.digits, k=6))
    expires_at = (datetime.now() + timedelta(minutes=2)).strftime('%Y-%m-%d %H:%M:%S')
    
    cursor.execute('''
        INSERT INTO verification_codes (email, code, expires_at) 
        VALUES (?, ?, ?)
    ''', (email, otp_code, expires_at))
    
    print("\n" + "="*50)
    print(f" NEW REGISTRATION CODE FOR: {email}")
    print(f" CODE: {otp_code} (Valid for 2 min)")
    print("="*50 + "\n")
    
    conn.commit()
    conn.close()
    
    return jsonify({
        "message": "User created. Verification code sent.",
        "requires_verification": True,
        "email": email
    }), 201

@app.route('/api/auth/login-request', methods=['POST'])
def login_request():
    data = request.json
    email = data.get('email')
    password = data.get('password')
    device_id = data.get('device_id')
    
    # Verify existing user
    conn = database.get_db_connection()
    cursor = conn.cursor()
    cursor.execute('SELECT password_hash, name FROM users WHERE email = ?', (email,))
    user = cursor.fetchone()
    conn.close()
    
    if not user:
        return jsonify({"error": "User not found"}), 404
    
    # If password is provided, check it (Standard Login)
    if password and password != "SAVED_SESSION":
        if user[0] != f"hashed_{password}":
            return jsonify({"error": "Invalid password"}), 401
            
    # CHECK BYPASS
    if device_id and database.has_verified_today(email, device_id):
        return jsonify({
            "requires_verification": False, 
            "email": email,
            "token": f"session_{email}_verified_bypass"
        }), 200
    
    # Generate and save OTP (Mandatory for ALL logins/switches)
    code = database.create_verification_code(email)
    
    # 🔑 Terminal Notification
    print(f"\n{'='*40}")
    print(f"🔑 OTP FOR {email} ({'SWITCH' if not password or password == 'SAVED_SESSION' else 'LOGIN'}): {code}")
    print(f"{'='*40}\n")
    
    return jsonify({"message": "Code sent", "email": email, "requires_verification": True}), 200

@app.route('/api/auth/verify-code', methods=['POST'])
def verify_code():
    data = request.json
    email = data.get('email')
    code = data.get('code')
    device_id = data.get('device_id')
    
    if database.verify_otp_code(email, code, device_uuid=device_id):
        # Verification successful, return user info
        conn = database.get_db_connection()
        cursor = conn.cursor()
        cursor.execute('SELECT email, name, photo_url FROM users WHERE email = ?', (email,))
        user = cursor.fetchone()
        conn.close()
        
        return jsonify({
            "email": user[0],
            "name": user[1],
            "photoURL": user[2],
            "token": f"session_{email}_verified"
        }), 200
    else:
        return jsonify({"error": "Invalid or expired code"}), 401

if __name__ == '__main__':
    # start_ngrok() # Disabled per user request for separate processes
    app.run(host='0.0.0.0', port=3000)
