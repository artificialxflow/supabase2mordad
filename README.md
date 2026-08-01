# استک کامل Supabase برای Pasteur / Runflare

این پروژه دیگر فقط Studio نیست. سرویس‌ها:

| سرویس | نقش |
|--------|-----|
| `db` | Postgres با اسکیمای Supabase (`auth`, نقش‌ها، …) |
| `kong` | دروازه API عمومی روی **پورت 8000** |
| `auth` | GoTrue → `/auth/v1/...` |
| `rest` | PostgREST → `/rest/v1/...` |
| `meta` | متادیتا برای Studio |
| `studio` | داشبورد UI (از پشت Kong روی `/`) |

---

## مهم روی Runflare

1. نوع استقرار: **docker-compose** (نه فقط Dockerfile)
2. **Expose Port = 8000** (Kong) — دیگر 3000 نباشد
3. دامنه `supabase.pasteur.plus` به همین سرویس وصل باشد
4. همه متغیرهای `.env.example` را در **Bulk Edit** متغیر محیطی هم بگذارید
5. دیسک پایدار برای volume دیتابیس در نظر بگیرید (داده‌ها داخل `db-data` است)
6. RAM: برای این استک حداقل **۲GB+** توصیه می‌شود

---

## چک سلامت بعد از Deploy

```text
https://supabase.pasteur.plus/auth/v1/health
```
باید جواب سالم بدهد (نه 404 HTML استودیو).

```text
https://supabase.pasteur.plus/rest/v1/
```
با هدر `apikey` و `Authorization: Bearer <ANON_KEY>` باید پاسخ API بدهد.

Studio از همان دامنه روی مسیر `/` باز می‌شود.

---

## کلیدها برای فرانت Next (Pasteur)

از `.env` / پنل Runflare:

```env
NEXT_PUBLIC_SUPABASE_URL=https://supabase.pasteur.plus
NEXT_PUBLIC_SUPABASE_ANON_KEY=<همان ANON_KEY>
```

---

## Postgres جداگانه Runflare (`melkradardbnext-...`)

این استک **Postgres داخلی Supabase** می‌آورد (برای Auth لازم است).  
Postgres قبلی Runflare برای Auth کافی نیست مگر اسکیمای کامل Supabase روی آن init شود. می‌توانید آن را برای چیز دیگر نگه دارید؛ برای این استک لازم نیست.

---

## استقرار

```bash
# لوکال
cp .env.example .env
docker compose up -d
```

روی Runflare: Deploy با docker-compose + پورت 8000 + envها.

---

## SQL فاز ۱ Pasteur

بعد از سبز شدن `/auth/v1/health`، اسکریپت‌ها را به ترتیب در Studio SQL Editor یا با `psql` روی سرویس `db` اجرا کنید (01 → 02 → …).
