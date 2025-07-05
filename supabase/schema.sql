-- Database schema for HIS Ticketing

-- Table: tickets
create table if not exists tickets (
    id serial primary key,
    title text not null,
    description text,
    status text default 'open',
    assigned_to text,
    created_at timestamp with time zone default now(),
    updated_at timestamp with time zone default now()
);

-- Ensure screenshot_url column exists
alter table tickets add column if not exists screenshot_url text;

-- Function to update updated_at timestamp
create or replace function update_timestamp()
returns trigger as $$
begin
    new.updated_at = now();
    return new;
end;
$$ language plpgsql;

-- Trigger: trg_ticket_after_insert

-- Drop existing trigger if present
 drop trigger if exists trg_ticket_after_insert on tickets;
create trigger trg_ticket_after_insert
before insert on tickets
for each row execute procedure update_timestamp();

-- Trigger: trg_ticket_status_change

-- Drop existing trigger if present
 drop trigger if exists trg_ticket_status_change on tickets;
create trigger trg_ticket_status_change
before update of status on tickets
for each row execute procedure update_timestamp();

-- Trigger: trg_ticket_assigned

-- Drop existing trigger if present
 drop trigger if exists trg_ticket_assigned on tickets;
create trigger trg_ticket_assigned
before update of assigned_to on tickets
for each row execute procedure update_timestamp();
