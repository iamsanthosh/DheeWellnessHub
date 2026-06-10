// netlify/functions/admin-data.js
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

  // Simple token check
  const token = event.headers['x-admin-token'];
  if (!token) return { statusCode: 401, headers, body: JSON.stringify({ error: 'Unauthorized' }) };

  try {
    const [paymentsRes, coursesRes, enrollmentsRes, uiRes, settingsRes] = await Promise.all([
      supabase.from('payments').select('*').order('submitted_at', { ascending: false }),
      supabase.from('courses').select('*').order('created_at'),
      supabase.from('enrollments').select('*').order('enrolled_at', { ascending: false }),
      supabase.from('ui_content').select('*').order('section,key'),
      supabase.from('site_settings').select('*').order('key'),
    ]);

    return {
      statusCode: 200,
      headers,
      body: JSON.stringify({
        payments: paymentsRes.data || [],
        courses: coursesRes.data || [],
        enrollments: enrollmentsRes.data || [],
        ui: uiRes.data || [],
        settings: settingsRes.data || [],
      }),
    };
  } catch (err) {
    return { statusCode: 500, headers, body: JSON.stringify({ error: err.message }) };
  }
};
