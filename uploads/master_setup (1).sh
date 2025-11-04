#!/bin/bash
# =========================================================
# CLOUDFLARE DNS PANEL - COMPLETE AUTOMATED SETUP
# Includes: Configuration, PHP/Apache Setup, SSL, and Final UI Files
# =========================================================

# --- CONFIGURATION (START HERE) ---
# Replace these values with your actual Cloudflare details
CF_API_TOKEN="0472OKcWxrte69C5tyasX7la9OPwW_5QXaycDdUF" 
CF_ZONE_ID="9e9629822eadf8caf35ceaabbc588eac"
MAIN_DOMAIN="zivpn-panel.cc"
SUB_DOMAIN="cf-dns.${MAIN_DOMAIN}"

WEB_ROOT="/var/www/html"
CONFIG_DIR="/etc/app-config"
CONFIG_FILE="${CONFIG_DIR}/cloudflare_config.php"
# --- CONFIGURATION (END HERE) ---


echo "================================================"
echo "🚀 CLOUDFLARE DNS PANEL - AUTOMATED SETUP"
echo "================================================"

# 1. System Update and Essential Packages Installation
echo "1/10. System Update and Installing Essential Packages (PHP, Apache, cURL, Certbot)..."
sudo apt update -y

# Install PHP and Apache (assuming PHP 7.4 is the target)
sudo apt install -y apache2 php7.4 php7.4-curl php7.4-json php7.4-common php7.4-cli php7.4-mbstring php7.4-xml libapache2-mod-php7.4 software-properties-common

# Install Certbot (for SSL)
sudo add-apt-repository -y ppa:certbot/certbot
sudo apt update
sudo apt install -y certbot python3-certbot-apache

# Enable PHP and Rewrite Module
sudo a2enmod php7.4 rewrite
sudo systemctl restart apache2

echo "✅ Basic environment setup completed."

# 2. Check and Fix common PHP Configuration issues (short_open_tag)
echo "2/10. Checking php.ini for short_open_tag..."
# Check /etc/php/7.4/apache2/php.ini (or similar)
PHP_INI_FILE=$(find /etc/php/ -name php.ini | grep apache2 | head -n 1)

if [ -f "$PHP_INI_FILE" ]; then
    sudo sed -i 's/^short_open_tag = Off/short_open_tag = On/' "$PHP_INI_FILE"
    echo "   -> short_open_tag set to On in $PHP_INI_FILE."
else
    echo "   -> Warning: Could not find PHP INI file for Apache."
fi
sudo systemctl restart apache2
echo "✅ PHP configuration (short_open_tag) checked and Apache restarted."

# 3. Create Secure Configuration Directory and File
echo "3/10. Creating secure configuration file: ${CONFIG_FILE}..."
sudo mkdir -p ${CONFIG_DIR}
cat << EOF_CONFIG | sudo tee "${CONFIG_FILE}" > /dev/null
<?php
// Cloudflare API Configuration (Do NOT store this file in ${WEB_ROOT})
return [
    'API_TOKEN' => '${CF_API_TOKEN}', 
    'ZONE_ID' => '${CF_ZONE_ID}',
    'DOMAIN' => '${MAIN_DOMAIN}',
];
?>
EOF_CONFIG
echo "✅ Configuration file created."

# 4. Create and Configure Apache Virtual Host (HTTP Only for now)
echo "4/10. Creating Apache Virtual Host for ${SUB_DOMAIN}..."
VHOST_CONF="/etc/apache2/sites-available/${SUB_DOMAIN}.conf"
cat << EOF_VHOST | sudo tee "$VHOST_CONF" > /dev/null
<VirtualHost *:80>
    ServerName ${SUB_DOMAIN}
    DocumentRoot ${WEB_ROOT}
    
    <Directory ${WEB_ROOT}>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>
    
    ErrorLog \${APACHE_LOG_DIR}/${SUB_DOMAIN}-error.log
    CustomLog \${APACHE_LOG_DIR}/${SUB_DOMAIN}-access.log combined
</VirtualHost>
EOF_VHOST

sudo a2ensite "${SUB_DOMAIN}.conf"
sudo a2dissite 000-default.conf # Disable default config (optional but clean)
sudo systemctl reload apache2
echo "✅ Virtual Host created and enabled. Restarted Apache."

# 5. SSL Installation using Certbot (Requires DNS A Record to be pointing to this VPS)
echo "5/10. Installing SSL (Certbot) for ${SUB_DOMAIN}..."
# Use webroot to verify ownership
sudo certbot --apache -d "${SUB_DOMAIN}" --agree-tos --email your.email@example.com --redirect --non-interactive 

if [ $? -eq 0 ]; then
    echo "✅ SSL certificate successfully installed and Apache config updated."
else
    echo "⚠️ WARNING: Certbot failed. Check DNS A Record for ${SUB_DOMAIN} pointing to this VPS IP."
fi

# 6. Create index.php (Clean Modern UI)
echo "6/10. Creating index.php with Clean Modern UI..."
cat << 'EOF_INDEX_PHP' | sudo tee "${WEB_ROOT}/index.php" > /dev/null
<?php 
// Base Domain ကို စနစ်တကျ ထုတ်ပြရန်
$domain = "zivpn-panel.cc"; // Set manually if needed, or derived from config
?>
<!DOCTYPE html>
<html lang="my">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Cloudflare DNS Record စီမံခန့်ခွဲခြင်း</title>
    <style>
        @import url('https://fonts.googleapis.com/css2?family=Padauk:wght@400;700&display=swap');
        body { 
            font-family: 'Padauk', Arial, sans-serif; 
            margin: 0; 
            padding: 20px; 
            background-color: #f5f7fa; 
            color: #2c3e50;
            font-size: 15px; /* Optimal Base Font Size */
        }
        .container { 
            max-width: 480px; 
            margin: 20px auto; 
            padding: 30px; 
            background: #ffffff; 
            border-radius: 12px; 
            box-shadow: 0 8px 25px rgba(0, 0, 0, 0.1); 
        }
        h2 { 
            color: #3498db; 
            border-bottom: 2px solid #ecf0f1; 
            padding-bottom: 15px; 
            margin-bottom: 30px; 
            text-align: center; 
            font-weight: 700;
            font-size: 1.6em; 
        }
        label { 
            display: block; 
            margin-bottom: 6px; 
            font-weight: 700; 
            color: #34495e; 
            font-size: 1.05em; 
        }
        input[type="text"], select { 
            width: 100%; 
            padding: 10px 12px; 
            margin-bottom: 20px; 
            border: 1px solid #bdc3c7; 
            border-radius: 6px; 
            box-sizing: border-box; 
            font-size: 1em;
            transition: border-color 0.3s, box-shadow 0.3s;
        }
        input[type="text"]:focus, select:focus {
            border-color: #3498db;
            box-shadow: 0 0 5px rgba(52, 152, 219, 0.5);
            outline: none;
        }
        input[type="submit"] { 
            width: 100%; 
            padding: 12px; 
            background-color: #2ecc71; 
            color: white; 
            cursor: pointer; 
            font-size: 1.1em; 
            font-weight: 700; 
            border: none; 
            border-radius: 6px; 
            transition: background-color 0.3s; 
            font-family: 'Padauk', sans-serif;
            box-shadow: 0 4px 10px rgba(46, 204, 113, 0.4);
        }
        input[type="submit"]:hover { background-color: #27ae60; }
        .domain-suffix { 
            display: block; 
            margin-top: -15px; 
            margin-bottom: 25px; 
            color: #95a5a6; 
            font-weight: 400; 
            font-size: 0.9em; 
            padding-left: 2px; 
        }
        .list-btn { 
            display: block; 
            text-align: center; 
            padding: 12px; 
            margin-top: 15px; 
            background-color: #3498db; 
            color: white; 
            border-radius: 6px; 
            text-decoration: none; 
            font-weight: 700; 
            transition: background-color 0.3s; 
            font-family: 'Padauk', sans-serif;
            box-shadow: 0 4px 10px rgba(52, 152, 219, 0.4);
        }
        .list-btn:hover { background-color: #2980b9; }

        /* Result Styles */
        .result-box { 
            padding: 15px; 
            border-radius: 8px; 
            margin-top: 30px; 
            white-space: pre-wrap; 
            font-size: 0.95em; 
        }
        .result-title { 
            font-size: 1.05em; 
            font-weight: 700; 
            margin-bottom: 8px; 
            border-bottom: 1px dashed #ccc; 
            padding-bottom: 5px; 
        }
        .result-success { background-color: #e8f8f5; border: 1px solid #2ecc71; color: #1e8449; }
        .result-error { background-color: #fbecec; border: 1px solid #e74c3c; color: #c0392b; }
        .result-info { background-color: #fcf3cf; border: 1px solid #f39c12; color: #b7950b; }
        
        @media (max-width: 600px) {
            .container { padding: 20px; margin: 10px; }
            body { font-size: 14px; } 
        }
    </style>
</head>
<body>
    <div class="container">
        <h2>Cloudflare DNS Record စီမံခန့်ခွဲမှု</h2>

        <form action="process.php?action=manage" method="POST">
            <label for="subdomain">Subdomain (ဥပမာ: svp101):</label>
            <input type="text" id="subdomain" name="subdomain" placeholder="ထည့်သွင်းလိုသော အမည်" required>
            <span class="domain-suffix">.<?php echo htmlspecialchars($domain); ?></span>

            <label for="ip_address">IP Address (A Record တန်ဖိုး):</label>
            <input type="text" id="ip_address" name="ip_address" placeholder="VPS IP Address ကို ဖြည့်သွင်းပါ" required>

            <label for="proxied">Cloudflare Proxy (Security / DDOS ကာကွယ်မှု):</label>
            <select id="proxied" name="proxied">
                <option value="false">Off (DNS Only) - IP တိုက်ရိုက်ချိတ်ရန်</option>
                <option value="true">On (Proxied) - DDOS ကာကွယ်မှုဖြင့်</option>
            </select>

            <input type="submit" value="✅ DNS Record စတင် ဖန်တီး / ပြင်ဆင်မည်">
        </form>

        <a href="list.php" class="list-btn">📋 Record များ စာရင်း ကြည့်ရန်</a>

        <?php 
        if (isset($_GET['result'])) {
            $data = json_decode(base64_decode($_GET['result']), true);
            $class = 'result-info'; 
            $title = 'လုပ်ဆောင်ချက် ရလဒ်:';
            $details = '';

            if (isset($data['status'])) {
                if ($data['status'] === 'SUCCESS') {
                    $class = 'result-success';
                    $title = '✅ အောင်မြင်ပါသည်: Record ဖန်တီး/ပြင်ဆင်ခြင်း ပြီးဆုံးပါသည်။';
                    $details = "Subdomain: **" . htmlspecialchars($data['record_name']) . "**\n";
                    $details .= "IP Address: " . htmlspecialchars($data['vps_ip']) . "\n";
                    $details .= "Proxy Status: " . ($data['proxied'] ? "On (Proxied)" : "Off (DNS Only)") . "\n";
                    $details .= "\nCloudflare တွင် အသက်ဝင်နေပါပြီ။";
                } elseif ($data['status'] === 'DELETE_SUCCESS') {
                    $class = 'result-success';
                    $title = '🗑️ ဖျက်ခြင်း အောင်မြင်ပါသည်: Record ကို ဖျက်လိုက်ပါသည်။';
                    $details = "ဖျက်လိုက်သော Record: **" . htmlspecialchars($data['record_name']) . "**\n";
                } elseif ($data['status'] === 'INFO') {
                    $title = 'ℹ️ အချက်အလက်: DNS Record သည် တန်ဖိုး မပြောင်းလဲပါ။';
                    $details = "Subdomain: **" . htmlspecialchars($data['record_name']) . "**\n";
                    $details .= "IP Address: " . htmlspecialchars($data['vps_ip']) . "\n";
                    $details .= "Proxy Status: " . ($data['proxied'] ? "On (Proxied)" : "Off (DNS Only)") . "\n";
                } elseif ($data['status'] === 'ERROR') {
                    $class = 'result-error';
                    $title = '❌ အမှားအယွင်း: လုပ်ဆောင်ချက် မအောင်မြင်ပါ။';
                    $details = "Cloudflare Error: " . htmlspecialchars($data['cf_error']) . "\n";
                    $details .= "HTTP Status: " . htmlspecialchars($data['http_code']) . "\n";
                    $details .= "\nFull Response: " . print_r($data['full_response'] ?? [], true);
                }
            }
            
            echo "<div class='result-box {$class}'>";
            echo "<div class='result-title'>{$title}</div>";
            echo "<div class='result-details'>{$details}</div>";
            echo "</div>";

            echo '<script>';
            echo 'if (history.replaceState) {';
            echo '  history.replaceState(null, document.title, window.location.pathname);';
            echo '}';
            echo '</script>';
        }
        ?>
    </div>
</body>
</html>
EOF_INDEX_PHP

# 7. Create process.php (The Core Logic)
echo "7/10. Creating process.php (Core Logic)..."
cat << EOF_PHP | sudo tee "${WEB_ROOT}/process.php" > /dev/null
<?php
// Error Debugging
ini_set('display_errors', 1);
ini_set('display_startup_errors', 1);
error_reporting(E_ALL);

// =========================================================
// CONFIGURATION (Secure Config File မှ ခေါ်ယူခြင်း)
// =========================================================
\$config_file = '${CONFIG_FILE}';
if (!file_exists(\$config_file)) {
    die("Error: Configuration file not found at " . \$config_file);
}

\$config = require \$config_file;

\$api_token = \$config['API_TOKEN']; 
\$zone_id = \$config['ZONE_ID']; 
\$domain = \$config['DOMAIN'];

\$record_type = "A";
\$ttl = 1; 

// Helper function to redirect with JSON result
function redirect_with_result(\$status, \$message_data) {
    \$output_data = array_merge(['status' => \$status], \$message_data);
    \$encoded_result = base64_encode(json_encode(\$output_data));
    header("Location: index.php?result=" . \$encoded_result);
    exit();
}

// =========================================================
// ACTION ROUTING
// =========================================================
\$action = \$_GET['action'] ?? 'manage';

if (\$_SERVER['REQUEST_METHOD'] !== 'POST' && \$action !== 'delete') {
    if (\$action === 'manage') {
        header("Location: index.php"); 
        exit();
    }
}

if (\$action === 'manage') {
    handle_manage_record();
} elseif (\$action === 'delete') {
    handle_delete_record();
} else {
    header("Location: index.php"); 
    exit();
}

// FUNCTION: MANAGE (CREATE/UPDATE) RECORD
function handle_manage_record() {
    global \$api_token, \$zone_id, \$domain, \$record_type, \$ttl;

    \$subdomain = trim(\$_POST['subdomain'] ?? '');
    \$input_ip = trim(\$_POST['ip_address'] ?? ''); 
    \$proxied = (\$_POST['proxied'] === 'true') ? true : false;

    if (empty(\$subdomain)) {
        redirect_with_result('ERROR', ['cf_error' => 'Subdomain Name ကို ဖြည့်သွင်းရန် လိုအပ်ပါသည်။', 'http_code' => 400]);
    }

    \$record_name = \$subdomain . '.' . \$domain;

    // IP Address သည် မှန်ကန်သော IPv4 ပုံစံ ဟုတ်မဟုတ် စစ်ဆေးခြင်း
    if (!filter_var(\$input_ip, FILTER_VALIDATE_IP, FILTER_FLAG_IPV4)) {
        redirect_with_result('ERROR', ['cf_error' => "ထည့်သွင်းထားသော IP Address သည် မှန်ကန်သော IPv4 ပုံစံမဟုတ်ပါ၊ သို့မဟုတ် ဗလာဖြစ်နေပါသည်။", 'http_code' => 400]);
    }
    
    \$vps_ip = \$input_ip; 

    // 1. လက်ရှိ DNS Record ကို ရှာဖွေခြင်း
    \$ch = curl_init("https://api.cloudflare.com/client/v4/zones/\$zone_id/dns_records?type=\$record_type&name=\$record_name");
    curl_setopt(\$ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt(\$ch, CURLOPT_HTTPHEADER, array(
        "Authorization: Bearer \$api_token",
        "Content-Type: application/json"
    ));
    \$response = curl_exec(\$ch);
    \$http_code = curl_getinfo(\$ch, CURLINFO_HTTP_CODE);
    curl_close(\$ch);

    \$data = json_decode(\$response, true);

    if (\$http_code !== 200 || !(\$data['success'] ?? false)) {
        \$cf_error = \$data['errors'][0]['message'] ?? 'Unknown API Query Error (Search)';
        redirect_with_result('ERROR', ['cf_error' => \$cf_error, 'http_code' => \$http_code, 'full_response' => \$data]);
    }

    \$record_id = \$data['result'][0]['id'] ?? null;
    \$current_ip = \$data['result'][0]['content'] ?? null;
    \$current_proxied = \$data['result'][0]['proxied'] ?? null; 
    \$action_url = '';
    \$method = '';

    // 2. စီမံခန့်ခွဲခြင်း (Create or Update)
    if (\$record_id) {
        if (\$current_ip === \$vps_ip && \$current_proxied == \$proxied) {
            redirect_with_result('INFO', ['record_name' => \$record_name, 'vps_ip' => \$vps_ip, 'proxied' => \$proxied]);
        }
        
        \$action_url = "https://api.cloudflare.com/client/v4/zones/\$zone_id/dns_records/\$record_id";
        \$method = 'PUT';

    } else {
        \$action_url = "https://api.cloudflare.com/client/v4/zones/\$zone_id/dns_records";
        \$method = 'POST';
    }

    // Final API Call (Create or Update)
    \$api_data = json_encode([
        'type' => \$record_type,
        'name' => \$subdomain,
        'content' => \$vps_ip,
        'ttl' => \$ttl,
        'proxied' => \$proxied
    ]);

    \$ch = curl_init(\$action_url);
    curl_setopt(\$ch, CURLOPT_CUSTOMREQUEST, \$method);
    curl_setopt(\$ch, CURLOPT_POSTFIELDS, \$api_data);
    curl_setopt(\$ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt(\$ch, CURLOPT_HTTPHEADER, array(
        "Authorization: Bearer \$api_token",
        "Content-Type: application/json",
        'Content-Length: ' . strlen(\$api_data)
    ));
    \$final_response = curl_exec(\$ch);
    \$final_http_code = curl_getinfo(\$ch, CURLINFO_HTTP_CODE);
    curl_close(\$ch);

    \$final_data = json_decode(\$final_response, true);

    if (\$final_http_code >= 200 && \$final_http_code < 300 && (\$final_data['success'] ?? false)) {
        redirect_with_result('SUCCESS', ['record_name' => \$record_name, 'vps_ip' => \$vps_ip, 'proxied' => \$proxied]);
    } else {
        \$cf_error = \$final_data['errors'][0]['message'] ?? 'Unknown API Error (Create/Update)';
        redirect_with_result('ERROR', ['cf_error' => \$cf_error, 'http_code' => \$final_http_code, 'full_response' => \$final_data]);
    }
}


// FUNCTION: DELETE RECORD
function handle_delete_record() {
    global \$api_token, \$zone_id;

    \$record_id = trim(\$_POST['record_id'] ?? '');
    \$record_name = trim(\$_POST['record_name'] ?? '');

    if (empty(\$record_id) || empty(\$record_name)) {
        redirect_with_result('ERROR', ['cf_error' => 'Delete လုပ်ရန် Record ID မပြည့်စုံပါ။', 'http_code' => 400]);
    }
    
    // API Call: DELETE
    \$action_url = "https://api.cloudflare.com/client/v4/zones/\$zone_id/dns_records/\$record_id";

    \$ch = curl_init(\$action_url);
    curl_setopt(\$ch, CURLOPT_CUSTOMREQUEST, 'DELETE');
    curl_setopt(\$ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt(\$ch, CURLOPT_HTTPHEADER, array(
        "Authorization: Bearer \$api_token",
        "Content-Type: application/json"
    ));
    \$final_response = curl_exec(\$ch);
    \$final_http_code = curl_getinfo(\$ch, CURLINFO_HTTP_CODE);
    curl_close(\$ch);

    \$final_data = json_decode(\$final_response, true);

    if (\$final_http_code === 200 && (\$final_data['success'] ?? false)) {
        redirect_with_result('DELETE_SUCCESS', ['record_name' => \$record_name]);
    } else {
        \$cf_error = \$final_data['errors'][0]['message'] ?? 'Unknown API Error during delete';
        redirect_with_result('ERROR', ['cf_error' => \$cf_error, 'http_code' => \$final_http_code, 'full_response' => \$final_data]);
    }
}
?>
EOF_PHP

# 8. Create list.php (Clean Modern UI)
echo "8/10. Creating list.php with Clean Modern UI..."
cat << EOF_LIST_PHP | sudo tee "${WEB_ROOT}/list.php" > /dev/null
<?php
// Error Debugging
ini_set('display_errors', 1);
ini_set('display_startup_errors', 1);
error_reporting(E_ALL);

// =========================================================
// CONFIGURATION (Secure Config File မှ ခေါ်ယူခြင်း)
// =========================================================
\$config_file = '${CONFIG_FILE}';
if (!file_exists(\$config_file)) {
    die("Error: Configuration file not found at " . \$config_file);
}

\$config = require \$config_file;

\$api_token = \$config['API_TOKEN']; 
\$zone_id = \$config['ZONE_ID']; 
\$domain = \$config['DOMAIN'];

\$record_type = "A";

// 1. Cloudflare မှ DNS Record အားလုံးကို ရယူခြင်း
function fetch_records(\$api_token, \$zone_id, \$record_type) {
    \$url = "https://api.cloudflare.com/client/v4/zones/\$zone_id/dns_records?type=\$record_type&per_page=100";
    
    \$ch = curl_init(\$url);
    curl_setopt(\$ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt(\$ch, CURLOPT_HTTPHEADER, array(
        "Authorization: Bearer \$api_token",
        "Content-Type: application/json"
    ));
    \$response = curl_exec(\$ch);
    \$http_code = curl_getinfo(\$ch, CURLINFO_HTTP_CODE);
    curl_close(\$ch);

    \$data = json_decode(\$response, true);

    if (\$http_code !== 200 || !(\$data['success'] ?? false)) {
        \$error_message = \$data['errors'][0]['message'] ?? 'Unknown API Query Error';
        return ['error' => true, 'message' => \$error_message, 'full_response' => \$data];
    }
    return ['error' => false, 'records' => \$data['result'] ?? []];
}

\$result = fetch_records(\$api_token, \$zone_id, \$record_type);
\$records = \$result['records'] ?? [];

// Filter only records that belong to the main domain
\$filtered_records = array_filter(\$records, function(\$record) use (\$domain) {
    return strpos(\$record['name'], \$domain) !== false && \$record['name'] !== \$domain;
});

?>
<!DOCTYPE html>
<html lang="my">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>DNS Records များစာရင်း</title>
    <style>
        @import url('https://fonts.googleapis.com/css2?family=Padauk:wght@400;700&display=swap');
        body { 
            font-family: 'Padauk', Arial, sans-serif; 
            margin: 0; 
            padding: 20px; 
            background-color: #f5f7fa; 
            color: #2c3e50; 
            font-size: 15px;
        }
        .container { 
            max-width: 900px; 
            margin: auto; 
            padding: 30px; 
            background: #fff; 
            border-radius: 12px; 
            box-shadow: 0 8px 25px rgba(0, 0, 0, 0.1); 
        }
        h2 { 
            color: #3498db; 
            border-bottom: 2px solid #ecf0f1; 
            padding-bottom: 15px; 
            margin-bottom: 30px; 
            text-align: center; 
            font-weight: 700;
            font-size: 1.6em;
        }
        
        .back-btn { 
            display: inline-block; 
            padding: 10px 15px; 
            margin-bottom: 20px; 
            background-color: #95a5a6; 
            color: white; 
            border-radius: 6px; 
            text-decoration: none; 
            font-weight: 700; 
            transition: background-color 0.3s; 
            font-family: 'Padauk', sans-serif;
            box-shadow: 0 2px 5px rgba(0,0,0,0.2);
        }
        .back-btn:hover { background-color: #7f8c8d; }

        .info-box { padding: 15px; border-radius: 6px; margin-top: 20px; background-color: #fcf3cf; border: 1px solid #f39c12; color: #b7950b; font-weight: 700; }
        .error-box { padding: 15px; border-radius: 6px; margin-top: 20px; background-color: #fbecec; border: 1px solid #e74c3c; color: #c0392b; font-weight: 700; }

        /* Card View for Mobile */
        .record-card {
            background: #ffffff;
            border: 1px solid #dfe6e9;
            border-radius: 8px;
            padding: 15px;
            margin-bottom: 15px;
            box-shadow: 0 2px 8px rgba(0,0,0,0.05);
        }
        .card-item { display: flex; justify-content: space-between; padding: 5px 0; border-bottom: 1px dotted #ecf0f1; font-size: 1em; }
        .card-item:last-child { border-bottom: none; }
        .card-label { font-weight: 700; color: #34495e; width: 45%; }
        .card-value { text-align: right; width: 55%; word-break: break-all; }
        .delete-form { margin: 15px 0 0; text-align: center; }
        .delete-btn { 
            background-color: #e74c3c; 
            color: white; 
            border: none; 
            padding: 8px 15px; 
            border-radius: 4px; 
            cursor: pointer; 
            transition: background-color 0.3s; 
            width: 100%; 
            font-size: 1em; 
            font-family: 'Padauk', sans-serif;
        }
        .delete-btn:hover { background-color: #c0392b; }
        .proxy-on { color: #f39c12; font-weight: 700; }
        .proxy-off { color: #2ecc71; font-weight: 700; }

        /* Desktop View (Table View) */
        .record-table { display: none; }
        @media (min-width: 768px) {
            .record-card-list { display: none; }
            .record-table { display: table; width: 100%; border-collapse: collapse; margin-top: 15px; font-size: 0.95em; }
            .record-table th, .record-table td { padding: 12px 15px; text-align: left; border-bottom: 1px solid #dfe6e9; }
            .record-table th { background-color: #3498db; color: white; font-weight: 700; font-family: 'Padauk', sans-serif; }
            .record-table tr:nth-child(even) { background-color: #f9f9f9; }
            .record-table tr:hover { background-color: #f0f3f6; }
            .record-table .delete-form { margin: 0; text-align: center; }
            .record-table .delete-btn { width: auto; padding: 6px 12px; font-size: 0.9em; }
        }
        @media (max-width: 600px) {
            body { font-size: 14px; }
        }
    </style>
</head>
<body>
    <div class="container">
        <a href="index.php" class="back-btn">← Record အသစ် ဖန်တီးရန် စာမျက်နှာသို့</a>
        <h2>လက်ရှိ DNS Record များစာရင်း (<?php echo htmlspecialchars(\$domain); ?>)</h2>
        
        <?php if (\$result['error']): ?>
            <div class='error-box'>❌ အမှားအယွင်း: Record စာရင်းရယူရာတွင် မအောင်မြင်ပါ။ <?php echo htmlspecialchars(\$result['message']); ?>
            </div>
        <?php elseif (empty(\$filtered_records)): ?>
            <div class='info-box'>ℹ️ အချက်အလက်: လက်ရှိတွင် A Record များ မရှိသေးပါ။</div>
        <?php else: ?>
            
            <div class="record-card-list">
                <?php foreach (\$filtered_records as \$record): 
                    \$subdomain_only = str_replace("." . \$domain, "", \$record['name']);
                    \$proxy_status = \$record['proxied'] ? "<span class='proxy-on'>On (Proxied)</span>" : "<span class='proxy-off'>Off (DNS Only)</span>";
                ?>
                    <div class="record-card">
                        <div class="card-item"><span class="card-label">Subdomain:</span> <span class="card-value"><?php echo htmlspecialchars(\$subdomain_only); ?></span></div>
                        <div class="card-item"><span class="card-label">IP Address:</span> <span class="card-value"><?php echo htmlspecialchars(\$record['content']); ?></span></div>
                        <div class="card-item"><span class="card-label">Proxy Status:</span> <span class="card-value"><?php echo \$proxy_status; ?></span></div>
                        <div class="delete-form">
                            <form action='process.php?action=delete' method='POST' style='margin: 0;' onsubmit="return confirm('သေချာပါသလား? <?php echo htmlspecialchars(\$subdomain_only); ?> ကို ဖျက်တော့မှာပါ။');">
                                <input type='hidden' name='record_id' value='<?php echo htmlspecialchars(\$record['id']); ?>'>
                                <input type='hidden' name='record_name' value='<?php echo htmlspecialchars(\$record['name']); ?>'>
                                <button type='submit' class='delete-btn'>🗑️ ဖျက်မည်</button>
                            </form>
                        </div>
                    </div>
                <?php endforeach; ?>
            </div>

            <table class="record-table">
                <thead>
                    <tr>
                        <th>Subdomain</th>
                        <th>IP Address</th>
                        <th>Proxy</th>
                        <th>လုပ်ဆောင်ချက်</th>
                    </tr>
                </thead>
                <tbody>
                    <?php foreach (\$filtered_records as \$record): 
                        \$subdomain_only = str_replace("." . \$domain, "", \$record['name']);
                        \$proxy_status = \$record['proxied'] ? "<span class='proxy-on'>On (Proxied)</span>" : "<span class='proxy-off'>Off (DNS Only)</span>";
                    ?>
                        <tr>
                            <td><?php echo htmlspecialchars(\$subdomain_only); ?></td>
                            <td><?php echo htmlspecialchars(\$record['content']); ?></td>
                            <td><?php echo \$proxy_status; ?></td>
                            <td>
                                <form action='process.php?action=delete' method='POST' style='margin: 0;' onsubmit="return confirm('သေချာပါသလား? <?php echo htmlspecialchars(\$subdomain_only); ?> ကို ဖျက်တော့မှာပါ။');">
                                    <input type='hidden' name='record_id' value='<?php echo htmlspecialchars(\$record['id']); ?>'>
                                    <input type='hidden' name='record_name' value='<?php echo htmlspecialchars(\$record['name']); ?>'>
                                    <button type='submit' class='delete-btn'>🗑️ ဖျက်မည်</button>
                                </form>
                            </td>
                        </tr>
                    <?php endforeach; ?>
                </tbody>
            </table>

        <?php endif; ?>
    </div>
</body>
</html>
EOF_LIST_PHP

# 9. Final Permissions (Just in case)
echo "9/10. Setting final file permissions..."
sudo chown -R www-data:www-data "${WEB_ROOT}"
sudo chmod -R 755 "${WEB_ROOT}"
sudo chmod 600 "${CONFIG_FILE}"

# 10. Final Instructions
echo "================================================"
echo "✅ SETUP COMPLETE! (FINAL INSTRUCTIONS)"
echo "================================================"
echo "1. Configuration: API Token and Zone ID ကို စစ်ဆေးရန် ${CONFIG_FILE} ကို ဖွင့်ပါ။"
echo "   (ယခု Script တွင် 'YOUR_CLOUDFLARE_API_TOKEN_HERE' ဖြင့် ထားခဲ့ပါက အမှန်တန်ဖိုးများဖြည့်ရန် လိုအပ်ပါသည်။)"
echo "2. Access Link: Panel ကို https://${SUB_DOMAIN}/ သို့မဟုတ် https://${SUB_DOMAIN}/index.php မှ ဝင်ရောက်ပါ။"
echo "3. Troubleshooting: SSL error ရှိပါက Subdomain A Record သည် ဤ VPS IP သို့ ရောက်နေကြောင်း Cloudflare တွင် စစ်ပါ။"
echo ""
