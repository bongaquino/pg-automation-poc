# Acme Golf Co — AI Automation POC

AI-powered customer support automation proof-of-concept built as a portfolio demonstration of AI-powered support automation for an online golf instruction company.


---

## Overview

This repository contains a working automation pipeline that classifies incoming customer support tickets and drafts category-specific responses tailored to Acme Golf Co's products, policies, and tone.

```
Customer ticket → Webhook → Parse → Shopify Lookup → AI Classify → Route → AI Draft → Agent Review
```

The POC runs on **n8n** (self-hosted, Docker Compose) and demonstrates the full workflow architecture. AI responses are mocked for the demo; in production, two nodes swap to Claude API calls with pre-written prompts.

## Architecture

```
┌─────────────────┐
│  Incoming Ticket │  ← Webhook (Intercom, email, web form)
│  (n8n Webhook)   │
└────────┬────────┘
         ▼
┌─────────────────┐
│  Parse Ticket    │  ← Normalize payload format
└────────┬────────┘
         ▼
┌─────────────────┐
│  Shopify Lookup  │  ← Customer order history, spend, tags
└────────┬────────┘
         ▼
┌─────────────────┐
│  Classify Ticket │  ← AI: category, urgency, product, summary
│  (Claude API)    │
└────────┬────────┘
         ▼
┌─────────────────┐
│  Route by        │  ← Switch on category
│  Category        │
└────────┬────────┘
         ▼
┌─────────────────┐
│  Draft Response  │  ← AI: category-specific prompt template
│  (Claude API)    │
└────────┬────────┘
         ▼
┌─────────────────┐
│  Output          │  ← Internal note + classification metadata
│  (Agent Review)  │     Human-in-the-loop before sending
└─────────────────┘
```

## Ticket Categories

| Category | Trigger Keywords | Urgency | Response Focus |
|----------|-----------------|---------|----------------|
| `refund` | return, refund, money back | Medium | 365-day return policy, prepaid label, coach consultation offer |
| `shipping` | broken, damaged, crushed | High | Immediate replacement, no return-first required, priority processing |
| `billing_dispute` | charge, subscription, unauthorized | High | Immediate refund, cancel subscription, transparent explanation |
| `vip_coaching` | VIP, golf school | Low | Locations, 2.5-day format, connect with VIP team |
| `product_question` | (default) | Low | Product recommendations based on handicap, relevant courses |
| `technical_support` | app, crash, white screen | Medium | Troubleshooting steps, device-specific guidance |

## Repository Structure

```
pg-automation-poc/
├── README.md                          # This file
├── workflows/
│   ├── pg-support-poc-demo.json       # n8n workflow (mock AI, no API key needed)
│   └── pg-support-full-workflow.json  # n8n workflow (Claude API, production-ready)
├── scripts/
│   └── test-demo.sh                   # 6 test tickets covering all categories
├── prompts/
│   ├── classify-ticket.md             # Claude system prompt for classification
│   └── draft-response.md             # Claude system prompts for each category
├── docs/
│   ├── setup-guide.md                 # Step-by-step setup instructions
│   ├── automation-opportunities.md    # Business analysis of PG automation targets
│   └── cost-estimate.md               # API cost projections
└── .env.example                       # Environment variables template
```

## Quick Start

### Prerequisites

- n8n running on Docker Compose (tested on v2.10.4)
- No API keys required for the demo workflow

### Setup

```bash
# 1. Clone this repo
git clone https://github.com/YOUR_USERNAME/pg-automation-poc.git
cd pg-automation-poc

# 2. Import the workflow into n8n
#    Open n8n → Create workflow → Import from file
#    Select workflows/pg-support-poc-demo.json

# 3. Publish the workflow in n8n (top right button)

# 4. Run the tests
chmod +x scripts/test-demo.sh
./scripts/test-demo.sh all
```

### Sample Output

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
TEST: Shipping Damage — 357 Fairway Wood
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✓ Response (200)
Category: shipping
Urgency:  high
Summary:  Product damaged in shipping

─── AI Draft Response ───
Hi Sarah,

We're really sorry about this - receiving a damaged club is the last
thing we want, especially when it's a gift. That's on us.

Here's what we're doing:

1. Shipping a brand new 357 right away - no need to return the
   damaged one first
2. We'll email a prepaid return label for the damaged unit
3. Replacement arrives within 3-5 business days

I've flagged your order (PG-30455) for priority processing.
You'll get tracking info as soon as it ships.

The Acme Golf Co Team
```

## Key Code Snippets

### Ticket Classification (Claude API)

The classifier prompt returns structured JSON for downstream routing:

```javascript
// System prompt for Claude classification
const systemPrompt = `You are a support ticket classifier for Acme Golf Co.
Classify the customer's message into exactly one category and extract key details.

Categories:
- refund: Customer wants money back or to return a product
- shipping: Delivery issues, tracking, damaged in transit
- product_question: Questions about clubs, training aids, courses
- billing_dispute: Unauthorized charges, subscription confusion
- vip_coaching: VIP Golf School inquiries, coaching programs
- technical_support: App issues, login problems, video playback

Return ONLY valid JSON:
{
  "category": "one of the categories above",
  "urgency": "low|medium|high",
  "product_mentioned": "product name or null",
  "order_id": "order number if mentioned or null",
  "summary": "one-line summary of the issue"
}`;

// Claude API call
const response = await fetch("https://api.anthropic.com/v1/messages", {
  method: "POST",
  headers: {
    "x-api-key": process.env.ANTHROPIC_API_KEY,
    "anthropic-version": "2023-06-01",
    "content-type": "application/json"
  },
  body: JSON.stringify({
    model: "claude-sonnet-4-20250514",
    max_tokens: 512,
    system: systemPrompt,
    messages: [{
      role: "user",
      content: `Classify this ticket:\n\nCustomer: ${name} (${email})\nHistory: ${orders} orders, ${spent} total\n\nMessage:\n${message}`
    }]
  })
});
```

### Category-Specific Draft Prompts

Each category gets a tailored system prompt with Acme Golf Co product knowledge:

```javascript
const prompts = {
  refund: `You are a friendly support agent for Acme Golf Co.
Draft a response to this refund/return request.

Rules:
- Reference their specific product if mentioned
- Mention Acme Golf Co's 365-day return policy
- Provide clear next steps (how to initiate the return)
- If damaged item, express empathy and offer replacement first
- Warm, human tone — fellow golf enthusiast helping out
- Keep under 150 words
- Sign off as "The Acme Golf Co Team"`,

  shipping: `You are a friendly support agent for Acme Golf Co.
Draft a response to this shipping inquiry.

Rules:
- Acknowledge the shipping concern
- If damaged in transit, offer immediate replacement
- No need to return damaged item first
- Provide estimated timeline and tracking next steps
- Keep under 150 words
- Sign off as "The Acme Golf Co Team"`,

  billing_dispute: `You are a friendly support agent for Acme Golf Co.
Draft a response to this billing concern.

Rules:
- Take the concern seriously
- If VIP Coaching auto-subscription, explain clearly how to cancel
- Offer to process refund immediately if unauthorized
- Never be defensive about billing practices
- Keep under 150 words
- Sign off as "The Acme Golf Co Team"`,

  // ... additional categories in prompts/draft-response.md
};
```

### Webhook + Shopify Integration

```javascript
// n8n Code node: Shopify customer lookup
const response = await fetch(
  `https://${SHOPIFY_STORE}.myshopify.com/admin/api/2024-01/customers/search.json?query=email:${customerEmail}`,
  {
    headers: { "X-Shopify-Access-Token": SHOPIFY_TOKEN }
  }
);

const data = await response.json();
const customer = data.customers[0];

return {
  found: true,
  orders_count: customer.orders_count,
  total_spent: customer.total_spent,
  tags: customer.tags,
  last_order: customer.orders[0]?.name
};
```

## Production Deployment

To move from POC to production:

| Step | What Changes | Effort |
|------|-------------|--------|
| 1. Add Claude API key | Swap mock classifier → Claude API call | 10 min |
| 2. Connect Shopify | Replace mock lookup → live Shopify Admin API | 30 min |
| 3. Connect Intercom | Replace webhook trigger → Intercom webhook subscription | 30 min |
| 4. Add Google Sheets logging | Append execution data for reporting | 15 min |
| 5. Post draft to Intercom | Add API call to create internal note on conversation | 30 min |

### Cost Estimate

Per ticket (2 Claude API calls):
- Classification: ~300 input + ~100 output tokens ≈ $0.002
- Draft: ~400 input + ~200 output tokens ≈ $0.003
- **Total: ~$0.005 per ticket** (half a cent)

| Volume | Daily Cost | Monthly Cost |
|--------|-----------|-------------|
| 20 tickets/day | $0.10 | $3.00 |
| 50 tickets/day | $0.25 | $7.50 |
| 100 tickets/day | $0.50 | $15.00 |

## Automation Opportunities Identified

Beyond support auto-drafting, the following high-impact automations were identified for Acme Golf Co:

1. **Email Content Generation** — Mine 15+ video masterclasses for daily newsletter content (tips, drills, product tie-ins)
2. **Product Launch Pipeline** — New product/course → auto-generate all marketing collateral (email, social, ads, product page copy)
3. **PG1 App Onboarding** — Assessment root flaw → personalized 7-day email sequence with matched courses and training aids
4. **Review & Testimonial Mining** — Extract quotable customer success stories, categorized by product and improvement type
5. **Lead Scoring & VIP Routing** — Score leads by behavior, route high-value prospects to VIP Golf School sales
6. **Shopify ↔ Members Portal Cross-sell** — Purchase + course completion triggers smart product recommendations

See [docs/automation-opportunities.md](docs/automation-opportunities.md) for full analysis.

## Tech Stack

| Component | Technology |
|-----------|-----------|
| Automation platform | n8n (self-hosted, Docker Compose) |
| AI engine | Claude API (Anthropic) |
| E-commerce | Shopify Admin API |
| Customer messaging | Intercom API |
| Marketing automation | Mautic API |
| Logging | Google Sheets API |
| Infrastructure | Docker, UTM VM, macOS |

## About

The POC demonstrates end-to-end automation pipeline design, Claude AI prompt engineering, and business process analysis.


---

*This repository is a portfolio piece demonstrating AI-powered customer support automation capabilities.*
