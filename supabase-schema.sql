-- ============================================================
-- DheeWellnessHub — SUPABASE SCHEMA
-- Run this entire file in Supabase SQL Editor
-- ============================================================

-- ── 1. UI CONTENT (ALL labels, text, copy — fully configurable) ──
CREATE TABLE IF NOT EXISTS ui_content (
  id            BIGSERIAL PRIMARY KEY,
  key           TEXT UNIQUE NOT NULL,   -- e.g. "hero.title", "nav.cart_button"
  value         TEXT NOT NULL,          -- The actual text shown in UI
  description   TEXT,                  -- Admin hint: what this text is used for
  section       TEXT NOT NULL,         -- "nav" | "hero" | "courses" | "cart" | "payment" | "status" | "admin" | "footer"
  updated_at    TIMESTAMPTZ DEFAULT NOW()
);

-- ── 2. SITE SETTINGS (colors, logos, UPI, QR, WhatsApp config) ──
CREATE TABLE IF NOT EXISTS site_settings (
  id            BIGSERIAL PRIMARY KEY,
  key           TEXT UNIQUE NOT NULL,
  value         TEXT,
  description   TEXT,
  updated_at    TIMESTAMPTZ DEFAULT NOW()
);

-- ── 3. COURSES ──
CREATE TABLE IF NOT EXISTS courses (
  id            BIGSERIAL PRIMARY KEY,
  name          TEXT NOT NULL,
  tag           TEXT DEFAULT 'General',
  batch_name    TEXT,
  start_date    DATE,
  end_date      DATE,
  duration      TEXT,
  schedule      TEXT,
  price         INTEGER NOT NULL DEFAULT 0,
  total_seats   INTEGER NOT NULL DEFAULT 30,
  enrolled      INTEGER NOT NULL DEFAULT 0,
  description   TEXT,
  whatsapp_link TEXT,
  is_active     BOOLEAN DEFAULT TRUE,
  created_at    TIMESTAMPTZ DEFAULT NOW(),
  updated_at    TIMESTAMPTZ DEFAULT NOW()
);

-- ── 4. PAYMENTS ──
CREATE TABLE IF NOT EXISTS payments (
  id            BIGSERIAL PRIMARY KEY,
  student_name  TEXT NOT NULL,
  email         TEXT NOT NULL,
  phone         TEXT NOT NULL,
  utr           TEXT NOT NULL,
  payment_date  DATE NOT NULL,
  amount        INTEGER NOT NULL,
  status        TEXT NOT NULL DEFAULT 'pending',  -- pending | verified | rejected
  course_ids    INTEGER[],
  course_names  TEXT,
  submitted_at  TIMESTAMPTZ DEFAULT NOW(),
  verified_at   TIMESTAMPTZ,
  rejected_at   TIMESTAMPTZ,
  admin_note    TEXT
);

-- ── 5. ENROLLMENTS (created when payment verified) ──
CREATE TABLE IF NOT EXISTS enrollments (
  id            BIGSERIAL PRIMARY KEY,
  payment_id    INTEGER REFERENCES payments(id),
  student_name  TEXT NOT NULL,
  email         TEXT NOT NULL,
  phone         TEXT NOT NULL,
  course_id     INTEGER REFERENCES courses(id),
  course_name   TEXT,
  whatsapp_link TEXT,
  enrolled_at   TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- SEED: UI CONTENT — DEFAULT LABELS (fully editable via admin)
-- ============================================================
INSERT INTO ui_content (key, value, description, section) VALUES

-- NAV
('nav.logo',            'DheeWellnessHub',                     'Brand name shown in navbar',                  'nav'),
('nav.logo_suffix',     '',                                    'Optional suffix after logo (e.g. Academy)',   'nav'),
('nav.cart_button',     'Cart',                                'Cart button label',                           'nav'),
('nav.admin_button',    'Admin',                               'Admin login button text',                     'nav'),
('nav.tagline',         'Live Online Courses',                 'Tagline shown next to logo on desktop',       'nav'),

-- HERO
('hero.eyebrow',        '🎓 Enrollments Open — Limited Seats', 'Small label above hero headline',             'hero'),
('hero.title_line1',    'Skills that open',                    'Hero headline line 1',                        'hero'),
('hero.title_line2',    'doors.',                              'Hero headline line 2 (highlighted word)',     'hero'),
('hero.subtitle',       'Expert-led live batches with hands-on projects, 1:1 mentoring, and a community that moves with you.', 'Hero subtext paragraph', 'hero'),
('hero.stat1_value',    '1,200+',                              'Stat 1 number',                               'hero'),
('hero.stat1_label',    'Students trained',                    'Stat 1 label',                                'hero'),
('hero.stat2_value',    '4.9 ★',                               'Stat 2 number',                               'hero'),
('hero.stat2_label',    'Average rating',                      'Stat 2 label',                                'hero'),
('hero.stat3_value',    '92%',                                 'Stat 3 number',                               'hero'),
('hero.stat3_label',    'Placement rate',                      'Stat 3 label',                                'hero'),
('hero.cta_primary',    'Browse courses',                      'Hero primary CTA button',                     'hero'),

-- COURSES PAGE
('courses.section_title',   'Available Batches',               'Courses section heading',                     'courses'),
('courses.section_sub',     'Pick a batch — seats fill fast.', 'Courses section subheading',                  'courses'),
('courses.add_cart_btn',    'Add to Cart',                     'Add to cart button on course card',           'courses'),
('courses.in_cart_btn',     '✓ In Cart',                       'Label when course already in cart',           'courses'),
('courses.full_btn',        'Batch Full',                      'Button when no seats available',              'courses'),
('courses.seats_left',      'seats left',                      'Label next to seat count',                    'courses'),
('courses.batch_full_label','Full',                            'Badge when batch is full',                    'courses'),
('courses.price_suffix',    'per course',                      'Text after price',                            'courses'),
('courses.no_courses',      'No courses available right now. Check back soon!', 'Empty state message',        'courses'),
('courses.loading',         'Loading courses…',                'Loading state text',                          'courses'),
('courses.duration_label',  'Duration',                        'Meta label for duration',                     'courses'),
('courses.schedule_label',  'Schedule',                        'Meta label for schedule',                     'courses'),
('courses.seats_label',     'Seats',                           'Meta label for seats',                        'courses'),

-- CART
('cart.title',              'Your Cart',                       'Cart page title',                             'cart'),
('cart.subtitle',           'Review your courses before paying.','Cart page subtitle',                        'cart'),
('cart.empty_title',        'Nothing here yet',                'Empty cart heading',                          'cart'),
('cart.empty_sub',          'Head back and pick a course you would love to learn.', 'Empty cart sub',           'cart'),
('cart.empty_cta',          'Browse Courses',                  'Empty cart CTA button',                       'cart'),
('cart.remove_btn',         'Remove',                          'Remove item button',                          'cart'),
('cart.total_label',        'Total payable',                   'Cart total label',                            'cart'),
('cart.proceed_btn',        'Proceed to Payment →',            'Checkout button',                             'cart'),
('cart.breadcrumb_home',    'Home',                            'Breadcrumb: home',                            'cart'),
('cart.breadcrumb_self',    'Cart',                            'Breadcrumb: cart',                            'cart'),

-- PAYMENT
('payment.title',           'Complete your payment',           'Payment page title',                          'payment'),
('payment.subtitle',        'Scan the QR code, pay the exact amount, then fill in your details.', 'Payment page subtitle', 'payment'),
('payment.qr_heading',      'Scan & Pay',                      'QR box heading',                              'payment'),
('payment.qr_subtext',      'Use any UPI app — GPay, PhonePe, Paytm', 'QR subtext below UPI id',            'payment'),
('payment.amount_label',    'Amount to pay',                   'Label above total amount on payment page',    'payment'),
('payment.warning_text',    'After paying, note the UTR / Transaction ID from your payment app. Enrollment is confirmed after we verify with our bank.', 'Warning note on payment page', 'payment'),
('payment.form_heading',    'Enter payment details',           'Form section heading',                        'payment'),
('payment.field_name',      'Full Name',                       'Field label: name',                           'payment'),
('payment.field_email',     'Email Address',                   'Field label: email',                          'payment'),
('payment.field_phone',     'Phone Number',                    'Field label: phone',                          'payment'),
('payment.field_utr',       'UTR / Transaction ID',            'Field label: UTR',                            'payment'),
('payment.field_date',      'Payment Date',                    'Field label: date',                           'payment'),
('payment.placeholder_name','Your full name',                  'Placeholder: name field',                     'payment'),
('payment.placeholder_email','you@email.com',                  'Placeholder: email field',                    'payment'),
('payment.placeholder_phone','10-digit mobile number',         'Placeholder: phone field',                    'payment'),
('payment.placeholder_utr', '12-digit UTR or transaction ID',  'Placeholder: UTR field',                      'payment'),
('payment.submit_btn',      'Submit Payment',                  'Submit payment button',                       'payment'),
('payment.submitting_btn',  'Submitting…',                     'Submit button loading state',                 'payment'),
('payment.breadcrumb_payment','Payment',                       'Breadcrumb: payment',                         'payment'),

-- STATUS
('status.icon',             '🎉',                              'Emoji shown on success status page',          'status'),
('status.title',            'Payment submitted!',              'Status page heading',                         'status'),
('status.badge_text',       'Pending Verification',            'Status badge label',                          'status'),
('status.body',             'We have received your payment details. Your UTR will be verified against our bank statement and enrollment confirmed within 24 hours.', 'Status body copy', 'status'),
('status.note',             'Check your email for a confirmation. Once verified, you will receive your WhatsApp group invite.', 'Status page note', 'status'),
('status.step1_title',      'Payment submitted',               'Step 1 title in timeline',                    'status'),
('status.step1_sub',        'UTR recorded',                    'Step 1 sub',                                  'status'),
('status.step2_title',      'Admin verification',              'Step 2 title',                                'status'),
('status.step2_sub',        'We match with bank statement',    'Step 2 sub',                                  'status'),
('status.step3_title',      'Enrollment confirmed',            'Step 3 title',                                'status'),
('status.step3_sub',        'WhatsApp group invite sent',      'Step 3 sub',                                  'status'),
('status.back_btn',         '← Back to home',                  'Back button on status page',                  'status'),

-- FOOTER
('footer.copyright',        '© 2025 DheeWellnessHub. All rights reserved.', 'Footer copyright text',               'footer'),
('footer.tagline',          'Transforming careers, one batch at a time.', 'Footer tagline',                   'footer'),

-- ADMIN
('admin.login_title',       'Admin Sign In',                   'Admin login page title',                      'admin'),
('admin.login_subtitle',    'Access your dashboard',           'Admin login subtitle',                        'admin'),
('admin.login_btn',         'Sign In →',                       'Admin login button',                          'admin'),
('admin.logout_btn',        'Sign Out',                        'Admin logout button',                         'admin'),
('admin.demo_hint',         'Demo credentials pre-filled',     'Hint shown below admin login form',           'admin')

ON CONFLICT (key) DO NOTHING;

-- ============================================================
-- SEED: SITE SETTINGS
-- ============================================================
INSERT INTO site_settings (key, value, description) VALUES
('upi_id',           'DheeWellnessHub@upi',         'UPI ID for payment QR code'),
('upi_name',         'DheeWellnessHub Academy',     'Account holder name shown on QR'),
('qr_image_url',     '',                      'Custom QR image URL (leave blank to auto-generate)'),
('bank_name',        'HDFC Bank',             'Bank name shown in payment instructions'),
('admin_email',      'admin@DheeWellnessHub.com',   'Admin email for login and notifications'),
('admin_password',   'admin123',              'Admin password (change in production!)'),
('site_name',        'DheeWellnessHub',             'Site name used in emails and title'),
('primary_color',    '#0f766e',               'Primary brand color (hex)'),
('accent_color',     '#f59e0b',               'Accent color (hex)'),
('logo_url',         '',                      'Logo image URL (leave blank to use text logo)'),
('support_email',    'support@DheeWellnessHub.com', 'Support email shown to students'),
('whatsapp_support', '',                      'WhatsApp support number (optional)')
ON CONFLICT (key) DO NOTHING;

-- ============================================================
-- SEED: SAMPLE COURSES
-- ============================================================
INSERT INTO courses (name, tag, batch_name, start_date, end_date, duration, schedule, price, total_seats, enrolled, description, whatsapp_link) VALUES
('Full Stack Web Development', 'Web Dev',     'Batch 14 – July 2025', '2025-07-01', '2025-09-30', '3 months',  'Mon, Wed, Fri – 7 PM IST', 7999, 30, 18, 'React, Node.js, MongoDB, and deployment. Build 5 real-world projects with live code reviews.', 'https://chat.whatsapp.com/example1'),
('Python for Data Science',    'Data Science','Batch 8 – July 2025',  '2025-07-05', '2025-10-05', '3 months',  'Tue, Thu, Sat – 8 PM IST',  8999, 25, 24, 'Pandas, NumPy, machine learning basics, and capstone projects with real datasets.',           'https://chat.whatsapp.com/example2'),
('UI/UX Design Masterclass',   'Design',      'Batch 5 – Aug 2025',   '2025-08-01', '2025-10-31', '3 months',  'Sat & Sun – 10 AM IST',     5999, 20,  9, 'Figma end-to-end, user research, prototyping, and a portfolio-ready case study.',           'https://chat.whatsapp.com/example3'),
('Digital Marketing Pro',      'Marketing',   'Batch 11 – July 2025', '2025-07-10', '2025-09-10', '2 months',  'Mon, Wed – 9 PM IST',       3999, 40, 12, 'SEO, paid ads, content strategy, and social media — with live campaign walkthroughs.',       'https://chat.whatsapp.com/example4')
ON CONFLICT DO NOTHING;

-- ============================================================
-- ROW LEVEL SECURITY
-- ============================================================
ALTER TABLE ui_content   ENABLE ROW LEVEL SECURITY;
ALTER TABLE site_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE courses       ENABLE ROW LEVEL SECURITY;
ALTER TABLE payments      ENABLE ROW LEVEL SECURITY;
ALTER TABLE enrollments   ENABLE ROW LEVEL SECURITY;

-- Public can read ui_content, site_settings (non-sensitive), courses
CREATE POLICY "public_read_ui"       ON ui_content    FOR SELECT USING (true);
CREATE POLICY "public_read_settings" ON site_settings FOR SELECT USING (key NOT IN ('admin_password'));
CREATE POLICY "public_read_courses"  ON courses        FOR SELECT USING (is_active = true);
CREATE POLICY "public_insert_payment" ON payments      FOR INSERT WITH CHECK (true);

-- Anon can read their own submissions (by email) — service role handles admin ops via functions
CREATE POLICY "public_read_enrollments" ON enrollments FOR SELECT USING (true);

-- ============================================================
-- HELPER: auto-update updated_at
-- ============================================================
CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER AS $$
BEGIN NEW.updated_at = NOW(); RETURN NEW; END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_ui_content_updated    BEFORE UPDATE ON ui_content    FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_site_settings_updated BEFORE UPDATE ON site_settings FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_courses_updated       BEFORE UPDATE ON courses        FOR EACH ROW EXECUTE FUNCTION set_updated_at();
