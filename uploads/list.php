<?php
// Error Debugging
ini_set('display_errors', 1);
ini_set('display_startup_errors', 1);
error_reporting(E_ALL);

// =========================================================
// CONFIGURATION (Secure Config File မှ ခေါ်ယူခြင်း)
// =========================================================
$config_file = '/etc/app-config/cloudflare_config.php';
if (!file_exists($config_file)) {
    die("Error: Configuration file not found at " . $config_file);
}

$config = require $config_file;

$api_token = $config['API_TOKEN']; 
$zone_id = $config['ZONE_ID']; 
$domain = $config['DOMAIN'];

// 1. Cloudflare မှ DNS Record အားလုံးကို ရယူခြင်း (Type အားလုံးပါဝင်ရန် type parameter ဖြုတ်ထားသည်)
function fetch_records($api_token, $zone_id) {
    // A, CNAME, NS Record များ အားလုံးပါဝင်ရန် type parameter ဖြုတ်ထားသည်
    $url = "https://api.cloudflare.com/client/v4/zones/$zone_id/dns_records?per_page=100"; 
    
    $ch = curl_init($url);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_HTTPHEADER, array(
        "Authorization: Bearer $api_token",
        "Content-Type: application/json"
    ));
    $response = curl_exec($ch);
    $http_code = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);

    $data = json_decode($response, true);

    if ($http_code !== 200 || !($data['success'] ?? false)) {
        $error_message = $data['errors'][0]['message'] ?? 'Unknown API Query Error';
        return ['error' => true, 'message' => $error_message, 'full_response' => $data];
    }
    return ['error' => false, 'records' => $data['result'] ?? []];
}

$result = fetch_records($api_token, $zone_id);
$records = $result['records'] ?? [];

// Filter: Root domain (zivpn-panel.cc) နှင့် Cloudflare Default Record များကို ချန်လှပ်ထားသည်
$filtered_records = array_filter($records, function($record) use ($domain) {
    // Filter only A, CNAME, NS records that are NOT the root domain itself
    $valid_type = in_array($record['type'], ['A', 'CNAME', 'NS']);
    $is_not_root = ($record['name'] !== $domain);
    return $valid_type && $is_not_root;
});

?>
<!DOCTYPE html>
<html lang="my">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>DNS Records များစာရင်း</title>
    <style>
        /* Design based on index.php (Modern & Clean) */
        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; margin: 0; padding: 20px; background-color: #e9ecef; }
        .container { max-width: 950px; margin: auto; padding: 35px; background: #ffffff; border-radius: 15px; box-shadow: 0 8px 25px rgba(0, 0, 0, 0.15); }
        h2 { color: #0056b3; border-bottom: 4px solid #0056b3; padding-bottom: 10px; margin-bottom: 30px; text-align: center; font-size: 1.8em; }
        
        /* Navigation Button */
        .back-btn { display: inline-block; padding: 10px 15px; margin-bottom: 25px; background-color: #6c757d; color: white; border-radius: 8px; text-decoration: none; font-weight: bold; transition: background-color 0.3s; }
        .back-btn:hover { background-color: #5a6268; }

        /* Error/Info Box */
        .info-box { padding: 15px; border-radius: 8px; margin-top: 20px; background-color: #fcefd7; border: 2px solid #ffc107; color: #856404; font-weight: bold; }
        .error-box { padding: 15px; border-radius: 8px; margin-top: 20px; background-color: #f8d7da; border: 2px solid #dc3545; color: #721c24; font-weight: bold; }

        /* Record Table Design */
        .record-table { width: 100%; border-collapse: collapse; margin-top: 15px; font-size: 0.9em; table-layout: fixed; }
        .record-table th, .record-table td { padding: 12px 10px; text-align: left; border-bottom: 1px solid #dee2e6; word-wrap: break-word; }
        .record-table th { background-color: #007bff; color: white; font-weight: 600; }
        .record-table tr:nth-child(even) { background-color: #f8f9fa; }
        .record-table .delete-form { margin: 0; text-align: center; }
        .delete-btn { background-color: #dc3545; color: white; border: none; padding: 6px 12px; border-radius: 4px; cursor: pointer; transition: background-color 0.3s; font-size: 0.9em; }
        .delete-btn:hover { background-color: #c82333; }
        .proxy-on { color: #ff9900; font-weight: bold; }
        .proxy-off { color: #28a745; font-weight: bold; }
        .type-badge { display: inline-block; padding: 4px 8px; border-radius: 4px; font-weight: bold; font-size: 0.85em; }
        .type-A { background-color: #007bff; color: white; }
        .type-CNAME { background-color: #28a745; color: white; }
        .type-NS { background-color: #ffc107; color: #343a40; }
        .type-OTHER { background-color: #6c757d; color: white; }

        /* Card view for mobile (Simplified) */
        .record-card-list { display: none; }
        @media (max-width: 768px) {
            .record-table { display: none; }
            .record-card-list { display: block; }
            .record-card {
                background: #fff;
                border: 1px solid #ddd;
                border-radius: 8px;
                padding: 15px;
                margin-bottom: 15px;
                box-shadow: 0 2px 5px rgba(0,0,0,0.05);
            }
            .card-item { padding: 5px 0; border-bottom: 1px dotted #eee; }
            .card-label { font-weight: bold; color: #555; display: inline-block; width: 35%; }
            .card-value { display: inline-block; width: 60%; text-align: right; }
        }
    </style>
</head>
<body>
    <div class="container">
        <a href="index.php" class="back-btn">← Record ဖန်တီးရန် စာမျက်နှာသို့</a>
        <h2>📊 လက်ရှိ DNS Record များစာရင်း (<?php echo htmlspecialchars($domain); ?>)</h2>
        
        <?php if ($result['error']): ?>
            <div class='error-box'>❌ ERROR: Record စာရင်းရယူရာတွင် မအောင်မြင်ပါ။ <?php echo htmlspecialchars($result['message']); ?></div>
        <?php elseif (empty($filtered_records)): ?>
            <div class='info-box'>ℹ️ လက်ရှိတွင် A, CNAME, NS Record များ မရှိသေးပါ သို့မဟုတ် Domain Root Record များသာ ရှိပါသည်။</div>
        <?php else: ?>
            
            <table class="record-table">
                <thead>
                    <tr>
                        <th style="width: 10%;">Type</th>
                        <th style="width: 30%;">Subdomain</th>
                        <th style="width: 40%;">Content (Value)</th>
                        <th style="width: 10%;">Proxy</th>
                        <th style="width: 10%;">Action</th>
                    </tr>
                </thead>
                <tbody>
                    <?php foreach ($filtered_records as $record): 
                        $subdomain_only = str_replace("." . $domain, "", $record['name']);
                        $proxy_status = isset($record['proxied']) 
                            ? ($record['proxied'] ? "<span class='proxy-on'>Proxied (On)</span>" : "<span class='proxy-off'>DNS Only (Off)</span>")
                            : "N/A"; // NS Records will be N/A
                        
                        $type_class = 'type-' . $record['type'];
                    ?>
                        <tr>
                            <td><span class="type-badge <?php echo $type_class; ?>"><?php echo htmlspecialchars($record['type']); ?></span></td>
                            <td><?php echo htmlspecialchars($subdomain_only); ?></td>
                            <td><?php echo htmlspecialchars($record['content']); ?></td>
                            <td><?php echo $proxy_status; ?></td>
                            <td>
                                <form action='process.php?action=delete' method='POST' style='margin: 0;' onsubmit="return confirm('<?php echo htmlspecialchars($record['name']); ?> (<?php echo htmlspecialchars($record['type']); ?>) ကို ဖျက်တော့မှာ သေချာပါသလား?');">
                                    <input type='hidden' name='record_id' value='<?php echo htmlspecialchars($record['id']); ?>'>
                                    <input type='hidden' name='record_name' value='<?php echo htmlspecialchars($record['name']); ?>'>
                                    <input type='hidden' name='record_type' value='<?php echo htmlspecialchars($record['type']); ?>'>
                                    <button type='submit' class='delete-btn'>🗑️ ဖျက်မည်</button>
                                </form>
                            </td>
                        </tr>
                    <?php endforeach; ?>
                </tbody>
            </table>
            
            <div class="record-card-list">
                <?php foreach ($filtered_records as $record): 
                    $subdomain_only = str_replace("." . $domain, "", $record['name']);
                    $proxy_status = isset($record['proxied']) 
                        ? ($record['proxied'] ? "<span class='proxy-on'>Proxied (On)</span>" : "<span class='proxy-off'>DNS Only (Off)</span>")
                        : "N/A";
                    $type_class = 'type-' . $record['type'];
                ?>
                    <div class="record-card">
                        <div class="card-item"><span class="card-label">Type:</span> <span class="card-value"><span class="type-badge <?php echo $type_class; ?>"><?php echo htmlspecialchars($record['type']); ?></span></span></div>
                        <div class="card-item"><span class="card-label">Subdomain:</span> <span class="card-value"><?php echo htmlspecialchars($subdomain_only); ?></span></div>
                        <div class="card-item"><span class="card-label">Content:</span> <span class="card-value"><?php echo htmlspecialchars($record['content']); ?></span></div>
                        <div class="card-item"><span class="card-label">Proxy Status:</span> <span class="card-value"><?php echo $proxy_status; ?></span></div>
                        <div style="margin-top: 10px; text-align: center;">
                            <form action='process.php?action=delete' method='POST' style='margin: 0;' onsubmit="return confirm('<?php echo htmlspecialchars($record['name']); ?> (<?php echo htmlspecialchars($record['type']); ?>) ကို ဖျက်တော့မှာ သေချာပါသလား?');">
                                <input type='hidden' name='record_id' value='<?php echo htmlspecialchars($record['id']); ?>'>
                                <input type='hidden' name='record_name' value='<?php echo htmlspecialchars($record['name']); ?>'>
                                <input type='hidden' name='record_type' value='<?php echo htmlspecialchars($record['type']); ?>'>
                                <button type='submit' class='delete-btn'>🗑️ ဖျက်မည်</button>
                            </form>
                        </div>
                    </div>
                <?php endforeach; ?>
            </div>

        <?php endif; ?>
    </div>
</body>
</html>
