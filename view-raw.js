// functions/view-raw.js
const fetch = require('node-fetch');

// 🛑 သင့် Repository အချက်အလက်များကို ဤနေရာတွင် ပြင်ဆင်ပါ။
const REPO_OWNER = "tn69code";
const REPO_NAME = "filesupload";
const BRANCH_NAME = "main"; 
    
exports.handler = async (event, context) => {
    const { path } = event.queryStringParameters;

    if (!path) {
        return { statusCode: 400, body: 'Missing path parameter.' };
    }

    // Raw GitHub URL ကို တည်ဆောက်သည်
    const rawGitHubUrl = `https://raw.githubusercontent.com/${REPO_OWNER}/${REPO_NAME}/${BRANCH_NAME}/${path}`;

    try {
        const response = await fetch(rawGitHubUrl);

        if (response.status !== 200) {
            return { statusCode: response.status, body: `Error fetching content from GitHub: ${response.statusText}` };
        }

        // Content ကို Text အနေနဲ့ ဖတ်ပြီး၊ MIME Type ကို Force ပြောင်းသည်
        const contentText = await response.text();

        return {
            statusCode: 200,
            headers: {
                // Browser က Download မလုပ်ဘဲ Text အနေဖြင့် ပြသရန်
                'Content-Type': 'text/plain; charset=utf-8', 
                'Access-Control-Allow-Origin': '*',
            },
            body: contentText,
        };

    } catch (error) {
        console.error('Proxy Fetch Error:', error);
        return { statusCode: 500, body: 'Internal Server Error during fetch.' };
    }
};
