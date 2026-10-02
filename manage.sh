#!/usr/bin/env bash

PID_FILE="app.pid"
LOG_FILE="app.log"

case "$1" in
    start)
        if [ -f "$PID_FILE" ] && kill -0 $(cat "$PID_FILE") 2>/dev/null; then
            echo "Flask server is already running (PID: $(cat "$PID_FILE"))"
            exit 1
        fi
        echo "Starting Flask server..."
        nohup python3 app.py > "$LOG_FILE" 2>&1 &
        echo $! > "$PID_FILE"
        echo "Server started successfully. Logs: $LOG_FILE"
        ;;
    stop)
        if [ ! -f "$PID_FILE" ] || ! kill -0 $(cat "$PID_FILE") 2>/dev/null; then
            echo "Flask server is not running."
            rm -f "$PID_FILE"
            exit 1
        fi
        echo "Stopping Flask server (PID: $(cat "$PID_FILE"))..."
        kill $(cat "$PID_FILE")
        rm -f "$PID_FILE"
        echo "Server stopped."
        ;;
    status)
        if [ -f "$PID_FILE" ] && kill -0 $(cat "$PID_FILE") 2>/dev/null; then
            echo "Flask server is running (PID: $(cat "$PID_FILE"))"
        else
            echo "Flask server is stopped."
        fi
        ;;
    *)
        echo "Usage: $0 {start|stop|status}"
        exit 1
        ;;
esac
