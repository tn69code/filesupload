// functions/upload.js ကို ပြင်ဆင်ရန်

// ... (ယခင် Code များ) ...

// SHA ကို ရယူသည် (Token လိုအပ်သည်)
async function getFileSha(path) {
    // ဤနေရာတွင် Error Handling ကို ပိုမို တင်းကျပ်စွာ ထားရှိသည်
    const apiUrl = `https://api.github.com/repos/${REPO_OWNER}/${REPO_NAME}/contents/${path}?ref=${BRANCH_NAME}`;
    
    // Authorization Header ကို မဖြစ်မနေ ထည့်ရမည်
    const response = await fetch(apiUrl, {
        method: 'GET',
        headers: { 'Authorization': `token ${GITHUB_TOKEN}`, 'Accept': 'application/vnd.github.v3+json' }
    });

    if (response.status === 200) { 
        return (await response.json()).sha; 
    } 
    if (response.status === 404) { 
        return null; // ဖိုင်မရှိရင် null ပြန်ပို့ပါ
    }
    
    // 403 (Permission) သို့မဟုတ် အခြား Error များ တက်လာရင် Error ကို ပြန်ပစ်ပါ
    const errorData = await response.json();
    throw new Error(`SHA Fetch Failed: ${response.status} - ${errorData.message || response.statusText}`);
}

// ... (ကျန်သော Code များ) ...

exports.handler = async (event) => {
    // ... (ယခင် Code များ) ...
    
    try {
        // ... (body parsing) ...
        const { path, content, fileName } = body; 

        // 1. File Upload/Update အတွက် SHA ကို စစ်ဆေးခြင်း
        // 🛑 အကယ်၍ Token မှန်ရင် ဒီနေရာကနေ SHA ကို ရမှာပါ။ Token မှားရင် ဒီနေရာကနေ Error တက်ပြီး Client ဆီ ပြန်ရောက်ပါမယ်။
        const existingSha = await getFileSha(path); 
        
        // ... (ကျန်သော Logic များ) ...
        
    } catch (error) {
        // 🛑 Netlify Function ကနေ Client (index.html) ဆီကို JSON Error ပြန်ပို့ရန်
        return { 
            statusCode: 500, 
            headers: { 'Content-Type': 'application/json' }, // JSON Error အဖြစ် ပြန်ပို့သည်
            body: JSON.stringify({ error: error.message || 'Unknown server error' }) 
        };
    }
};
