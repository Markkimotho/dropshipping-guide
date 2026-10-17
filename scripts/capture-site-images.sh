#!/usr/bin/env bash
set -euo pipefail

repo_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
chrome='/Applications/Google Chrome.app/Contents/MacOS/Google Chrome'
if [[ ! -x "$chrome" ]]; then
  printf 'Chrome is required to refresh these screenshots: %s\n' "$chrome" >&2
  exit 1
fi

image_dir="$repo_dir/assets/images"
mkdir -p "$image_dir"
profile_dir=$(mktemp -d "${TMPDIR:-/tmp}/dropshipping-guide-capture.XXXXXX")
trap 'rm -rf "$profile_dir"' EXIT

# Each capture is a public page, not a logged-in dashboard or a claim of endorsement.
captures=(
  'llc-formation|https://sos.wyo.gov/Business/StartABusiness.aspx'
  'business-banking|https://www.consumerfinance.gov/consumer-tools/bank-accounts/'
  'shopify-admin|https://help.shopify.com/en/manual/shopify-admin/shopify-admin-overview'
  'theme-customization|https://themes.shopify.com/'
  'store-policies|https://help.shopify.com/en/manual/checkout-settings/refund-privacy-tos'
  'dropshipping-app|https://www.dsers.com/'
  'product-research|https://www.shopify.com/blog/product-research'
  'product-page|https://www.shopify.com/blog/product-page'
  'payment-gateways|https://stripe.com/payments'
  'shipping|https://www.usps.com/international/'
  'website-testing|https://pagespeed.web.dev/'
  'marketing|https://www.shopify.com/blog/marketing-strategy'
  'store-launch|https://help.shopify.com/en/manual/online-store/setting-up'
  'growth-analytics|https://marketingplatform.google.com/about/analytics/'
  'tax-compliance|https://www.irs.gov/businesses/small-businesses-self-employed/limited-liability-company-llc'
  'customer-loyalty|https://www.shopify.com/blog/customer-loyalty-program'
)

for capture in "${captures[@]}"; do
  IFS='|' read -r name url <<< "$capture"
  if (( $# > 0 )); then
    requested=false
    for target in "$@"; do
      if [[ "$target" == "$name" ]]; then
        requested=true
        break
      fi
    done
    [[ "$requested" == true ]] || continue
  fi
  printf 'Capturing %s\n' "$name"
  python3 -c 'import subprocess, sys; subprocess.run(sys.argv[1:], check=True, timeout=25, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)' \
    "$chrome" --headless=new --no-first-run --no-default-browser-check \
    --disable-gpu --disable-background-networking --hide-scrollbars --window-size=1200,600 \
    --virtual-time-budget=3000 --user-data-dir="$profile_dir" \
    --screenshot="$image_dir/$name.png" "$url"
  if [[ ! -s "$image_dir/$name.png" ]]; then
    printf 'Capture failed: %s\n' "$url" >&2
    exit 1
  fi
done
