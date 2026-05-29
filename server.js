'use strict';

const express = require('express');
const fs = require('fs');
const path = require('path');
const { randomUUID } = require('crypto');
const { exec } = require('child_process');

const app = express();
const PORT = 3000;

const WORKSPACE = '/home/coder/workspace';
const INSTRUCTIONS_FILE = path.join(WORKSPACE, 'windsurf-instructions.txt');
const OUTPUT_FILE = path.join(WORKSPACE, 'windsurf-output.txt');
const WORK_COMPLETED_MARKER = 'WORK-COMPLETED';
const POLL_INTERVAL_MS = 2000;
const TIMEOUT_MS = 5 * 60 * 1000; // 5 minutes

app.use(express.json());

function log(msg) {
  console.log(`[${new Date().toISOString()}] ${msg}`);
}

app.use((req, res, next) => {
  log(`${req.method} ${req.path}`);
  next();
});

// ── GET / — mobile UI ──────────────────────────────────────────────────────
app.get('/', (req, res) => {
  res.setHeader('Content-Type', 'text/html; charset=utf-8');
  res.send(`<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0">
  <title>Vibe-OS</title>
  <style>
    *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }
    body {
      background: #1a1a1a;
      color: #e8e8e8;
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
      font-size: 16px;
      min-height: 100vh;
      padding: 16px;
      display: flex;
      flex-direction: column;
      gap: 16px;
    }
    h1 {
      font-size: 28px;
      font-weight: 700;
      color: #7c3aed;
      text-align: center;
      letter-spacing: -0.5px;
      padding-top: 8px;
    }
    h1 span { color: #a78bfa; font-size: 14px; font-weight: 400; display: block; margin-top: 2px; }
    textarea {
      width: 100%;
      min-height: 120px;
      background: #262626;
      color: #e8e8e8;
      border: 1px solid #3f3f46;
      border-radius: 10px;
      padding: 12px 14px;
      font-size: 16px;
      font-family: inherit;
      resize: vertical;
      outline: none;
      transition: border-color 0.2s;
    }
    textarea:focus { border-color: #7c3aed; }
    button {
      width: 100%;
      min-height: 52px;
      background: #7c3aed;
      color: #fff;
      border: none;
      border-radius: 10px;
      font-size: 18px;
      font-weight: 600;
      cursor: pointer;
      transition: background 0.2s, transform 0.1s;
      -webkit-tap-highlight-color: transparent;
    }
    button:active { transform: scale(0.98); }
    button:disabled { background: #4c1d95; color: #a78bfa; cursor: not-allowed; }
    #status {
      font-size: 14px;
      text-align: center;
      color: #a1a1aa;
      min-height: 20px;
    }
    #status.thinking { color: #a78bfa; }
    #status.done { color: #4ade80; }
    #status.error { color: #f87171; }
    .dots::after {
      content: '';
      animation: dots 1.4s infinite;
    }
    @keyframes dots {
      0%   { content: '.'; }
      33%  { content: '..'; }
      66%  { content: '...'; }
      100% { content: ''; }
    }
    #output-wrap {
      flex: 1;
      display: flex;
      flex-direction: column;
      gap: 6px;
    }
    #output-label {
      font-size: 12px;
      color: #71717a;
      text-transform: uppercase;
      letter-spacing: 0.5px;
    }
    #output {
      background: #111;
      border: 1px solid #27272a;
      border-radius: 10px;
      padding: 14px;
      font-family: 'SFMono-Regular', Consolas, 'Liberation Mono', Menlo, monospace;
      font-size: 13px;
      line-height: 1.6;
      white-space: pre-wrap;
      word-break: break-word;
      color: #d4d4d8;
      min-height: 120px;
      max-height: 50vh;
      overflow-y: auto;
    }
  </style>
</head>
<body>
  <h1>Vibe-OS<span>Cascade Agent Interface</span></h1>

  <textarea id="prompt" placeholder="Enter your prompt for Cascade…" rows="5"></textarea>

  <button id="send-btn" onclick="sendPrompt()">Send to Cascade</button>

  <div id="status">Ready</div>

  <div id="output-wrap">
    <div id="output-label">Output</div>
    <div id="output"></div>
  </div>

  <script>
    let pollTimer = null;

    function setStatus(text, cls) {
      const el = document.getElementById('status');
      el.textContent = text;
      el.className = cls || '';
      if (cls === 'thinking') {
        el.classList.add('dots');
      }
    }

    function setOutput(text) {
      const el = document.getElementById('output');
      el.textContent = text;
      el.scrollTop = el.scrollHeight;
    }

    function stopPolling() {
      if (pollTimer) { clearInterval(pollTimer); pollTimer = null; }
    }

    function startPolling() {
      stopPolling();
      pollTimer = setInterval(async () => {
        try {
          const res = await fetch('/output');
          const text = await res.text();
          setOutput(text);
          if (text.includes('WORK-COMPLETED')) {
            stopPolling();
            document.getElementById('send-btn').disabled = false;
            setStatus('Done', 'done');
          }
        } catch (e) {
          // keep polling
        }
      }, 2000);
    }

    async function sendPrompt() {
      const prompt = document.getElementById('prompt').value.trim();
      if (!prompt) { setStatus('Please enter a prompt.', 'error'); return; }

      stopPolling();
      setOutput('');
      setStatus('Thinking', 'thinking');
      document.getElementById('send-btn').disabled = true;

      try {
        const res = await fetch('/cascade', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ prompt })
        });
        if (!res.ok) { throw new Error('Server error ' + res.status); }
        startPolling();
        // The POST will resolve when Cascade finishes; update output once more
        const data = await res.json();
        stopPolling();
        setOutput(data.response || '');
        setStatus('Done', 'done');
        document.getElementById('send-btn').disabled = false;
      } catch (e) {
        stopPolling();
        setStatus('Error: ' + e.message, 'error');
        document.getElementById('send-btn').disabled = false;
      }
    }

    // Allow Ctrl+Enter / Cmd+Enter to submit
    document.getElementById('prompt').addEventListener('keydown', (e) => {
      if ((e.ctrlKey || e.metaKey) && e.key === 'Enter') sendPrompt();
    });
  </script>
</body>
</html>`);
});

// ── GET /status ────────────────────────────────────────────────────────────
app.get('/status', (req, res) => {
  res.json({ status: 'ok' });
});

// ── GET /output — live polling endpoint ───────────────────────────────────
app.get('/output', (req, res) => {
  try {
    const content = fs.existsSync(OUTPUT_FILE)
      ? fs.readFileSync(OUTPUT_FILE, 'utf8')
      : '';
    res.setHeader('Content-Type', 'text/plain; charset=utf-8');
    res.send(content);
  } catch (err) {
    res.status(500).send('');
  }
});

// ── Trigger Cascade workflow via xdotool ──────────────────────────────────
function triggerCascadeWorkflow() {
  return new Promise((resolve) => {
    const cmds = [
      // Open Cascade panel
      `DISPLAY=:1 xdotool key ctrl+l`,
      // Wait then type workflow name
      `sleep 1 && DISPLAY=:1 xdotool type --clearmodifiers '/entry-workflow'`,
      // Submit
      `sleep 0.5 && DISPLAY=:1 xdotool key Return`
    ];
    let i = 0;
    function next() {
      if (i >= cmds.length) return resolve();
      exec(cmds[i++], (err) => {
        if (err) log(`xdotool warn: ${err.message}`);
        setTimeout(next, 600);
      });
    }
    next();
  });
}

// ── POST /cascade — accept prompt, drive Cascade, return response ──────────
app.post('/cascade', async (req, res) => {
  const { prompt } = req.body || {};
  if (!prompt || typeof prompt !== 'string' || !prompt.trim()) {
    return res.status(400).json({ error: 'prompt is required' });
  }

  const id = randomUUID();
  log(`cascade request id=${id} prompt="${prompt.slice(0, 80)}…"`);

  try {
    // Ensure workspace directory exists
    fs.mkdirSync(WORKSPACE, { recursive: true });

    // Write instructions for Cascade
    fs.writeFileSync(INSTRUCTIONS_FILE, prompt.trim(), 'utf8');

    // Clear previous output so we know when a fresh response arrives
    fs.writeFileSync(OUTPUT_FILE, '', 'utf8');

    // Trigger Cascade workflow via xdotool
    log(`cascade id=${id} triggering workflow via xdotool…`);
    await triggerCascadeWorkflow();
    log(`cascade id=${id} workflow triggered, polling for completion…`);

    // Poll for WORK-COMPLETED marker
    const deadline = Date.now() + TIMEOUT_MS;
    let response = '';

    await new Promise((resolve, reject) => {
      const check = () => {
        if (Date.now() > deadline) {
          return reject(new Error('Cascade timed out after 5 minutes'));
        }
        try {
          if (fs.existsSync(OUTPUT_FILE)) {
            const contents = fs.readFileSync(OUTPUT_FILE, 'utf8');
            if (contents.includes(WORK_COMPLETED_MARKER)) {
              response = contents;
              return resolve();
            }
          }
        } catch (_) {
          // file not ready yet — keep polling
        }
        setTimeout(check, POLL_INTERVAL_MS);
      };
      setTimeout(check, POLL_INTERVAL_MS);
    });

    log(`cascade id=${id} completed, response length=${response.length}`);
    res.json({ response, status: 'complete' });
  } catch (err) {
    log(`cascade id=${id} error: ${err.message}`);
    res.status(500).json({ error: err.message, status: 'error' });
  }
});

// ── Start ──────────────────────────────────────────────────────────────────
app.listen(PORT, '0.0.0.0', () => {
  log(`Vibe-OS server listening on port ${PORT}`);
});
