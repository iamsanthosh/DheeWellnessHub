// netlify/functions/public-data.js
// Returns all UI content, public settings, and active courses in one call
// Called on every page load — keeps frontend fast with a single round-trip

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

  try {
    const [uiRes, settingsRes, coursesRes] = await Promise.all([
      supabase.from('ui_content').select('key,value').order('section'),
      supabase.from('site_settings').select('key,value').not('key', 'eq', 'admin_password'),
      supabase.from('courses').select('*').eq('is_active', true).order('created_at'),
    ]);

    if (uiRes.error)       throw uiRes.error;
    if (settingsRes.error) throw settingsRes.error;
    if (coursesRes.error)  throw coursesRes.error;

    // Convert arrays to key→value maps for easy frontend use
    const ui = Object.fromEntries(uiRes.data.map(r => [r.key, r.value]));
    const settings = Object.fromEntries(settingsRes.data.map(r => [r.key, r.value]));

    return {
      statusCode: 200,
      headers,
      body: JSON.stringify({ ui, settings, courses: coursesRes.data }),
    };
  } catch (err) {
    console.error('public-data error:', err);
    return { statusCode: 500, headers, body: JSON.stringify({ error: err.message }) };
  }
};
