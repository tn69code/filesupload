// functions/upload.js
const fetch = require('node-fetch');

// 🛑 Variable Name ကို MY_GITHUB_TOKEN အဖြစ် ပြောင်းလဲထားသည်။
// (Netlify ရဲ့ GITHUB_TOKEN conflict ကို ရှောင်ရှားရန်နှင့် Scope အခက်အခဲကို ဖြေရှင်းရန်)
const GITHUB_TOKEN = process.env.MY_GITHUB_TOKEN; 

// 🛑 သင့် Repository အချက်အလက်များကို ဤနေရာတွင် ပြင်ဆင်ပါ။
const REPO_OWNER = "tn69code";
const REPO_NAME = "filesupload";
const BRANCH_NAME = "main"; 
const COUNTER_FILE_PATH = "upload_count.json";

// SHA ကို ရယူသည် (Token လိုအပ်သည်)
async function getFileSha(path) {
    const apiUrl = `https://api.github.com/repos/${REPO_OWNER}/${REPO_NAME}/contents/${path}?ref=${BRANCH_NAME}`;
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
    
    // Error တက်တဲ့အခါ JSON ပြန်မလာရင်တောင် Message ပါအောင် ကိုင်တွယ်သည်
    let errorData = {};
    try { errorData = await response.json(); } catch (e) { errorData.message = response.statusText; }
    
    throw new Error(`SHA Fetch Failed: ${response.status} - ${errorData.message || response.statusText}`);
}

// ဖိုင်ကို GitHub သို့ Upload/Update လုပ်သည် (Token လိုအပ်သည်)
async function uploadToGitHub(path, content, message, existingSha) {
    const apiUrl = `https://api.github.com/repos/${REPO_OWNER}/${REPO_NAME}/contents/${path}`;
    const data = { message: message, content: content, sha: existingSha, branch: BRANCH_NAME };
    if (existingSha === null) delete data.sha;

    const response = await fetch(apiUrl, {
        method: 'PUT',
        headers: { 'Authorization': `token ${GITHUB_TOKEN}`, 'Accept': 'application/vnd.github.v3+json', 'Content-Type': 'application/json' },
        body: JSON.stringify(data)
    });

    if (response.status === 201 || response.status === 200) { return await response.json(); } 
    
    let errorData = {};
    try { errorData = await response.json(); } catch (e) { errorData.message = response.statusText; }
    
    throw new Error(`Upload Failed: ${response.status} - ${errorData.message || response.statusText}`);
}

// Counter ကို တိုးမြှင့်သည် (Token လိုအပ်သည်)
async function incrementCounter() {
    const apiUrl = `https://api.github.com/repos/${REPO_OWNER}/${REPO_NAME}/contents/${COUNTER_FILE_PATH}`;
    const sha = await getFileSha(COUNTER_FILE_PATH); 
    let currentCount = 0;
    
    if (sha) {
        const getResponse = await fetch(apiUrl, { method: 'GET', headers: { 'Authorization': `token ${GITHUB_TOKEN}`, 'Accept': 'application/vnd.github.v3+json' } });
        const data = await getResponse.json();
        currentCount = JSON.parse(Buffer.from(data.content, 'base64').toString()).count || 0;
    }
    
    const newCount = currentCount + 1;
    const newContentString = JSON.stringify({ count: newCount }, null, 2); 
    const newBase64Content = Buffer.from(newContentString).toString('base64');
    
    await uploadToGitHub(COUNTER_FILE_PATH, newBase64Content, `Auto-increment counter to ${newCount}`, sha);
    return newCount;
}


exports.handler = async (event) => {
    if (event.httpMethod !== 'POST') { return { statusCode: 405, body: 'Method Not Allowed' }; }
    
    // 🛑 Token ကို GITHUB_TOKEN အစား MY_GITHUB_TOKEN အဖြစ် စစ်ဆေးသည်။
    if (!GITHUB_TOKEN) { return { statusCode: 500, body: JSON.stringify({ error: 'Missing MY_GITHUB_TOKEN environment variable. Check Netlify Environment Settings.' }) }; }

    try {
        const body = JSON.parse(event.body);
        const { path, content, fileName } = body; 

        // 1. File Upload/Update အတွက် SHA ကို စစ်ဆေးခြင်း
        const existingSha = await getFileSha(path); 
        const action = existingSha ? "Update" : "Create";
        const commitMessage = `${action}: ${fileName} (${new Date().toLocaleTimeString()})`;
        
        const uploadResult = await uploadToGitHub(path, content, commitMessage, existingSha);

        // 2. Counter Update
        const newCount = await incrementCounter();

        return {
            statusCode: 200,
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                path: uploadResult.content.path,
                newCount: newCount 
            })
        };

    } catch (error) {
        // 🛑 Client (index.html) ဆီကို JSON Error ပြန်ပို့ရန်
        console.error("Function Error:", error);
        return { 
            statusCode: 500, 
            headers: { 'Content-Type': 'application/json' }, 
            body: JSON.stringify({ error: error.message || 'Unknown server error' }) 
        };
    }
};
