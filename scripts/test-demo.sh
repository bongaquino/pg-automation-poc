#!/bin/bash
# Support Auto-Draft POC — Test Script
# Sends fake support tickets to the n8n workflow via webhook.

WEBHOOK_URL="${PG_WEBHOOK_URL:-http://192.168.14.11:5678/webhook/pg-support-ticket}"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

send_ticket() {
  local name="$1"
  local payload="$2"
  echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${YELLOW}TEST: ${name}${NC}"
  echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

  response=$(curl -s -w "\n---HTTP_CODE:%{http_code}" -X POST "$WEBHOOK_URL" \
    -H "Content-Type: application/json" \
    -d "$payload" 2>&1)

  http_code=$(echo "$response" | grep -o 'HTTP_CODE:[0-9]*' | cut -d: -f2)
  body=$(echo "$response" | sed '/---HTTP_CODE:/d')

  if [ -z "$http_code" ]; then
    echo -e "${RED}✗ Connection failed — is n8n running at $WEBHOOK_URL?${NC}"
    return 1
  fi

  if [ "$http_code" -ge 200 ] 2>/dev/null && [ "$http_code" -lt 300 ] 2>/dev/null; then
    category=$(echo "$body" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('classification',{}).get('category','?'))" 2>/dev/null)
    urgency=$(echo "$body" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('classification',{}).get('urgency','?'))" 2>/dev/null)
    summary=$(echo "$body" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('classification',{}).get('summary','?'))" 2>/dev/null)
    draft=$(echo "$body" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('draft_response','?'))" 2>/dev/null)

    echo -e "${GREEN}✓ Response ($http_code)${NC}"
    echo -e "${CYAN}Category:${NC} $category"
    echo -e "${CYAN}Urgency:${NC}  $urgency"
    echo -e "${CYAN}Summary:${NC}  $summary"
    echo -e "\n${CYAN}─── AI Draft Response ───${NC}"
    echo "$draft"
  else
    echo -e "${RED}✗ Error ($http_code):${NC}"
    echo "$body"
  fi
}

test_1() {
  send_ticket "Refund Request — SF1 Driver" '{
    "customer_email": "mike.jones@example.com",
    "customer_name": "Mike Jones",
    "message": "Hi, I purchased the SF1 Driver about 3 weeks ago and I am not happy with it. The ball keeps going left no matter what I do. I would like to return it and get my money back. My order number is T-20241. Thanks.",
    "channel": "email"
  }'
}

test_2() {
  send_ticket "Shipping Damage — 357 Fairway Wood" '{
    "customer_email": "sarah.chen@example.com",
    "customer_name": "Sarah Chen",
    "message": "I just received my 357 fairway wood and the shaft is broken! It was clearly damaged during shipping. The box was crushed on one side. This was supposed to be a birthday gift for my husband and now I dont know what to do. Order T-30455.",
    "channel": "email"
  }'
}

test_3() {
  send_ticket "Billing Dispute — Auto-subscription" '{
    "customer_email": "robert.williams@example.com",
    "customer_name": "Robert Williams",
    "message": "I just noticed a charge of $47.99 on my credit card. I never signed up for any subscription or VIP coaching program. I only bought the Click Stick two months ago. Please refund this charge immediately and cancel whatever subscription you signed me up for without my consent.",
    "channel": "web"
  }'
}

test_4() {
  send_ticket "Product Question — Which Club" '{
    "customer_email": "tom.baker@example.com",
    "customer_name": "Tom Baker",
    "message": "Hey there, Im a 15 handicap and I really struggle with my long approach shots. I keep chunking my 5 iron and hybrid. Would the 357 or 359 be better for me? Also do you have any training courses that might help with my ball striking? Thanks!",
    "channel": "web"
  }'
}

test_5() {
  send_ticket "VIP Golf School Inquiry" '{
    "customer_email": "jennifer.park@example.com",
    "customer_name": "Jennifer Park",
    "message": "I have been using your courses for about a year now and I have improved a lot! I went from a 28 to a 19 handicap. I would love to attend one of your VIP Golf Schools. Are there any available in the Southeast US in the next couple months? What is the cost?",
    "channel": "email"
  }'
}

test_6() {
  send_ticket "Technical Support — App Crash" '{
    "customer_email": "dave.murphy@example.com",
    "customer_name": "Dave Murphy",
    "message": "The app keeps crashing on my iPhone when I try to view my assessment results. I completed the assessment yesterday but every time I tap on My Plan it just goes to a white screen and closes. Ive tried restarting my phone. Running iOS 17.4.",
    "channel": "web"
  }'
}

run_all() {
  echo -e "${YELLOW}Running all 6 test tickets against $WEBHOOK_URL${NC}"
  test_1; sleep 1; test_2; sleep 1; test_3; sleep 1
  test_4; sleep 1; test_5; sleep 1; test_6
  echo -e "\n${GREEN}━━━ All 6 tests complete ━━━${NC}"
  echo -e "Check n8n Executions tab for the full pipeline view."
}

case "${1:-menu}" in
  1) test_1 ;; 2) test_2 ;; 3) test_3 ;;
  4) test_4 ;; 5) test_5 ;; 6) test_6 ;;
  all) run_all ;;
  *)
    echo -e "${YELLOW}Support Auto-Draft — Test Suite${NC}"
    echo -e "Target: ${CYAN}$WEBHOOK_URL${NC}\n"
    echo "  1) Refund (SF1 Driver)"
    echo "  2) Shipping damage (357 Wood)"
    echo "  3) Billing dispute (auto-sub)"
    echo "  4) Product question (which club)"
    echo "  5) VIP Golf School inquiry"
    echo "  6) Tech support (app crash)"
    echo "  a) Run all 6"
    echo ""
    read -p "Pick: " c
    case $c in
      1) test_1 ;; 2) test_2 ;; 3) test_3 ;;
      4) test_4 ;; 5) test_5 ;; 6) test_6 ;;
      a|A) run_all ;; *) echo "Invalid" ;;
    esac
    ;;
esac
