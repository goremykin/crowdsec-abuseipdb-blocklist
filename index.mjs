import { readFile, writeFile, rm } from 'fs/promises';
import { fileURLToPath } from 'url';
import { exec } from 'child_process';
import { promisify } from 'util';
import path from 'path';

const __current_filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__current_filename);
const configPath = path.join(__dirname, 'config.json');

const configRaw = await readFile(configPath, { encoding: 'utf-8' });
const config = JSON.parse(configRaw);
const apiKey = config.apiKey;
const confidenceMinimum = config.confidenceMinimum ?? '75';
const banDuration = config.banDuration ?? '24h';

if (!apiKey) {
	throw new Error('API key missing in config.json');
}

const url = new URL('https://api.abuseipdb.com/api/v2/blacklist');
url.searchParams.set('confidenceMinimum', confidenceMinimum);

const response = await fetch(url, {
	method: 'GET',
	headers: {
		Key: apiKey,
		Accept: 'application/json'
	}
});

if (!response.ok) {
	throw new Error(`Fetch failed: ${response.status} ${response.statusText}`);
}

const responseData = await response.json();
const crowdsecDecisions = responseData.data
	.map(({ ipAddress }) => ({
		duration: banDuration,
		reason: 'abuseipdb',
		scope: 'ip',
		type: 'ban',
		value: ipAddress,
	}));
const crowdsecDecisionsJson = JSON.stringify(crowdsecDecisions);
const crowdsecDecisionsPath = path.join(__dirname, 'decisions.json');
await writeFile(crowdsecDecisionsPath, crowdsecDecisionsJson, { encoding: 'utf-8' });

const execAsync = promisify(exec);
const { stdout, stderr } = await execAsync(`cscli decisions import -i "${crowdsecDecisionsPath}"`);

console.log('Command output:\n', stdout);

if (stderr) {
	console.error('Command stderr:\n', stderr);
}

await rm(crowdsecDecisionsPath);