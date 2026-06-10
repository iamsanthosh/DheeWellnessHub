# DheeWellnessHub — Course Enrollment Platform

Live online course enrollment with UPI payment, admin verification, and WhatsApp group automation.

---

## Architecture

```
public/
  index.html      ← Student SPA (courses, cart, payment, status)
  admin.html      ← Admin dashboard (payments, courses, UI editor, settings)
netlify/functions/
  public-data.js  ← GET  /api/public-data   (ui_content + settings + courses)
  submit-payment.js← POST /api/submit-payment
  admin-login.js  ← POST /api/admin-login
  admin-data.js   ← GET  /api/admin-data    (all data, token-gated)
  admin-action.js ← POST /api/admin-action  (verify/reject, CRUD, UI updates)
supabase-schema.sql ← Full DB schema + seed data
netlify.toml
package.json
```

---

## Setup in 5 steps

### 1. Create Supabase project
1. Go to [supabase.com](https://supabase.com) → New project
2. Go to **SQL Editor** → paste entire `supabase-schema.sql` → Run
3. Copy your **Project URL** and **service_role secret key** from Settings → API

### 2. Deploy to Netlify
1. Push this repo to GitHub
2. Go to [netlify.com](https://netlify.com) → New site from Git
3. Build settings:
   - Publish directory: `public`
   - Functions directory: `netlify/functions`

### 3. Set environment variables in Netlify
Go to Site Settings → Environment Variables → Add:

| Key | Value |
|-----|-------|
| `SUPABASE_URL` | `https://xxxx.supabase.co` |
| `SUPABASE_SERVICE_KEY` | `eyJhbGci...` (service_role key) |

### 4. Install dependencies
```bash
npm install
```
The Netlify build process will auto-install `@supabase/supabase-js` during deploy.

### 5. Configure your site
1. Visit `your-site.netlify.app/admin.html`
2. Login with `admin@DheeWellnessHub.com` / `admin123`
3. Go to **Settings** → update admin email, password, UPI ID
4. Go to **UI Labels & Text** → customize every piece of text on the site
5. Go to **Courses** → add your real courses

---

## UI Content System

Every label, button, heading, and piece of copy on the student site is stored in the `ui_content` table with a `key` like:

```
hero.title_line1        → "Skills that open"
courses.add_cart_btn    → "Add to Cart"
payment.submit_btn      → "Submit Payment"
status.step2_sub        → "We match with bank statement"
```

The admin can edit any of these in **Admin → UI Labels & Text** — changes go live immediately on next page load.

---

## Student Flow

1. **Browse** → courses pulled from Supabase
2. **Add to Cart** → session storage
3. **Payment** → QR code generated from UPI ID, form submitted to Supabase
4. **Status page** → "Pending Verification"
5. **Admin verifies** → payment marked verified, enrollment record created
6. **Student** → gets WhatsApp group link (admin can send manually or via WhatsApp Business API)

---

## Admin Flow

1. Login at `/admin.html`
2. **Dashboard** → stats overview + recent payments
3. **Payments** → filter by pending/verified/rejected, click Verify/Reject
4. **Enrollments** → see all confirmed students + WhatsApp group links
5. **Courses** → add/edit/delete courses and batches
6. **UI Labels** → edit every text label on the student site
7. **Settings** → UPI ID, QR image, branding colors, admin credentials

---

## WhatsApp Integration (manual + optional API)

Currently: when a payment is verified, the enrollment record stores the `whatsapp_link` from the course. The admin can see it in Enrollments and share manually.

For **automated** WhatsApp invites, add your API call inside `admin-action.js` in the `verify_payment` block:

```js
// After creating enrollment records:
await fetch('https://api.whatsapp.business/v1/messages', {
  method: 'POST',
  headers: { 'Authorization': `Bearer ${process.env.WA_TOKEN}` },
  body: JSON.stringify({
    to: payment.phone,
    type: 'text',
    text: { body: `Welcome! Join your batch: ${whatsapp_link}` }
  })
});
```

---

## Local Development

```bash
npm install -g netlify-cli
netlify dev
```

This starts the dev server at `http://localhost:8888` with functions available at `/.netlify/functions/*`.
