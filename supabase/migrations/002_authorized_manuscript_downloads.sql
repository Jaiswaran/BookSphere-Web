-- Allow full manuscript downloads only for the author, free books, or readers
-- who have a library entry (purchase/access record).
drop policy if exists "manuscript owner read" on storage.objects;
drop policy if exists "authorized manuscript read" on storage.objects;
create policy "authorized manuscript read"
on storage.objects for select to authenticated
using (
  bucket_id = 'manuscripts'
  and exists (
    select 1
    from public.books b
    where b.manuscript_path = storage.objects.name
      and b.status = 'PUBLISHED'
      and (
        b.author_id = (select auth.uid())
        or b.is_free = true
        or exists (
          select 1 from public.library l
          where l.book_id = b.id and l.user_id = (select auth.uid())
        )
      )
  )
);
