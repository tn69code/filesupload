ano /etc/zivpn/web.py; exit
from flask import Flask, jsonify, render_template_string, request, redirect, url_for, session, make_response
import json, re, subprocess, os, tempfile, hmac
from datetime import datetime, timedelta

USERS_FILE = "/etc/zivpn/users.json"
CONFIG_FILE = "/etc/zivpn/config.json"
LISTEN_FALLBACK = "5667"
RECENT_SECONDS = 120
LOGO_URL = "https://raw.githubusercontent.com/Upk123/upkvip-ziscript/refs/heads/main/20251018_231111.png"


HTML = """<!doctype html>
<html lang="my"><head><meta charset="utf-8">
<title>ZIVPN User Panel</title>
<meta name="viewport" content="width=device-width,initial-scale=1">
<meta http-equiv="refresh" content="120">
<style>
 :root{
  --bg:#ffffff; --fg:#111; --muted:#666; --card:#fafafa; --bd:#e5e5e5;
  --ok:#0a8a0a; --bad:#c0392b; --unk:#666; --btn:#fff; --btnbd:#ccc;
  --pill:#f5f5f5; --pill-bad:#ffecec; --pill-ok:#eaffe6; --pill-unk:#f0f0f0;
 }
 html,body{background:var(--bg);color:var(--fg)}
 body{font-family:system-ui,Segoe UI,Roboto,Arial;margin:24px}
 header{display:flex;align-items:center;gap:14px;margin-bottom:16px}
 h1{margin:0;font-size:1.8em;font-weight:600;line-height:1.2}
 .sub{color:var(--muted);font-size:.95em}
 .btn{
   padding:8px 14px;border-radius:999px;border:1px solid var(--btnbd);
   background:var(--btn);color:var(--fg);text-decoration:none;white-space:nowrap;cursor:pointer
 }
 table{border-collapse:collapse;width:100%;max-width:980px}
 th,td{border:1px solid var(--bd);padding:10px;text-align:left}
 th{background:var(--card)}
 .ok{color:var(--ok);background:var(--pill-ok)}
 .bad{color:var(--bad);background:var(--pill-bad)}
 .unk{color:var(--unk);background:var(--pill-unk)}
 .pill{display:inline-block;padding:4px 10px;border-radius:999px}
 form.box{margin:18px 0;padding:12px;border:1px solid var(--bd);border-radius:12px;background:var(--card);max-width:980px}
 label{display:block;margin:6px 0 2px}
 input{width:100%;max-width:420px;padding:9px 12px;border:1px solid var(--bd);border-radius:10px}
 .row{display:flex;gap:18px;flex-wrap:wrap}
 .row>div{flex:1 1 220px}
 .msg{margin:10px 0;color:var(--ok)}
 .err{margin:10px 0;color:var(--bad)}
 .muted{color:var(--muted)}
 .delform{display:inline}
 tr.expired td{opacity:.9; text-decoration-color: var(--bad);}
 .center{display:flex;align-items:center;justify-content:center}
 .login-card{max-width:auto;margin:70px auto;padding:24px;border:1px solid var(--bd);border-radius:14px;background:var(--card)}
 .login-card h3{margin:10px}
 .logo{height:64px;width:auto;border-radius:14px;box-shadow:0 2px 6px rgba(0,0,0,0.15)}

     /* ပုံမှန် စတိုင်များ Reset လုပ်ခြင်း */
* {
    box-sizing: border-box;
    margin: 0;
    padding: 0;
    font-family: sans-serif; /* သင့်တော်တဲ့ font ကို ပြောင်းနိုင်ပါတယ်။ */
}
sody {
    background-color: #f0f2f5; /* နောက်ခံ အရောင် အဖြူဘက်သမ်းသော မီးခိုးရောင် */
    display: flex;
    justify-content: center;
    align-items: center;
    min-height: 100vh;
}

.login-container {
    background-color: #ffffff; /* Login Box ရဲ့ နောက်ခံ အဖြူရောင် */
    padding: 40px 30px;
    border-radius: 12px;
    box-shadow: 0 4px 10px rgba(0, 0, 0, 0.1); /* အရိပ်လေး ပေးခြင်း */
    width: 100%;
    max-width: 350px; /* အကျယ်ကို ကန့်သတ်ခြင်း */
    text-align: center;
}

.profile-image-container {
    display: inline-block;
    margin-bottom: 20px;
    border-radius: 50%;
    overflow: hidden;
    border: 3px solid #f0f2f5; /* ပုံပတ်လည် ဘောင်လေး */
}

.profile-image {
    width: 80px; /* ပုံအရွယ်အစား */
    height: 80px;
    object-fit: cover;
    display: block;
}

h1 {
    font-size: 24px;
    color: #333333;
    margin-bottom: 5px;
}

.panel-title {
    font-size: 14px;
    color: #666666;
    margin-bottom: 30px;
}

.input-group {
    margin-bottom: 15px;
}

input[type="p"],
input[type="password"] {
    width: 100%;
    padding: 12px 15px;
    border: 1px solid #dddddd;
    border-radius: 8px;
    font-size: 16px;
    outline: none;
    transition: border-color 0.3s;
}

/* ပုံထဲကလို Password input မှာပဲ ဘောင်ထူထူလေး ထည့်ဖို့ */
input[type="p"] {
    border: 2px solid #5a5a5a; 
}

input:focus {
    border-color: #007bff; /* Focus လုပ်တဲ့အခါ အရောင်ပြောင်းဖို့ */
}

.login-button {
    width: 100%;
    padding: 12px;
    background-color: #007bff; /* ခလုတ်အရောင် (အပြာရောင်) */
    color: white;
    border: none;
    border-radius: 8px;
    font-size: 16px;
    cursor: pointer;
    transition: background-color 0.3s;
    margin-top: 20px;
}

.login-button:hover {
    background-color: #0056b3;
}</style>

</head><bsody>

{% if not authed %}
<body>
    <div class="login-container">
        <div class="profile-image-container">
            <img src="path/to/kdev-profile-pic.jpg" alt="KDEV Profile" class="profile-image">
        </div>
        <h1>KDEV</h1>
        <p class="panel-title">ZIVPN User Panel – Login</p>
<form action="/login" method="POST" class="login-form">
            <div class="input-group">
                <input type="text" id="username" name="u" placeholder="Username" required>
            </div>
            <div class="input-group">
                <input type="password" id="password" name="p" placeholder="Password" required>
            </div>
            <button type="submit" class="login-button">Login</button>
        </form>
    </div>
</body>
{% else %}

<header>
    <div class="sub">ZIVPN User Panel</div>
  </div>
  <div style="display:flex;gap:8px;align-items:center">
    <a class="btn" href="https://m.me/tak69" target="_blank" rel="noopener">💬 Contact (Messenger)</a>
    <a class="btn" href="/logout">Logout</a>
  </div>
</header>

<form method="post" action="/add" class="box">
  <h3>➕ အသုံးပြုသူ အသစ်ထည့်ရန်</h3>
  {% if msg %}<div class="msg">{{msg}}</div>{% endif %}
  {% if err %}<div class="err">{{err}}</div>{% endif %}
  <div class="row">
    <div><label>👤 User</label><input name="user" required></div>
    <div><label>🔑 Password</label><input name="password" required></div>
  </div>
  <div class="row">
    <div><label>⏰ Expires (ထည့်သွင်းလိုသည့်ရက်)</label><input name="expires" placeholder="2025-12-31 or 30"></div>
    <div><label>🔌 UDP Port (6000–19999)</label><input name="port" placeholder="auto"></div>
  </div>
  <button class="btn" type="submit">Save + Sync</button>
</form>

<table>
  <tr>
    <th>👤 User</th><th>🔑 Password</th><th>⏰ Expires</th>
    <th>🔌 Port</th><th>🔎 Status</th><th>🗑️ Delete</th>
  </tr>
  {% for u in users %}
  <tr class="{% if u.expires and u.expires < today %}expired{% endif %}">
    <td class="usercell">{{u.user}}</td>
    <td>{{u.password}}</td>
    <td>{% if u.expires %}{{u.expires}}{% else %}<span class="muted">—</span>{% endif %}</td>
    <td>{% if u.port %}{{u.port}}{% else %}<span class="muted">—</span>{% endif %}</td>
    <td>
      {% if u.status == "Online" %}<span class="pill ok">Online</span>
      {% elif u.status == "Offline" %}<span class="pill bad">Offline</span>
      {% else %}<span class="pill unk">Unknown</span>
      {% endif %}
    </td>
    <td>
      <form class="delform" method="post" action="/delete" onsubmit="return confirm('ဖျက်မလား?')">
        <input type="hidden" name="user" value="{{u.user}}">
        <button type="submit" class="btn" style="border-color:transparent;background:#ffecec">Delete</button>
      </form>
    </td>
  </tr>
  {% endfor %}
</table>

{% endif %}
</body></html>"""

app = Flask(__name__)

# Secret & Admin credentials (via env)
app.secret_key = os.environ.get("WEB_SECRET","dev-secret-change-me")
ADMIN_USER = os.environ.get("WEB_ADMIN_USER","kdev").strip()
ADMIN_PASS = os.environ.get("WEB_ADMIN_PASSWORD","kdev").strip()

def read_json(path, default):
  try:
    with open(path,"r") as f: return json.load(f)
  except Exception:
    return default

def write_json_atomic(path, data):
  d=json.dumps(data, ensure_ascii=False, indent=2)
  dirn=os.path.dirname(path); fd,tmp=tempfile.mkstemp(prefix=".tmp-", dir=dirn)
  try:
    with os.fdopen(fd,"w") as f: f.write(d)
    os.replace(tmp,path)
  finally:
    try: os.remove(tmp)
    except: pass

def load_users():
  v=read_json(USERS_FILE,[])
  out=[]
  for u in v:
    out.append({"user":u.get("user",""),
                "password":u.get("password",""),
                "expires":u.get("expires",""),
                "port":str(u.get("port","")) if u.get("port","")!="" else ""})
  return out

def save_users(users): write_json_atomic(USERS_FILE, users)

def get_listen_port_from_config():
  cfg=read_json(CONFIG_FILE,{})
  listen=str(cfg.get("listen","")).strip()
  m=re.search(r":(\d+)$", listen) if listen else None
  return (m.group(1) if m else LISTEN_FALLBACK)

def get_udp_listen_ports():
  out=subprocess.run("ss -uHln", shell=True, capture_output=True, text=True).stdout
  return set(re.findall(r":(\d+)\s", out))

def pick_free_port():
  used={str(u.get("port","")) for u in load_users() if str(u.get("port",""))}
  used |= get_udp_listen_ports()
  for p in range(6000,20000):
    if str(p) not in used: return str(p)
  return ""

def has_recent_udp_activity(port):
  if not port: return False
  try:
    out=subprocess.run("conntrack -L -p udp 2>/dev/null | grep 'dport=%s\\b'"%port,
                       shell=True, capture_output=True, text=True).stdout
    return bool(out)
  except Exception:
    return False

def status_for_user(u, active_ports, listen_port):
  port=str(u.get("port",""))
  check_port=port if port else listen_port
  if has_recent_udp_activity(check_port): return "Online"
  if check_port in active_ports: return "Offline"
  return "Unknown"

# --- mirror sync: config.json(auth.config) = users.json passwords only
def sync_config_passwords(mode="mirror"):
  cfg=read_json(CONFIG_FILE,{})
  users=load_users()
  users_pw=sorted({str(u["password"]) for u in users if u.get("password")})
  if mode=="merge":
    old=[]
    if isinstance(cfg.get("auth",{}).get("config",None), list):
      old=list(map(str, cfg["auth"]["config"]))
    new_pw=sorted(set(old)|set(users_pw))
  else:
    new_pw=users_pw
  if not isinstance(cfg.get("auth"),dict): cfg["auth"]={}
  cfg["auth"]["mode"]="passwords"
  cfg["auth"]["config"]=new_pw
  cfg["listen"]=cfg.get("listen") or ":5667"
  cfg["cert"]=cfg.get("cert") or "/etc/zivpn/zivpn.crt"
  cfg["key"]=cfg.get("key") or "/etc/zivpn/zivpn.key"
  cfg["obfs"]=cfg.get("obfs") or "zivpn"
  write_json_atomic(CONFIG_FILE,cfg)
  subprocess.run("systemctl restart zivpn.service", shell=True)

# --- Login guard helpers
def login_enabled(): return bool(ADMIN_USER and ADMIN_PASS)
def is_authed(): return session.get("auth") == True
def require_login():
  if login_enabled() and not is_authed():
    return False
  return True

def build_view(msg="", err=""):
  if not require_login():
    # render login UI
    return render_template_string(HTML, authed=False, logo=LOGO_URL, err=session.pop("login_err", None))
  users=load_users()
  active=get_udp_listen_ports()
  listen_port=get_listen_port_from_config()
  view=[]
  for u in users:
    view.append(type("U",(),{
      "user":u.get("user",""),
      "password":u.get("password",""),
      "expires":u.get("expires",""),
      "port":u.get("port",""),
      "status":status_for_user(u,active,listen_port)
    }))
  view.sort(key=lambda x:(x.user or "").lower())
  today=datetime.now().strftime("%Y-%m-%d")
  return render_template_string(HTML, authed=True, logo=LOGO_URL, users=view, msg=msg, err=err, today=today)

@app.route("/login", methods=["GET","POST"])
def login():
  if not login_enabled():
    return redirect(url_for('index'))
  if request.method=="POST":
    u=(request.form.get("u") or "").strip()
    p=(request.form.get("p") or "").strip()
    if hmac.compare_digest(u, ADMIN_USER) and hmac.compare_digest(p, ADMIN_PASS):
      session["auth"]=True
      return redirect(url_for('index'))
    else:
      session["auth"]=False
      session["login_err"]="မှန်ကန်မှုမရှိပါ (username/password)"
      return redirect(url_for('login'))
  # GET
  return render_template_string(HTML, authed=False, logo=LOGO_URL, err=session.pop("login_err", None))

@app.route("/logout", methods=["GET"])
def logout():
  session.pop("auth", None)
  return redirect(url_for('login') if login_enabled() else url_for('index'))

@app.route("/", methods=["GET"])
def index(): return build_view()

@app.route("/add", methods=["POST"])
def add_user():
  if not require_login(): return redirect(url_for('login'))
  user=(request.form.get("user") or "").strip()
  password=(request.form.get("password") or "").strip()
  expires=(request.form.get("expires") or "").strip()
  port=(request.form.get("port") or "").strip()

  if expires.isdigit():
    expires=(datetime.now() + timedelta(days=int(expires))).strftime("%Y-%m-%d")

  if not user or not password:
    return build_view(err="User နှင့် Password လိုအပ်သည်")
  if expires:
    try: datetime.strptime(expires,"%Y-%m-%d")
    except ValueError:
      return build_view(err="Expires format မမှန်ပါ (YYYY-MM-DD)")
  if port:
    if not re.fullmatch(r"\d{2,5}",port) or not (6000 <= int(port) <= 19999):
      return build_view(err="Port အကွာအဝေး 6000-19999")
  else:
    port=pick_free_port()

  users=load_users(); replaced=False
  for u in users:
    if u.get("user","").lower()==user.lower():
      u["password"]=password; u["expires"]=expires; u["port"]=port; replaced=True; break
  if not replaced:
    users.append({"user":user,"password":password,"expires":expires,"port":port})
  save_users(users); sync_config_passwords()
  return build_view(msg="Saved & Synced")

@app.route("/delete", methods=["POST"])
def delete_user_html():
  if not require_login(): return redirect(url_for('login'))
  user = (request.form.get("user") or "").strip()
  if not user:
    return build_view(err="User လိုအပ်သည်")
  remain = [u for u in load_users() if (u.get("user","").lower() != user.lower())]
  save_users(remain)
  sync_config_passwords(mode="mirror")
  return build_view(msg=f"Deleted: {user}")

@app.route("/api/user.delete", methods=["POST"])
def delete_user_api():
  if not require_login():
    return make_response(jsonify({"ok": False, "err":"login required"}), 401)
  data = request.get_json(silent=True) or {}
  user = (data.get("user") or "").strip()
  if not user:
    return jsonify({"ok": False, "err": "user required"}), 400
  remain = [u for u in load_users() if (u.get("user","").lower() != user.lower())]
  save_users(remain)
  sync_config_passwords(mode="mirror")
  return jsonify({"ok": True})

@app.route("/api/users", methods=["GET","POST"])
def api_users():
  if not require_login():
    return make_response(jsonify({"ok": False, "err":"login required"}), 401)
  if request.method=="GET":
    users=load_users(); active=get_udp_listen_ports(); listen_port=get_listen_port_from_config()
    for u in users: u["status"]=status_for_user(u,active,listen_port)
    return jsonify(users)
  data=request.get_json(silent=True) or {}
  user=(data.get("user") or "").strip()
  password=(data.get("password") or "").strip()
  expires=(data.get("expires") or "").strip()
  port=str(data.get("port") or "").strip()
  if expires.isdigit():
    expires=(datetime.now()+timedelta(days=int(expires))).strftime("%Y-%m-%d")
  if not user or not password: return jsonify({"ok":False,"err":"user/password required"}),400
  if port and (not re.fullmatch(r"\d{2,5}",port) or not (6000<=int(port)<=19999)):
    return jsonify({"ok":False,"err":"invalid port"}),400
  if not port: port=pick_free_port()
  users=load_users(); replaced=False
  for u in users:
    if u.get("user","").lower()==user.lower():
      u["password"]=password; u["expires"]=expires; u["port"]=port; replaced=True; break
  if not replaced:
    users.append({"user":user,"password":password,"expires":expires,"port":port})
  save_users(users); sync_config_passwords()
  return jsonify({"ok":True})

@app.route("/favicon.ico", methods=["GET"])
def favicon(): return ("",204)

@app.errorhandler(405)
def handle_405(e): return redirect(url_for('index'))

if __name__ == "__main__":
  app.run(host="0.0.0.0", port=8080)
