// app.js

// ── Replace these with your real values ───────────────────────────────────────
const SUPABASE_URL      = 'https://zwiceccrwxwksiultqbf.supabase.co';
const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inp3aWNlY2Nyd3h3a3NpdWx0cWJmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTE3NDYyMDksImV4cCI6MjA2NzMyMjIwOX0.hnjHEV8vUePzzOWJnkWzBfHJn5ItcItJqNmiLgKpKoQ';
// ─────────────────────────────────────────────────────────────────────────────

// Instantiate the client
const supabaseClient = supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

async function loadTickets() {
  const container = document.getElementById('tickets');
  container.innerHTML = '';  // clear out old content

  // Order by the actual timestamp column (inserted_at), not `created_at`
  const { data: tickets, error } = await supabaseClient
    .from('tickets')
    .select('*')
    .order('inserted_at', { ascending: false });

  if (error) {
    console.error('Error loading tickets:', error);
    container.textContent = `Error loading tickets: ${error.message}`;
    return;
  }

  if (!tickets || tickets.length === 0) {
    container.textContent = 'No tickets found.';
    return;
  }

  tickets.forEach(ticket => {
    const card = document.createElement('div');
    card.className = 'ticket';

    const title = document.createElement('h2');
    title.textContent = ticket.title;
    card.appendChild(title);

    const desc = document.createElement('p');
    desc.textContent = ticket.description || '(no description)';
    card.appendChild(desc);

    if (ticket.screenshot_url) {
      const img = document.createElement('img');
      img.src = ticket.screenshot_url;
      img.alt = 'Ticket screenshot';
      img.className = 'screenshot';
      card.appendChild(img);
    }

    // Show when it was created
    const ts = document.createElement('small');
    ts.textContent = new Date(ticket.inserted_at).toLocaleString();
    card.appendChild(ts);

    container.appendChild(card);
  });
}

document.addEventListener('DOMContentLoaded', loadTickets);