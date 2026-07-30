# راهنمای استقرار Supabase Studio روی Runflare

این پروژه **Supabase Studio** (رابط مدیریت) + **postgres-meta** را بالا می‌آورد و به یک Postgres از قبل موجود وصل می‌شود.

> این استک کامل Supabase (Auth / Storage / Realtime / API Gateway) نیست؛ فقط پنل Studio برای مدیریت دیتابیس است.

---

## پیش‌نیاز: آیا باید Postgres بسازم؟

| وضعیت | کار شما |
|--------|---------|
| از قبل یک سرویس Postgres روی Runflare دارید (مثلاً `melkradardbnext-oft-service`) | **نیازی به ساخت دوباره نیست** |
| Postgres ندارید یا Studio به آن دسترسی شبکه ندارد | در همان پروژه Runflare یک سرویس **Postgres** بسازید |

Connection string را از پنل Postgres کپی کنید. معمولاً شبیه این است:

```text
postgresql://postgres:YOUR_PASSWORD@NAMENAME-service:5432/postgres
```

نکته مهم: ترجیحاً از **آدرس داخلی / نام سرویس** استفاده کنید (نه دامنه عمومی)، تا از داخل شبکه Runflare وصل شود.

---

## فقط یک متغیر اجباری: `DATABASE_URL`

دیگر لازم نیست host / user / password را جداگانه وارد کنید. همین connection string کافی است؛ هنگام استارت خودکار به متغیرهای داخلی تبدیل می‌شود.

### متغیرهایی که در Runflare می‌گذارید

| متغیر | اجباری؟ | توضیح |
|--------|---------|--------|
| `DATABASE_URL` | بله | همان connection string پستگرس |
| `SUPABASE_URL` | توصیه می‌شود | دامنه Studio، مثلاً `https://supabase-pasteurplus.runflare.run` |
| `SUPABASE_PUBLIC_ANON_KEY` | اختیاری | تا استک کامل ندارید می‌تواند `placeholder-anon-key` بماند |
| `SUPABASE_SERVICE_ROLE_KEY` | اختیاری | تا استک کامل ندارید می‌تواند `placeholder-service-role-key` بماند |

نمونه `DATABASE_URL`:

```env
DATABASE_URL=postgresql://postgres:YOUR_PASSWORD@melkradardbnext-oft-service:5432/postgres
```

اگر پسورد کاراکتر خاص دارد (`@`، `#`، `%` و …) باید در URL به‌صورت URL-encoded باشد.

---

## مراحل کار در Runflare (گام‌به‌گام)

### ۱) Postgres

- اگر دارید: connection string را بردارید.
- اگر ندارید: سرویس Postgres بسازید و string را کپی کنید.

### ۲) سرویس این پروژه (`supabase`)

1. کد را به گیت پوش کنید و در Runflare به مخزن وصل کنید (یا از نوع docker-compose استقرار دهید).
2. در تنظیمات سرویس، **پورت را روی `3000`** بگذارید.
3. از منوی **تنظیم متغیر محیطی** این‌ها را اضافه کنید:
   - `DATABASE_URL` = connection string پستگرس
   - `SUPABASE_URL` = `https://supabase-pasteurplus.runflare.run` (یا دامنه خودتان)
4. **استقرار / Redeploy** بزنید.
5. صبر کنید تا ابرک `فعال` شود.
6. دامنه را باز کنید: `https://supabase-pasteurplus.runflare.run`

### ۳) اگر صفحه باز نشد

1. **لاگ** سرویس را ببینید؛ باید خطی شبیه این باشد:
   - `[with-database-url] connected as postgres@...`
2. در **شبکه‌ها** مطمئن شوید expose روی **3000** است (نه 8000).
3. مطمئن شوید Postgres و Studio در **یک شبکه / یک پروژه** هستند و نام host داخل `DATABASE_URL` درست است.
4. اگر خطا `connection refused` به Postgres دیدید، host را با نام داخلی سرویس Postgres عوض کنید.

---

## فایل‌های مهم پروژه

| فایل | نقش |
|------|-----|
| `docker-compose.yml` | سرویس‌های `studio` (پورت 3000) و `meta` |
| `Dockerfile` | Studio + خواندن `DATABASE_URL` |
| `Dockerfile.meta` | postgres-meta + خواندن `DATABASE_URL` |
| `scripts/with-database-url.js` | تبدیل connection string به تنظیمات اتصال |
| `.env.example` | الگوی متغیرها (داخل گیت می‌رود) |
| `.env` | مقادیر واقعی لوکال (**داخل گیت نمی‌رود**) |

---

## اجرای لوکال (اختیاری)

```bash
cp .env.example .env
# سپس DATABASE_URL واقعی را در .env بگذارید
docker compose up --build
```

بعداً باز کنید: [http://localhost:3000](http://localhost:3000)

---

## امنیت

- فایل `.env` در `.gitignore` است؛ رمز را commit نکنید.
- در Runflare هم رمز را فقط در بخش متغیر محیطی بگذارید.
- `.env.example` فقط نمونه بدون رمز واقعی است.

---

## محدودیت فعلی

با این پروژه می‌توانید دیتابیس را از طریق Studio مدیریت کنید. اگر بعداً Auth، Storage، و API کامل Supabase خواستید، باید استک رسمی Supabase (Kong، Auth، PostgREST و …) اضافه شود و کلیدهای JWT واقعی ساخته شوند.
