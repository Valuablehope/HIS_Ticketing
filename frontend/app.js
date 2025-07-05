const SUPABASE_URL = 'https://dblxeucudkgmwmvqlyep.supabase.co';
const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRibHhldWN1ZGtnbXdtdnFseWVwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTE3NDI4NzEsImV4cCI6MjA2NzMxODg3MX0.hKQ4GhGNG8BhSUBBqXQU80CaWtjociPpsevF_kSfdgA';

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
    div.innerHTML = `<h2>${t.title}</h2><p>${t.description}</p>`;

    if (t.screenshot_url) {
      const img = document.createElement('img');
      img.src = t.screenshot_url;
      img.alt = `${t.title} screenshot`;
      div.appendChild(img);
    }

    container.appendChild(div);
  });
}

document.addEventListener('DOMContentLoaded', loadTickets);
