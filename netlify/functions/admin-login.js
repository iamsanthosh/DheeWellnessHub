// netlify/functions/admin-login.js
const { createClient } = require('@supabase/supabase-js');

const supabase = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_SERVICE_KEY
);

exports.handler = async (event) => {
  const headers = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'Content-Type',
    'Content-Type': 'application/json',
  };
  if (event.httpMethod === 'OPTIONS') return { statusCode: 200, headers, body: '' };
  if (event.httpMethod !== 'POST') return { statusCode: 405, headers, body: '' };

  try {
    const { email, password } = JSON.parse(event.body);

    const [emailRes, passRes] = await Promise.all([
      supabase.from('site_settings').select('value').eq('key', 'admin_email').single(),
      supabase.from('site_settings').select('value').eq('key', 'admin_password').single(),
    ]);

    if (emailRes.error || passRes.error) throw new Error('Config error');

    if (email !== emailRes.data.value || password !== passRes.data.value) {
      return { statusCode: 401, headers, body: JSON.stringify({ error: 'Invalid credentials' }) };
    }

    // Simple token — in production use Supabase Auth or JWT
    const token = Buffer.from(`${email}:${Date.now()}`).toString('base64');
    return { statusCode: 200, headers, body: JSON.stringify({ success: true, token }) };
  } catch (err) {
    return { statusCode: 500, headers, body: JSON.stringify({ error: err.message }) };
  }
};
