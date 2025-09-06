#!/bin/bash

# تنظيف شامل
echo "🧹 Perfect cleanup..."
pkill -f nginx 2>/dev/null || true
pkill -f ffmpeg 2>/dev/null || true
sleep 3

# متغيرات مشروع منظمة
SOURCE_URL="http://188.241.219.157/live/starshare-Shawkat/abdo/274176.ts?token=ShJdY2ZmQQNHCmMZCDZXUh9GSHAWGFMD.ZDsGQVN.WGBFNX013GR9YV1QbGBp0QE9SWmpcXlQXXlUHWlcbRxFACmcDY1tXEVkbVAoAAQJUFxUbRFldAxdeUAdaVAFcUwcHAhwWQlpXQQMLTFhUG0FQQU1VQl4HWTsFVBQLVABGCVxEXFgeEVwNZgFcWVlZBxcDGwESHERcFxETWAxCCQgfEFNZQEBSRwYbX1dBVFtPF1pWRV5EFExGWxMmJxVJRlZKRVVaQVpcDRtfG0BLFU8XUEpvQlUVQRYEUA8HRUdeEQITHBZfUks8WgpXWl1UF1xWV0MSCkQERk0TDw1ZDBBcQG5AXVYRCQ1MCVVJ"
WORK_DIR="/app"
STREAM_DIR="$WORK_DIR/stream"
HLS_DIR="$STREAM_DIR/hls"
LOGS_DIR="$STREAM_DIR/logs"
NGINX_CONF="/etc/nginx/nginx.conf"
PORT=${PORT:-8000}

echo "🚀 Perfect Stream Server v2.0"
echo "📁 Stream dir: $STREAM_DIR"
echo "🌐 Port: $PORT"

# استبدال البورت داخل Nginx config
sed -i "s/PORT_PLACEHOLDER/$PORT/" "$NGINX_CONF"

# إنشاء مجلدات وتنظيف سريع
mkdir -p "$LOGS_DIR" 2>/dev/null || true
find "$HLS_DIR" -name "*.ts" -delete 2>/dev/null || true
find "$HLS_DIR" -name "*.m3u8" -delete 2>/dev/null || true
rm -f "$LOGS_DIR"/*.log "$LOGS_DIR"/*.pid 2>/dev/null || true

echo "🌐 Starting nginx (perfect config)..."
nginx &
NGINX_PID=$!
sleep 2

echo "📺 Starting FFmpeg (no-error mode)..."
ffmpeg -hide_banner -loglevel error \
    -fflags +genpts \
    -user_agent "Mozilla/5.0 (compatible; Stream/1.0)" \
    -reconnect 1 \
    -reconnect_at_eof 1 \
    -reconnect_streamed 1 \
    -reconnect_delay_max 10 \
    -rw_timeout 10000000 \
    -i "$SOURCE_URL" \
    -c:v copy \
    -c:a copy \
    -f hls \
    -hls_time 4 \
    -hls_list_size 5 \
    -hls_flags delete_segments+independent_segments \
    -hls_segment_filename "$HLS_DIR/seg_%03d.ts" \
    "$HLS_DIR/playlist.m3u8" &

FFMPEG_PID=$!

echo "✅ Perfect Stream Server Running!"
echo "🌐 Web: http://0.0.0.0:$PORT"
echo "📺 Stream: http://0.0.0.0:$PORT/hls/playlist.m3u8"
echo "📊 FFmpeg: $FFMPEG_PID | Nginx: $NGINX_PID"

# مراقبة FFmpeg + تنظيف segments
monitor_ffmpeg() {
    while true; do
        sleep 30
        if ! kill -0 $FFMPEG_PID 2>/dev/null; then
            echo "🔄 FFmpeg crashed, restarting..."
            ffmpeg -hide_banner -loglevel error \
                -fflags +genpts \
                -user_agent "Mozilla/5.0 (compatible; Stream/1.0)" \
                -reconnect 1 \
                -reconnect_at_eof 1 \
                -reconnect_streamed 1 \
                -reconnect_delay_max 10 \
                -rw_timeout 10000000 \
                -i "$SOURCE_URL" \
                -c:v copy \
                -c:a copy \
                -f hls \
                -hls_time 4 \
                -hls_list_size 5 \
                -hls_flags delete_segments+independent_segments \
                -hls_segment_filename "$HLS_DIR/seg_%03d.ts" \
                "$HLS_DIR/playlist.m3u8" &
            FFMPEG_PID=$!
            echo "✅ FFmpeg restarted with PID: $FFMPEG_PID"
        fi
    done
}

cleanup_segments() {
    while true; do
        sleep 20
        SEGMENT_COUNT=$(ls -1 "$HLS_DIR"/seg_*.ts 2>/dev/null | wc -l)
        if [ "$SEGMENT_COUNT" -gt 10 ]; then
            echo "🧹 Cleaning old segments... (found $SEGMENT_COUNT, keeping 10)"
            ls -1t "$HLS_DIR"/seg_*.ts | tail -n +11 | xargs rm -f 2>/dev/null || true
        fi
    done
}

monitor_ffmpeg &
MONITOR_PID=$!
cleanup_segments &
CLEANUP_PID=$!

cleanup() {
    echo "🛑 Stopping all services..."
    kill $FFMPEG_PID 2>/dev/null || true
    kill $NGINX_PID 2>/dev/null || true
    kill $MONITOR_PID 2>/dev/null || true
    kill $CLEANUP_PID 2>/dev/null || true
    echo "✅ All services stopped."
    exit 0
}

trap cleanup SIGTERM SIGINT

while true; do
    sleep 60
done
