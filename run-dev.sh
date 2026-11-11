#!/usr/bin/env bash
# Formly Quick Runner Script
# Usage:
#   ./run-dev.sh                 # Jalankan dengan mode Mock Lokal
#   ./run-dev.sh supabase        # Jalankan dengan konfigurasi Supabase dari file .env

set -e

DEVICE_IP="10.143.33.141:40211"

if [ "$1" == "supabase" ]; then
    if [ ! -f .env ]; then
        echo "File .env belum ditemukan! Silakan salin .env.example menjadi .env terlebih dahulu."
        exit 1
    fi
    export $(grep -v '^#' .env | xargs)
    echo "Menjalankan Formly terhubung ke Supabase: $SUPABASE_URL"
    flutter run -d "$DEVICE_IP" \
        --dart-define=SUPABASE_URL="$SUPABASE_URL" \
        --dart-define=SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY"
else
    echo "Menjalankan Formly dalam mode Mock Lokal (Demo Mode)..."
    flutter run -d "$DEVICE_IP"
fi
