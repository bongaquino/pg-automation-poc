# Setup Guide

## Prerequisites

- Docker and Docker Compose installed
- n8n running on Docker (tested on v2.10.4, community edition)
- macOS or Linux terminal for running test scripts

## Step 1: Start n8n

```bash
docker compose up -d
```

## Step 2: Import the Workflow

1. Open n8n in your browser (`http://localhost:5678` or your VM IP)
2. Click **Create workflow** → **Import from file**
3. Select `workflows/support-poc-demo.json`
4. You should see 5 nodes connected in sequence

## Step 3: Publish the Workflow

1. Click **Publish** (top right)
2. The green dot confirms the webhook is active

## Step 4: Run Tests

```bash
chmod +x scripts/test-demo.sh
export PG_WEBHOOK_URL=http://YOUR_N8N_IP:5678/webhook/pg-support-ticket
./scripts/test-demo.sh all
```

## Step 5: Verify in n8n

1. Click the **Executions** tab
2. Each test shows as a completed execution
3. Click any execution to see data flowing through each node

## Upgrading to Production (Claude API)

1. Get an API key from [console.anthropic.com](https://console.anthropic.com)
2. Swap the keyword classifier node with an HTTP Request node calling Claude API
3. Swap the template drafter node with a second Claude API call
4. Prompts are pre-written in `prompts/classify-ticket.md` and `prompts/draft-response.md`
