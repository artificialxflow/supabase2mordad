# استک کامل Supabase — یک سرویس Docker برای Runflare

## این پروژه چیست؟

یک **Dockerfile همه‌کاره** که داخل یک کانتینر این‌ها را بالا می‌آورد:

| پروسه | پورت داخلی | نقش |
|--------|------------|-----|
| Postgres (Supabase) | 5432 | دیتابیس با اسکیمای `auth` |
| GoTrue (Auth) | 9999 | لاگین / ثبت‌نام |
| PostgREST | 3001 | REST API |
| postgres-meta | 8080 | متادیتا |
| Studio | 3000 | داشبورد |
| **nginx (عمومی)** | **8000** | دروازه `/auth` `/rest` `/` |

دامنه باید به پورت **8000** وصل شود.

---

## دقیقاً روی Runflare چه کار کنید

### ۱) پورت
**Expose Port = `8000`** (نه 3000)

### ۲) متغیرهای محیطی (Bulk Edit)
کل محتوای `.env.example` را paste کنید. حداقل:

- `POSTGRES_PASSWORD`
- `JWT_SECRET`
- `ANON_KEY`
- `SERVICE_ROLE_KEY`
- `PG_META_CRYPTO_KEY`
- `SUPABASE_PUBLIC_URL=https://supabase.pasteur.plus`
- `API_EXTERNAL_URL=https://supabase.pasteur.plus`
- `SITE_URL=https://pasteur.plus`
- `ADDITIONAL_REDIRECT_URLS=https://pasteur.plus/**`
- `ENABLE_EMAIL_AUTOCONFIRM=true`
- `KONG_HTTP_PORT=8000`

### ۳) Deploy
کد را Deploy کنید و **۵–۱۰ دقیقه** برای init دیتابیس صبر کنید.

### ۴) تست
1. `https://supabase.pasteur.plus/auth/v1/health` → باید OK باشد  
2. `https://supabase.pasteur.plus/` → Studio  
3. اگر 502 بود، لاگ را بفرستید (خطوط `[start]` و `[health]`)

### ۵) فرانت Pasteur
```env
NEXT_PUBLIC_SUPABASE_URL=https://supabase.pasteur.plus
NEXT_PUBLIC_SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJyb2xlIjoiYW5vbiIsImlzcyI6InN1cGFiYXNlIiwiaWF0IjoxNjQxNzY5MjAwLCJleHAiOjE5ODA5NjYwMDB9.6LDzhWwsXYabPo7AzXbHfIcFyW2w_ZA2yyV6A-tgyeE
```

---

## منابع

استک کامل سنگین است. اگر پاد مدام Restart شد، RAM را به **حداقل ۲GB** برسانید و در صورت امکان دیسک پایدار بدهید.

---

## نکته

Postgres جداگانه قبلی (`melkradardbnext-...`) دیگر برای این استک استفاده نمی‌شود؛ دیتابیس داخل همین کانتینر با ایمیج رسمی Supabase است تا اسکیمای `auth` وجود داشته باشد.
