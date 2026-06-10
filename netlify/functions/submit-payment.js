// netlify/functions/submit-payment.js
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
  if (event.httpMethod !== 'POST') return { statusCode: 405, headers, body: 'Method not allowed' };

  try {
    const body = JSON.parse(event.body);
    const { student_name, email, phone, utr, payment_date, amount, course_ids, course_names } = body;

    // Basic validation
    if (!student_name || !email || !phone || !utr || !payment_date || !amount) {
      return { statusCode: 400, headers, body: JSON.stringify({ error: 'Missing required fields' }) };
    }
    if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) {
      return { statusCode: 400, headers, body: JSON.stringify({ error: 'Invalid email' }) };
    }

    // Check for duplicate UTR
    const { data: existing } = await supabase.from('payments').select('id').eq('utr', utr).single();
    if (existing) {
      return { statusCode: 409, headers, body: JSON.stringify({ error: 'This UTR has already been submitted.' }) };
    }

    const { data, error } = await supabase.from('payments').insert({
      student_name, email, phone, utr, payment_date,
      amount, course_ids, course_names, status: 'pending',
    }).select().single();

    if (error) throw error;

    return { statusCode: 200, headers, body: JSON.stringify({ success: true, payment_id: data.id }) };
  } catch (err) {
    console.error('submit-payment error:', err);
    return { statusCode: 500, headers, body: JSON.stringify({ error: err.message }) };
  }
};
