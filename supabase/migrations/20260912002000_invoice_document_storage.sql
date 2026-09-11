insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('comptaflow-documents', 'comptaflow-documents', false, 10485760, array['application/pdf']::text[])
on conflict (id) do update
set public = false,
    file_size_limit = 10485760,
    allowed_mime_types = array['application/pdf']::text[];

create policy "Comptaflow users can read own PDFs"
on storage.objects
for select
to authenticated
using (
  bucket_id = 'comptaflow-documents'
  and (storage.foldername(name))[1] = (select auth.uid()::text)
);

create policy "Comptaflow users can upload own PDFs"
on storage.objects
for insert
to authenticated
with check (
  bucket_id = 'comptaflow-documents'
  and (storage.foldername(name))[1] = (select auth.uid()::text)
  and lower(storage.extension(name)) = 'pdf'
);

create policy "Comptaflow users can update own PDFs"
on storage.objects
for update
to authenticated
using (
  bucket_id = 'comptaflow-documents'
  and (storage.foldername(name))[1] = (select auth.uid()::text)
)
with check (
  bucket_id = 'comptaflow-documents'
  and (storage.foldername(name))[1] = (select auth.uid()::text)
  and lower(storage.extension(name)) = 'pdf'
);

create policy "Comptaflow users can delete own PDFs"
on storage.objects
for delete
to authenticated
using (
  bucket_id = 'comptaflow-documents'
  and (storage.foldername(name))[1] = (select auth.uid()::text)
);
