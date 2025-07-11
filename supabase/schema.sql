
-- Supabase schema for ticketing app with Telegram notifications
-- This file defines tables, indexes, and triggers
-- to send Telegram bot notifications when tickets are
-- created, updated, or assigned.

-- Extension required for HTTP requests

create extension if not exists http with schema extensions;

-- Profiles table stores user info and telegram chat id
create table if not exists profiles (
    id uuid primary key references auth.users(id) on delete cascade,
    full_name text,
    role text default 'user', -- 'user' or 'admin'
    telegram_chat_id text,
    created_at timestamp with time zone default now()
);

-- Tickets table
create table if not exists tickets (
    id uuid primary key default uuid_generate_v4(),
    title text not null,
    description text,
    screenshot_url text,
    status text not null default 'open',
    priority text,
    submitter_id uuid references profiles(id) on delete set null,
    assignee_id uuid references profiles(id) on delete set null,
    inserted_at timestamp with time zone default now(),
    updated_at timestamp with time zone default now()
);

create index if not exists idx_tickets_submitter on tickets(submitter_id);
create index if not exists idx_tickets_assignee  on tickets(assignee_id);
create index if not exists idx_tickets_status    on tickets(status);

create index if not exists tickets_submitter_idx on tickets(submitter_id);
create index if not exists tickets_assignee_idx on tickets(assignee_id);
create index if not exists tickets_status_idx on tickets(status);

-- Status history table
create table if not exists ticket_status_history (
    id bigserial primary key,
    ticket_id uuid references tickets(id) on delete cascade,
    from_status text,
    to_status text,
    changed_by uuid references profiles(id),
    changed_at timestamp with time zone default now()
);

-- Assignment history table
create table if not exists ticket_assignments (
    id bigserial primary key,
    ticket_id uuid references tickets(id) on delete cascade,
    assignee_id uuid references profiles(id),
    assigned_by uuid references profiles(id),
    assigned_at timestamp with time zone default now()
);

-- Function to post messages to Telegram
create or replace function notify_telegram(chat_id text, message text)
returns void language plpgsql as $$
declare
    resp json;
    bot_token text := current_setting('my.telegram_bot_token', true);
begin
    if chat_id is null then
        return;
    end if;
    if bot_token is null then
        raise notice 'Telegram bot token not configured';
        return;
    end if;
    select content into resp
    from http_post(
        format('https://api.telegram.org/bot%s/sendMessage', bot_token),
        json_build_object('chat_id', chat_id, 'text', message)::text,
        'application/json'
    );
end;
$$;

-- 4.2 Keep updated_at fresh
create or replace function fn_update_timestamp()
returns trigger language plpgsql as $$
begin
    new.updated_at := now();
    return new;
end;
$$;

-- Trigger function after ticket insert

-- Trigger function after ticket insert
create or replace function trg_ticket_after_insert()
returns trigger language plpgsql as $$
declare
    admin_rec record;
    submit_chat text;
begin
    select telegram_chat_id into submit_chat from profiles where id = new.submitter_id;
    perform notify_telegram(submit_chat, 'Ticket created: ' || new.title);

    for admin_rec in select telegram_chat_id from profiles where role = 'admin' loop
        perform notify_telegram(admin_rec.telegram_chat_id, 'New ticket submitted: ' || new.title);
    end loop;
    return new;
end;
$$;

create trigger trg_ticket_after_insert
after insert on tickets
for each row execute procedure trg_ticket_after_insert();

-- 5.2 AFTER UPDATE OF status: log history + notify submitter


-- Trigger for status change
create or replace function trg_ticket_status_change()
returns trigger language plpgsql as $$
declare
    submit_chat text;
begin
    if new.status is distinct from old.status then
        insert into ticket_status_history(ticket_id, from_status, to_status, changed_by)
        values (old.id, old.status, new.status, new.assignee_id);

        select telegram_chat_id into submit_chat from profiles where id = new.submitter_id;
        perform notify_telegram(submit_chat,
          'Status of ticket "' || new.title || '" changed to ' || new.status
        );

        perform notify_telegram(submit_chat, 'Status of ticket ' || new.title || ' changed to ' || new.status);
    end if;
    return new;
end;
$$;

create trigger trg_ticket_status_change
after update of status on tickets
for each row execute procedure trg_ticket_status_change();

-- 5.3 AFTER UPDATE OF assignee_id: log assignment + notify new assignee
-- Trigger for assignment change
create or replace function trg_ticket_assigned()
returns trigger language plpgsql as $$
declare
    assignee_chat text;
begin
    if new.assignee_id is distinct from old.assignee_id then
        insert into ticket_assignments(ticket_id, assignee_id, assigned_by)
        values (new.id, new.assignee_id, auth.uid()::uuid);
        select telegram_chat_id into assignee_chat from profiles where id = new.assignee_id;
        perform notify_telegram(assignee_chat, 'You have been assigned ticket: ' || new.title);
    end if;
    return new;
end;
$$;

-- 6. Trigger Creation
drop trigger if exists trg_update_timestamp on tickets;
create trigger trg_update_timestamp
before update on tickets
for each row execute procedure fn_update_timestamp();

drop trigger if exists tr_after_insert_tickets on tickets;
create trigger tr_after_insert_tickets
after insert on tickets
for each row execute procedure trg_ticket_after_insert();

drop trigger if exists tr_after_status_tickets on tickets;
create trigger tr_after_status_tickets
after update of status on tickets
for each row execute procedure trg_ticket_status_change();

drop trigger if exists tr_after_assign_tickets on tickets;
create trigger tr_after_assign_tickets
after update of assignee_id on tickets
for each row execute procedure trg_ticket_assigned();

-- Enable RLS and basic policies
alter table profiles enable row level security;
create policy policy_profiles_self_select
  on profiles for select
  using ( auth.uid() = id );

alter table tickets enable row level security;
create policy policy_tickets_access
  on tickets for select
  using ( auth.uid() = submitter_id or auth.uid() = assignee_id );

alter table ticket_status_history enable row level security;
create policy policy_status_history_access
  on ticket_status_history for select
  using (
    auth.uid() = (select submitter_id from tickets where id = ticket_status_history.ticket_id)
    or
    auth.uid() = (select assignee_id  from tickets where id = ticket_status_history.ticket_id)
  );

alter table ticket_assignments enable row level security;
create policy policy_assignments_access
  on ticket_assignments for select
  using (
    auth.uid() = (select submitter_id from tickets where id = ticket_assignments.ticket_id)
    or
    auth.uid() = (select assignee_id from tickets where id = ticket_assignments.ticket_id)
  );

-- Index history tables
create index if not exists idx_status_history_ticket on ticket_status_history(ticket_id);
create index if not exists idx_assignments_ticket on ticket_assignments(ticket_id);

