# BookSphere Web

A responsive web rebuild of the BookSphere reading marketplace.

## Features
- Supabase email/password authentication and persistent sessions
- Reader and Author roles
- Discover catalog from Supabase
- 2–3 page free preview for paid books
- Full online reading for free books and purchased books
- Browser PDF page rendering with page 1 included
- Author PDF + cover upload
- Automatic preview PDF generation from the selected preview page count
- Library and reading progress
- Demo checkout with a 70/30 author/BookSphere revenue split
- Profile and reading lists
- Responsive desktop/tablet/mobile UI

## Setup
1. Copy `.env.example` to `.env.local`.
2. Add your Supabase Project URL and publishable key.
3. Run the SQL in `supabase/migrations/001_booksphere_web.sql`.
4. `npm install`
5. `npm run dev`

Never put a Supabase service-role/secret key in frontend environment variables.
