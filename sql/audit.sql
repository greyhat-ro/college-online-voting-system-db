-- ==========================================
-- AUDIT LOGGING
-- ==========================================

alter table public.audit_logs enable row level security;


-- ==========================================
-- CREATE AUDIT LOG FUNCTION
-- ==========================================

create or replace function public.create_audit_log(
    p_action text,
    p_entity_type text,
    p_entity_id text default null,
    p_metadata jsonb default '{}'::jsonb
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin

    insert into public.audit_logs (
        actor_id,
        action,
        entity_type,
        entity_id,
        metadata
    )
    values (
        auth.uid(),
        p_action,
        p_entity_type,
        p_entity_id,
        p_metadata
    );

end;
$$;


-- ==========================================
-- ADMIN READ ACCESS
-- ==========================================

drop policy if exists "Only admins can view audit logs"
on public.audit_logs;


create policy "Only admins can view audit logs"
on public.audit_logs
for select
to authenticated
using (
    public.is_admin()
);


-- ==========================================
-- FUNCTION SECURITY
-- ==========================================

revoke execute on function public.create_audit_log(
    text,
    text,
    text,
    jsonb
) from public;


grant execute on function public.create_audit_log(
    text,
    text,
    text,
    jsonb
) to authenticated;
