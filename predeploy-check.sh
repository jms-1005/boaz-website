#!/usr/bin/env bash
# Pre-deploy guard for boaz.club.
# Fails if the critical HubSpot form fields or the mobile nav regress
# (e.g. index.html rebuilt from a stale source). Run before committing/deploying:
#   ./predeploy-check.sh            # checks ./index.html
#   ./predeploy-check.sh path.html  # checks a specific file
set -u
FILE="${1:-$(dirname "$0")/index.html}"
fail=0
need(){   grep -qF "$1" "$FILE" || { echo "  MISSING:     $2"; fail=1; }; }
forbid(){ grep -qF "$1" "$FILE" && { echo "  REGRESSION:  $2"; fail=1; }; }

[ -f "$FILE" ] || { echo "File not found: $FILE"; exit 2; }
echo "Checking $FILE ..."

# HubSpot form field names must match the HubSpot contact properties exactly
need 'name="existing_land_size"'   'Lend-your-land: land-size field (existing_land_size)'
need 'name="greenhouse"'           'Lend-your-land: greenhouse field (greenhouse)'
need 'name="firstname"'            'Form: first-name field'
need 'name="email"'                'Form: email field'
need 'api.hsforms.com/submissions' 'HubSpot submission endpoint'
need 'name="restaurant_name"'   'Restaurant: restaurant-name field (restaurant_name)'
need 'name="interested_in"'     'Restaurant: interested-in field (interested_in)'

# Mobile nav: hamburger + compact "Join" CTA
need 'id="navToggle"'               'Mobile nav: hamburger button'
need 'getElementById("navToggle")'  'Mobile nav: toggle script'
need 'class="cta-short"'            'Mobile nav: compact "Join" label'
need 'id="navLinks"'                'Mobile nav: menu container id'

# Known-bad names = a stale/clobbered build slipped through
forbid 'name="land_size"'              'old land-size field name is back'
forbid 'name="no_existing_greenhouse"' 'old greenhouse field name is back'
forbid 'name="i_am_interested_in"' 'old restaurant interested-in name is back'
forbid '<input name="lastname" placeholder="Restaurant' 'restaurant name mapped to lastname'

if [ "$fail" -ne 0 ]; then
  echo ""
  echo "FAIL: pre-deploy check failed for $FILE. Do not deploy."
  exit 1
fi
echo "PASS: pre-deploy check passed for $FILE."
