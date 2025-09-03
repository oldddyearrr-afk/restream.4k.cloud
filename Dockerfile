FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC
ENV PORT=8000

# تثبيت الحزم المطلوبة
RUN apt-get update && apt-get install -y \
    ffmpeg \
    nginx \
    bash \
    curl \
    ca-certificates \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# إنشاء مجلد العمل
WORKDIR /app

# نسخ جميع الملفات
COPY . .

# إنشاء المجلدات المطلوبة
RUN mkdir -p stream/hls stream/logs \
    && mkdir -p /var/log/nginx /var/lib/nginx /run \
    && chmod +x perfect_stream.sh \
    && chmod 755 stream/hls

# نسخ nginx.conf للمكان الصحيح
RUN cp stream/nginx.conf /etc/nginx/nginx.conf

# تعريف البورت
EXPOSE 8000

# تشغيل التطبيق
CMD ["./perfect_stream.sh"]
