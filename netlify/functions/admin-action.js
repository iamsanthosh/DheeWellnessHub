// netlify/functions/admin-action.js
// Single endpoint for all admin mutations
// body: { action, payload }

const { createClient } = require('@supabase/supabase-js');

const supabase = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_SERVICE_KEY
);

exports.handler = async (event) => {
  const headers = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'Content-Type, x-admin-token',
    'Content-Type': 'application/json',
  };
  if (event.httpMethod === 'OPTIONS') return { statusCode: 200, headers, body: '' };
  if (event.httpMethod !== 'POST') return { statusCode: 405, headers, body: '' };

  const token = event.headers['x-admin-token'];
  if (!token) return { statusCode: 401, headers, body: JSON.stringify({ error: 'Unauthorized' }) };

  try {
    const { action, payload } = JSON.parse(event.body);

    // ── PAYMENT: VERIFY ──
    if (action === 'verify_payment') {
      const { id } = payload;
      const { data: payment, error: pErr } = await supabase
        .from('payments').select('*').eq('id', id).single();
      if (pErr) throw pErr;

      await supabase.from('payments').update({ status: 'verified', verified_at: new Date().toISOString() }).eq('id', id);

      // Create enrollment records per course
      if (payment.course_ids && payment.course_ids.length > 0) {
        const { data: courseData } = await supabase.from('courses').select('id,name,whatsapp_link').in('id', payment.course_ids);
        const enrollments = (courseData || []).map(c => ({
          payment_id: id,
          student_name: payment.student_name,
          email: payment.email,
          phone: payment.phone,
          course_id: c.id,
          course_name: c.name,
          whatsapp_link: c.whatsapp_link,
        }));
        if (enrollments.length) await supabase.from('enrollments').insert(enrollments);

        // Increment enrolled count
        for (const c of courseData || []) {
          await supabase.rpc('increment_enrolled', { course_id: c.id }).catch(() =>
            supabase.from('courses').update({ enrolled: (c.enrolled || 0) + 1 }).eq('id', c.id)
          );
        }
      }
      return { statusCode: 200, headers, body: JSON.stringify({ success: true }) };
    }

    // ── PAYMENT: REJECT ──
    if (action === 'reject_payment') {
      const { id, note } = payload;
      await supabase.from('payments').update({ status: 'rejected', rejected_at: new Date().toISOString(), admin_note: note || '' }).eq('id', id);
      return { statusCode: 200, headers, body: JSON.stringify({ success: true }) };
    }

    // ── COURSE: CREATE ──
    if (action === 'create_course') {
      const { data, error } = await supabase.from('courses').insert(payload).select().single();
      if (error) throw error;
      return { statusCode: 200, headers, body: JSON.stringify({ success: true, course: data }) };
    }

    // ── COURSE: UPDATE ──
    if (action === 'update_course') {
      const { id, ...fields } = payload;
      const { data, error } = await supabase.from('courses').update(fields).eq('id', id).select().single();
      if (error) throw error;
      return { statusCode: 200, headers, body: JSON.stringify({ success: true, course: data }) };
    }

    // ── COURSE: DELETE ──
    if (action === 'delete_course') {
      const { id } = payload;
      await supabase.from('courses').update({ is_active: false }).eq('id', id);
      return { statusCode: 200, headers, body: JSON.stringify({ success: true }) };
    }

    // ── UI CONTENT: UPDATE SINGLE KEY ──
    if (action === 'update_ui') {
      const { key, value } = payload;
      const { error } = await supabase.from('ui_content').update({ value }).eq('key', key);
      if (error) throw error;
      return { statusCode: 200, headers, body: JSON.stringify({ success: true }) };
    }

    // ── UI CONTENT: BULK UPDATE ──
    if (action === 'bulk_update_ui') {
      const { updates } = payload; // [{ key, value }, ...]
      for (const u of updates) {
        await supabase.from('ui_content').update({ value: u.value }).eq('key', u.key);
      }
      return { statusCode: 200, headers, body: JSON.stringify({ success: true }) };
    }

    // ── SETTINGS: UPDATE ──
    if (action === 'update_setting') {
      const { key, value } = payload;
      const { error } = await supabase.from('site_settings').update({ value }).eq('key', key);
      if (error) throw error;
      return { statusCode: 200, headers, body: JSON.stringify({ success: true }) };
    }

    // ── SETTINGS: BULK UPDATE ──
    if (action === 'bulk_update_settings') {
      const { updates } = payload;
      for (const u of updates) {
        await supabase.from('site_settings').update({ value: u.value }).eq('key', u.key);
      }
      return { statusCode: 200, headers, body: JSON.stringify({ success: true }) };
    }

    return { statusCode: 400, headers, body: JSON.stringify({ error: 'Unknown action' }) };
  } catch (err) {
    console.error('admin-action error:', err);
    return { statusCode: 500, headers, body: JSON.stringify({ error: err.message }) };
  }
};
