
FROM ubuntu:22.04

# تعيين متغيرات البيئة لتجنب التفاعل أثناء التثبيت
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
RUN cp stream/nginx.conf /etc/nginx/nginx.conf \
    && sed -i 's|/home/runner/workspace/|/app/|g' /etc/nginx/nginx.conf

# نسخ nginx config للمكان الصحيح وتعديله
RUN cp stream/nginx.conf /etc/nginx/nginx.conf \
    && sed -i 's/listen 5000;/listen 8000;/g' /etc/nginx/nginx.conf \
    && sed -i 's|/home/runner/workspace/|/app/|g' /etc/nginx/nginx.conf

# تعريف البورت
EXPOSE 8000

# تشغيل التطبيق
CMD ["./perfect_stream.sh"]
