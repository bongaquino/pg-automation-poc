# Cost Estimate — Claude API for Support Automation

## Per-Ticket Cost

Each ticket requires two Claude API calls:

| Call | Input Tokens | Output Tokens | Cost |
|------|-------------|---------------|------|
| Classification | ~300 | ~100 | ~$0.002 |
| Draft Response | ~400 | ~200 | ~$0.003 |
| **Total per ticket** | | | **~$0.005** |

## Monthly Projections

| Daily Volume | Daily Cost | Monthly Cost | Annual Cost |
|-------------|-----------|-------------|------------|
| 20 tickets | $0.10 | $3.00 | $36 |
| 50 tickets | $0.25 | $7.50 | $90 |
| 100 tickets | $0.50 | $15.00 | $180 |
| 200 tickets | $1.00 | $30.00 | $360 |

## ROI Calculation

Assuming 50 tickets/day, average handling time reduction from 10 min to 3 min:

- **Time saved per ticket:** 7 minutes
- **Time saved per day:** 350 minutes (~5.8 hours)
- **Time saved per month:** ~175 hours
- **API cost per month:** $7.50

Even at a conservative $10/hr agent rate, monthly savings are $1,750 against $7.50 in API costs.

## Notes

- Costs based on Claude Sonnet pricing
- No cost for n8n (self-hosted, open source)
- Shopify API, Google Sheets API, and Intercom webhooks are free within standard rate limits
