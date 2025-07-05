const SUPABASE_URL = 'YOUR_SUPABASE_URL';
const SUPABASE_ANON_KEY = 'YOUR_SUPABASE_ANON_KEY';

const supabase = supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

async function loadTickets() {
  const { data: tickets, error } = await supabase
    .from('tickets')
    .select('*')
    .order('created_at', { ascending: false });

  const container = document.getElementById('tickets');
  container.innerHTML = '';

  if (error) {
    container.textContent = 'Error loading tickets';
    return;
  }

  tickets.forEach(t => {
    const div = document.createElement('div');
    div.className = 'ticket';
    div.innerHTML = `<strong>${t.title}</strong><p>${t.description}</p>`;
    container.appendChild(div);
  });
}

document.addEventListener('DOMContentLoaded', loadTickets);
