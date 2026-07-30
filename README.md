# راهنمای استقرار Supabase Studio روی Runflare

این پروژه Studio + postgres-meta را با پورت **3000** بالا می‌آورد و با یک `DATABASE_URL` به Postgres وصل می‌شود.

---

## متغیرهای محیطی (همین‌ها را در Runflare بگذارید)

محتوای درست الان در `.env.example` است. در پنل سرویس `supabase` → **تنظیم متغیر محیطی** → **Bulk Edit** دقیقاً این را بچسبانید:

```env
DATABASE_URL=postgresql://postgres:ljW3Onfbo6PSYVS3nidi@melkradardbnext-oft-qeu-service:5432/melkradatjp_db
SUPABASE_URL=https://supabase-pasteurplus.runflare.run
PORT=3000
HOSTNAME=0.0.0.0
```

اگر در صفحه دیتابیس host متفاوت بود (مثلاً `...-cft-...`)، همان **uri (internal)** صفحه دیتابیس را جایگزین خط `DATABASE_URL` کنید.

---

## دقیقاً چه کار کنید؟

1. در Runflare، سرویس **supabase** را باز کنید.
2. مطمئن شوید **Expose Port = 3000**.
3. بروید **تنظیم متغیر محیطی** → Bulk Edit → چهار متغیر بالا را ذخیره کنید.
4. کد/پروژه را دوباره **Deploy** کنید (GIT / CLI / Drag & Drop — همان روش قبلی).
5. ۱–۲ دقیقه صبر کنید تا ابرک `فعال` شود.
6. باز کنید: https://supabase-pasteurplus.runflare.run
7. اگر باز نشد: **مشاهده لاگ** را چک کنید و خطا را کپی کنید.

---

## لوکال (اختیاری)

```bash
cp .env.example .env
docker compose up --build
```

سپس: http://localhost:3000

---

## نکته امنیتی

فایل `.env` در گیت ignore است. اگر مخزن عمومی است، پسورد را در `.env.example` نگه ندارید و در Postgres عوضش کنید.
