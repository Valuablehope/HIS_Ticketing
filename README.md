# HIS Ticketing

This repository contains a sample Supabase schema for a React-based ticketing application. The schema includes triggers that send Telegram bot notifications when:

- A ticket is created (notifying the submitter and all admins)
- A ticket status changes (notifying the submitter)
- A ticket is assigned (notifying the assignee)
- Submitters can include a screenshot URL with each ticket
- Support agents can leave closing feedback when resolving tickets

The SQL schema can be found in [`supabase/schema.sql`](supabase/schema.sql).

## Applying the schema

1. Create a project in [Supabase](https://supabase.com/).
2. Open the SQL editor and run the contents of `supabase/schema.sql`.
3. Set the `my.telegram_bot_token` configuration value with your bot token:

```sql
alter role authenticated set my.telegram_bot_token = '<TELEGRAM_BOT_TOKEN>';
```

4. Ensure each user record in `profiles` has a `telegram_chat_id` so notifications can be delivered.

Tickets include an optional `screenshot_url` column. Files can be uploaded to Supabase Storage and the public URL saved in this column. When closing a ticket, support agents can insert feedback into `ticket_closure_feedback` to store their resolution notes.

The front‑end can be implemented in React and hosted as static files (e.g., on GitHub Pages) while interacting with Supabase for authentication, data storage, and these server-side notifications.
