#!/data/data/com.termux/files/usr/bin/bash

MODEL_PATH="/data/data/com.termux/files/home/models/qwen2.5-1.5b-instruct.gguf"
PORT=8080

echo "🚀 Initializing Hybrid AI Assistant Environment..."

# 1. Verify model file existence
if [ ! -f "$MODEL_PATH" ]; then
    echo "❌ Error: Model file not found at $MODEL_PATH"
    exit 1
fi

# 2. Check and launch llama-server
if pgrep -x "llama-server" > /dev/null; then
    echo "✅ Local llama-server is already active."
else
    echo "🔄 Starting local llama-server in the background..."
    llama-server \
      -m "$MODEL_PATH" \
      --port "$PORT" \
      --host 127.0.0.1 \
      -t 4 \
      -c 2048 \
      --batch-size 512 > /dev/null 2>&1 &
    
    echo "⏳ Waiting for local SLM to load into memory..."
    sleep 4
fi

# 3. Check Google Cloud API configuration (mohammadsameerrgorajanals@gmail.com)
if [ -z "$GOOGLE_CLOUD_API_KEY" ]; then
    echo "⚠️ Notice: GOOGLE_CLOUD_API_KEY environment variable is not set."
    echo "   To enable cloud routing, run: export GOOGLE_CLOUD_API_KEY='your_api_key'"
else
    echo "☁️ Cloud API configuration detected for mohammadsameerrgorajanals@gmail.com."
fi

# 4. Launch the hybrid assistant python script
if [ -f "voice_assistant.py" ]; then
    echo "🎙️ Launching hybrid voice assistant pipeline..."
    python3 voice_assistant.py
else
    echo "❌ Error: voice_assistant.py not found in the current directory."
    exit 1
fi
