#!/bin/bash
# ============================================================
# Flutter IPTV - Keystore Setup Helper
# ============================================================
# Usage: bash scripts/generate_keystore.sh
# ============================================================

set -e

echo ""
echo "🔑 Flutter IPTV - Keystore Generator"
echo "======================================"
echo ""

read -p "Enter keystore filename (default: release.jks): " KEYSTORE_FILE
KEYSTORE_FILE="${KEYSTORE_FILE:-release.jks}"

read -p "Enter key alias (default: flutter_iptv): " KEY_ALIAS
KEY_ALIAS="${KEY_ALIAS:-flutter_iptv}"

read -sp "Enter keystore password: " KEYSTORE_PASSWORD
echo ""

read -sp "Confirm keystore password: " KEYSTORE_PASSWORD_CONFIRM
echo ""

if [ "$KEYSTORE_PASSWORD" != "$KEYSTORE_PASSWORD_CONFIRM" ]; then
  echo "❌ Passwords don't match!"
  exit 1
fi

read -sp "Enter key password (press Enter to use same as keystore): " KEY_PASSWORD
echo ""
KEY_PASSWORD="${KEY_PASSWORD:-$KEYSTORE_PASSWORD}"

echo ""
echo "📋 Keystore details:"
read -p "  Your name / organization: " YOUR_NAME
read -p "  Organization unit: " ORG_UNIT
read -p "  Organization: " ORG
read -p "  City: " CITY
read -p "  State: " STATE
read -p "  Country code (e.g. US, ID): " COUNTRY

echo ""
echo "🔨 Generating keystore..."

keytool -genkey -v \
  -keystore "$KEYSTORE_FILE" \
  -alias "$KEY_ALIAS" \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000 \
  -storepass "$KEYSTORE_PASSWORD" \
  -keypass "$KEY_PASSWORD" \
  -dname "CN=$YOUR_NAME, OU=$ORG_UNIT, O=$ORG, L=$CITY, ST=$STATE, C=$COUNTRY"

echo ""
echo "✅ Keystore generated: $KEYSTORE_FILE"
echo ""

# Create key.properties
cat > android/key.properties << EOF
storeFile=../$(basename $KEYSTORE_FILE)
storePassword=$KEYSTORE_PASSWORD
keyAlias=$KEY_ALIAS
keyPassword=$KEY_PASSWORD
EOF

echo "📝 Created android/key.properties"
echo ""

# Encode to base64 for GitHub Actions
echo "📦 Base64 encoded keystore (for GitHub Actions secret KEY_STORE_BASE64):"
echo ""
BASE64_KEYSTORE=$(base64 -i "$KEYSTORE_FILE" | tr -d '\n')
echo "$BASE64_KEYSTORE"
echo ""
echo "⚠️  Add the above to GitHub Repository Secrets as:"
echo "   KEY_STORE_BASE64 = <above base64 string>"
echo "   KEY_STORE_PASSWORD = $KEYSTORE_PASSWORD"
echo "   KEY_ALIAS = $KEY_ALIAS"
echo "   KEY_PASSWORD = $KEY_PASSWORD"
echo ""
echo "🔒 Keep your keystore file safe! Never commit it to git."
