-- ====================================================================
-- THE KRISHA ARCHIVE — DATABASE SCHEMA (schema.sql)
-- Description: Fully normalized PostgreSQL schema design for Supabase
-- Scopes: AES-256 client-side encrypted fields, complete RLS, automatic timeline updates
-- ====================================================================

-- Enable UUID extension
create extension if not exists "uuid-ossp";

-- --------------------------------------------------------------------
-- 0. Core Audit Triggers & Functions
-- --------------------------------------------------------------------

-- Unified Updated At Column Auto-Update Trigger function
create or replace function update_updated_at_column()
returns trigger as $$
begin
    new.updated_at = timezone('utc'::text, now());
    return new;
end;
$$ language plpgsql;

-- --------------------------------------------------------------------
-- 1. Profiles (Main accounts linked directly to auth.users)
-- --------------------------------------------------------------------
create table public.profiles (
    id uuid references auth.users on delete cascade primary key,
    first_name text,
    last_name text,
    vault_salt text not null, -- Unique 32-byte salt generated client-side for PBKDF2
    created_at timestamp with time zone default timezone('utc'::text, now()) not null,
    updated_at timestamp with time zone default timezone('utc'::text, now()) not null,
    deleted_at timestamp with time zone
);

alter table public.profiles enable row level security;

create policy "Users can view and update their own profile"
    on public.profiles for all
    using (auth.uid() = id)
    with check (auth.uid() = id);

create trigger handle_updated_at_profiles
    before update on public.profiles
    for each row execute procedure update_updated_at_column();

-- --------------------------------------------------------------------
-- 2. Partner Profiles (Complete details about Krisha)
-- --------------------------------------------------------------------
create table public.partner_profiles (
    id uuid primary key default gen_random_uuid(),
    user_id uuid references public.profiles(id) on delete cascade unique not null,
    full_name text not null,
    nicknames text[] default '{}'::text[],
    birthday date,
    zodiac_sign text,
    favorite_color text,
    favorite_flower text,
    favorite_animal text,
    favorite_food text,
    favorite_drink text,
    favorite_perfume text,
    favorite_brands text[] default '{}'::text[],
    favorite_clothing_styles text[] default '{}'::text[],
    shoe_size text,
    ring_size text,
    hobbies text[] default '{}'::text[],
    dreams text[] default '{}'::text[],
    goals text[] default '{}'::text[],
    bucket_list text[] default '{}'::text[],
    fears text[] default '{}'::text[],
    insecurities text[] default '{}'::text[],
    strengths text[] default '{}'::text[],
    weaknesses text[] default '{}'::text[],
    personality_notes text,
    created_at timestamp with time zone default timezone('utc'::text, now()) not null,
    updated_at timestamp with time zone default timezone('utc'::text, now()) not null,
    deleted_at timestamp with time zone
);

alter table public.partner_profiles enable row level security;

create policy "Users can read and write their own partner profile"
    on public.partner_profiles for all
    using (auth.uid() = user_id)
    with check (auth.uid() = user_id);

create trigger handle_updated_at_partner_profiles
    before update on public.partner_profiles
    for each row execute procedure update_updated_at_column();

-- --------------------------------------------------------------------
-- 3. Cipher Vault (Encrypted Password Manager)
-- --------------------------------------------------------------------
create table public.cipher_vault (
    id uuid primary key default gen_random_uuid(),
    user_id uuid references public.profiles(id) on delete cascade not null,
    platform_name text not null, 
    website_url text,
    username_email text,                  -- Plaintext for easy search
    encrypted_password text not null,     -- Client-side AES-256 encrypted
    recovery_email text,                  -- Plaintext/Encrypted
    security_questions text,              -- Client-side AES-256 encrypted JSON string
    notes text,                           -- Client-side AES-256 encrypted
    created_at timestamp with time zone default timezone('utc'::text, now()) not null,
    updated_at timestamp with time zone default timezone('utc'::text, now()) not null,
    deleted_at timestamp with time zone
);

alter table public.cipher_vault enable row level security;

create policy "Users can perform CRUD on their own cipher vault"
    on public.cipher_vault for all
    using (auth.uid() = user_id)
    with check (auth.uid() = user_id);

create index idx_cipher_vault_user_id on public.cipher_vault (user_id);
create trigger handle_updated_at_cipher_vault
    before update on public.cipher_vault
    for each row execute procedure update_updated_at_column();

-- --------------------------------------------------------------------
-- 4. Love Language Tracker
-- --------------------------------------------------------------------
create table public.love_languages (
    id uuid primary key default gen_random_uuid(),
    user_id uuid references public.profiles(id) on delete cascade not null,
    category text not null,               -- 'service', 'quality_time', 'words', 'touch', 'gifts'
    what_works text[] default '{}'::text[],
    what_doesnt text[] default '{}'::text[],
    historical_success_rate numeric default 100.0,
    notes text,
    examples text[] default '{}'::text[],
    created_at timestamp with time zone default timezone('utc'::text, now()) not null,
    updated_at timestamp with time zone default timezone('utc'::text, now()) not null,
    deleted_at timestamp with time zone
);

alter table public.love_languages enable row level security;

create policy "Users can perform CRUD on love languages"
    on public.love_languages for all
    using (auth.uid() = user_id)
    with check (auth.uid() = user_id);

create index idx_love_languages_user_id on public.love_languages (user_id);
create trigger handle_updated_at_love_languages
    before update on public.love_languages
    for each row execute procedure update_updated_at_column();

-- --------------------------------------------------------------------
-- 5. Comfort Guidelines & Calming Techniques
-- --------------------------------------------------------------------
create table public.comfort_guidelines (
    id uuid primary key default gen_random_uuid(),
    user_id uuid references public.profiles(id) on delete cascade not null,
    comfort_type text not null,           -- 'comfort_her' or 'calm_her'
    trigger text not null,
    symptoms text[] default '{}'::text[],
    severity text,                        -- 'low', 'medium', 'high', 'critical'
    action_steps text[] default '{}'::text[],
    recommended_responses text[] default '{}'::text[],
    things_to_avoid text[] default '{}'::text[],
    success_rating numeric,
    messages_to_send text[] default '{}'::text[],
    physical_methods text[] default '{}'::text[],
    follow_up_actions text[] default '{}'::text[],
    created_at timestamp with time zone default timezone('utc'::text, now()) not null,
    updated_at timestamp with time zone default timezone('utc'::text, now()) not null,
    deleted_at timestamp with time zone
);

alter table public.comfort_guidelines enable row level security;

create policy "Users can perform CRUD on comfort guidelines"
    on public.comfort_guidelines for all
    using (auth.uid() = user_id)
    with check (auth.uid() = user_id);

create index idx_comfort_guidelines_user_id on public.comfort_guidelines (user_id);
create trigger handle_updated_at_comfort_guidelines
    before update on public.comfort_guidelines
    for each row execute procedure update_updated_at_column();

-- --------------------------------------------------------------------
-- 6. Preference Database
--------------------------------------------------------------------
create table public.preferences (
    id uuid primary key default gen_random_uuid(),
    user_id uuid references public.profiles(id) on delete cascade not null,
    category text not null,               -- Food, Snacks, Perfumes, Books, etc.
    item_name text not null,
    rating integer check (rating >= 1 and rating <= 5),
    priority text,                        -- 'high', 'medium', 'low'
    notes text,
    created_at timestamp with time zone default timezone('utc'::text, now()) not null,
    updated_at timestamp with time zone default timezone('utc'::text, now()) not null,
    deleted_at timestamp with time zone
);

alter table public.preferences enable row level security;

create policy "Users can perform CRUD on preferences"
    on public.preferences for all
    using (auth.uid() = user_id)
    with check (auth.uid() = user_id);

create index idx_preferences_user_id on public.preferences (user_id);
create index idx_preferences_category on public.preferences (user_id, category);
create trigger handle_updated_at_preferences
    before update on public.preferences
    for each row execute procedure update_updated_at_column();

-- --------------------------------------------------------------------
-- 7. Memories & Stories Archive
-- --------------------------------------------------------------------
create table public.memories (
    id uuid primary key default gen_random_uuid(),
    user_id uuid references public.profiles(id) on delete cascade not null,
    title text not null,
    story text not null,
    memory_date timestamp with time zone not null,
    location text,
    mood text,
    importance_score integer check (importance_score >= 1 and importance_score <= 10),
    tags text[] default '{}'::text[],
    created_at timestamp with time zone default timezone('utc'::text, now()) not null,
    updated_at timestamp with time zone default timezone('utc'::text, now()) not null,
    deleted_at timestamp with time zone
);

alter table public.memories enable row level security;

create policy "Users can perform CRUD on memories"
    on public.memories for all
    using (auth.uid() = user_id)
    with check (auth.uid() = user_id);

create index idx_memories_user_id on public.memories (user_id);
create index idx_memories_date on public.memories (user_id, memory_date desc);
create trigger handle_updated_at_memories
    before update on public.memories
    for each row execute procedure update_updated_at_column();

-- --------------------------------------------------------------------
-- 8. Media Archive
-- --------------------------------------------------------------------
create table public.media_archive (
    id uuid primary key default gen_random_uuid(),
    user_id uuid references public.profiles(id) on delete cascade not null,
    memory_id uuid references public.memories(id) on delete set null,
    storage_path text not null,           -- Reference to Supabase Storage Bucket File
    media_type text not null,             -- 'image', 'video', 'voice_note', 'document'
    album_name text,
    tags text[] default '{}'::text[],
    created_at timestamp with time zone default timezone('utc'::text, now()) not null,
    updated_at timestamp with time zone default timezone('utc'::text, now()) not null,
    deleted_at timestamp with time zone
);

alter table public.media_archive enable row level security;

create policy "Users can perform CRUD on media items"
    on public.media_archive for all
    using (auth.uid() = user_id)
    with check (auth.uid() = user_id);

create index idx_media_archive_user_id on public.media_archive (user_id);
create index idx_media_archive_memory_id on public.media_archive (memory_id);
create trigger handle_updated_at_media_archive
    before update on public.media_archive
    for each row execute procedure update_updated_at_column();

-- --------------------------------------------------------------------
-- 9. Relationship Events (Tracker & Countdowns)
-- --------------------------------------------------------------------
create table public.relationship_events (
    id uuid primary key default gen_random_uuid(),
    user_id uuid references public.profiles(id) on delete cascade not null,
    title text not null,
    event_date timestamp with time zone not null,
    event_type text not null,             -- 'anniversary', 'monthsary', 'birthday', 'first_meeting', 'first_call', 'first_date', 'first_gift', 'first_kiss', 'custom'
    countdown_enabled boolean default true,
    created_at timestamp with time zone default timezone('utc'::text, now()) not null,
    updated_at timestamp with time zone default timezone('utc'::text, now()) not null,
    deleted_at timestamp with time zone
);

alter table public.relationship_events enable row level security;

create policy "Users can perform CRUD on relationship events"
    on public.relationship_events for all
    using (auth.uid() = user_id)
    with check (auth.uid() = user_id);

create index idx_rel_events_user_id on public.relationship_events (user_id);
create trigger handle_updated_at_relationship_events
    before update on public.relationship_events
    for each row execute procedure update_updated_at_column();

-- --------------------------------------------------------------------
-- 10. Period Tracker
-- --------------------------------------------------------------------
create table public.period_records (
    id uuid primary key default gen_random_uuid(),
    user_id uuid references public.profiles(id) on delete cascade not null,
    start_date date not null,
    end_date date,
    symptoms text[] default '{}'::text[],
    mood text,
    flow_level text,                      -- 'spotted', 'light', 'medium', 'heavy'
    pain_level text,                      -- 'none', 'mild', 'moderate', 'severe'
    notes text,
    created_at timestamp with time zone default timezone('utc'::text, now()) not null,
    updated_at timestamp with time zone default timezone('utc'::text, now()) not null,
    deleted_at timestamp with time zone
);

alter table public.period_records enable row level security;

create policy "Users can perform CRUD on period records"
    on public.period_records for all
    using (auth.uid() = user_id)
    with check (auth.uid() = user_id);

create index idx_period_records_user_id on public.period_records (user_id);
create index idx_period_records_dates on public.period_records (user_id, start_date desc);
create trigger handle_updated_at_period_records
    before update on public.period_records
    for each row execute procedure update_updated_at_column();

-- --------------------------------------------------------------------
-- 11. Quote Vault (Things she says)
-- --------------------------------------------------------------------
create table public.quote_vault (
    id uuid primary key default gen_random_uuid(),
    user_id uuid references public.profiles(id) on delete cascade not null,
    quote text not null,
    quote_date date not null,
    context text,
    emotion text,
    significance text,
    tags text[] default '{}'::text[],
    created_at timestamp with time zone default timezone('utc'::text, now()) not null,
    updated_at timestamp with time zone default timezone('utc'::text, now()) not null,
    deleted_at timestamp with time zone
);

alter table public.quote_vault enable row level security;

create policy "Users can perform CRUD on quote vault"
    on public.quote_vault for all
    using (auth.uid() = user_id)
    with check (auth.uid() = user_id);

create index idx_quote_vault_user_id on public.quote_vault (user_id);
create trigger handle_updated_at_quote_vault
    before update on public.quote_vault
    for each row execute procedure update_updated_at_column();

-- --------------------------------------------------------------------
-- 12. Conflict Log
-- --------------------------------------------------------------------
create table public.conflict_logs (
    id uuid primary key default gen_random_uuid(),
    user_id uuid references public.profiles(id) on delete cascade not null,
    conflict_date date not null,
    what_happened text not null,
    emotional_impact text,
    root_cause text,
    resolution text,
    lessons_learned text,
    growth_notes text,
    created_at timestamp with time zone default timezone('utc'::text, now()) not null,
    updated_at timestamp with time zone default timezone('utc'::text, now()) not null,
    deleted_at timestamp with time zone
);

alter table public.conflict_logs enable row level security;

create policy "Users can perform CRUD on conflict logs"
    on public.conflict_logs for all
    using (auth.uid() = user_id)
    with check (auth.uid() = user_id);

create index idx_conflict_logs_user_id on public.conflict_logs (user_id);
create trigger handle_updated_at_conflict_logs
    before update on public.conflict_logs
    for each row execute procedure update_updated_at_column();

-- --------------------------------------------------------------------
-- 13. Social Matrix
-- --------------------------------------------------------------------
create table public.social_matrix (
    id uuid primary key default gen_random_uuid(),
    user_id uuid references public.profiles(id) on delete cascade not null,
    name text not null,
    relationship_type text not null,       -- 'like' or 'dislike'
    reason_or_status text,
    topics_or_guidelines text[] default '{}'::text[],
    positive_traits text[] default '{}'::text[],
    created_at timestamp with time zone default timezone('utc'::text, now()) not null,
    updated_at timestamp with time zone default timezone('utc'::text, now()) not null,
    deleted_at timestamp with time zone
);

alter table public.social_matrix enable row level security;

create policy "Users can perform CRUD on social matrix"
    on public.social_matrix for all
    using (auth.uid() = user_id)
    with check (auth.uid() = user_id);

create index idx_social_matrix_user_id on public.social_matrix (user_id);
create trigger handle_updated_at_social_matrix
    before update on public.social_matrix
    for each row execute procedure update_updated_at_column();

-- --------------------------------------------------------------------
-- 14. Gifts Database
-- --------------------------------------------------------------------
create table public.gifts_database (
    id uuid primary key default gen_random_uuid(),
    user_id uuid references public.profiles(id) on delete cascade not null,
    gift_idea text not null,
    status text not null default 'idea',  -- 'idea', 'purchased', 'gifted'
    budget numeric,
    reaction text,
    success_score integer check (success_score >= 1 and success_score <= 10),
    history_notes text,
    date_gifted date,
    created_at timestamp with time zone default timezone('utc'::text, now()) not null,
    updated_at timestamp with time zone default timezone('utc'::text, now()) not null,
    deleted_at timestamp with time zone
);

alter table public.gifts_database enable row level security;

create policy "Users can perform CRUD on gifts database"
    on public.gifts_database for all
    using (auth.uid() = user_id)
    with check (auth.uid() = user_id);

create index idx_gifts_db_user_id on public.gifts_database (user_id);
create trigger handle_updated_at_gifts_database
    before update on public.gifts_database
    for each row execute procedure update_updated_at_column();

-- --------------------------------------------------------------------
-- 15. Health & Wellness Database
-- --------------------------------------------------------------------
create table public.health_wellness (
    id uuid primary key default gen_random_uuid(),
    user_id uuid references public.profiles(id) on delete cascade unique not null,
    allergies text[] default '{}'::text[],
    medical_notes text,
    dietary_preferences text[] default '{}'::text[],
    comfort_foods text[] default '{}'::text[],
    stress_triggers text[] default '{}'::text[],
    sleep_notes text,
    wellness_preferences text,
    created_at timestamp with time zone default timezone('utc'::text, now()) not null,
    updated_at timestamp with time zone default timezone('utc'::text, now()) not null,
    deleted_at timestamp with time zone
);

alter table public.health_wellness enable row level security;

create policy "Users can perform CRUD on wellness database"
    on public.health_wellness for all
    using (auth.uid() = user_id)
    with check (auth.uid() = user_id);

create index idx_health_wellness_user_id on public.health_wellness (user_id);
create trigger handle_updated_at_health_wellness
    before update on public.health_wellness
    for each row execute procedure update_updated_at_column();

-- --------------------------------------------------------------------
-- 16. Unified Timeline Events (Read-Optimized Timeline Index)
-- --------------------------------------------------------------------
create table public.timeline_events (
    id uuid primary key default gen_random_uuid(),
    user_id uuid references public.profiles(id) on delete cascade not null,
    source_table text not null,           -- 'memories', 'relationship_events', 'quote_vault', 'conflict_logs', 'gifts_database'
    source_id uuid not null,
    event_date timestamp with time zone not null,
    title text not null,
    description text,
    mood text,
    tags text[] default '{}'::text[],
    importance_score integer,
    created_at timestamp with time zone default timezone('utc'::text, now()) not null,
    updated_at timestamp with time zone default timezone('utc'::text, now()) not null,
    deleted_at timestamp with time zone
);

alter table public.timeline_events enable row level security;

create policy "Users can browse their timeline index"
    on public.timeline_events for all
    using (auth.uid() = user_id)
    with check (auth.uid() = user_id);

create index idx_timeline_events_user_date on public.timeline_events (user_id, event_date desc);
create index idx_timeline_events_tags on public.timeline_events using gin (tags);
create trigger handle_updated_at_timeline_events
    before update on public.timeline_events
    for each row execute procedure update_updated_at_column();

-- --------------------------------------------------------------------
-- Trigger Functions for Timeline Aggregation Synchronization
-- --------------------------------------------------------------------

-- A. Memory Synchronization Function
create or replace function sync_memory_to_timeline()
returns trigger as $$
begin
    if (TG_OP = 'INSERT') then
        insert into public.timeline_events (user_id, source_table, source_id, event_date, title, description, mood, tags, importance_score)
        values (new.user_id, 'memories', new.id, new.memory_date, new.title, substring(new.story from 1 for 250), new.mood, new.tags, new.importance_score);
    elsif (TG_OP = 'UPDATE') then
        update public.timeline_events 
        set event_date = new.memory_date, title = new.title, description = substring(new.story from 1 for 250), mood = new.mood, tags = new.tags, importance_score = new.importance_score
        where source_id = new.id and source_table = 'memories';
    elsif (TG_OP = 'DELETE') then
        delete from public.timeline_events where source_id = old.id and source_table = 'memories';
    end if;
    return new;
end;
$$ language plpgsql;

create trigger trg_sync_memory
    after insert or update or delete on public.memories
    for each row execute procedure sync_memory_to_timeline();


-- B. Relationship Event Synchronization Function
create or replace function sync_relationship_event_to_timeline()
returns trigger as $$
begin
    if (TG_OP = 'INSERT') then
        insert into public.timeline_events (user_id, source_table, source_id, event_date, title, description, tags)
        values (new.user_id, 'relationship_events', new.id, new.event_date, new.title, 'Relationship milestone category: ' || new.event_type, array[new.event_type]);
    elsif (TG_OP = 'UPDATE') then
        update public.timeline_events 
        set event_date = new.event_date, title = new.title, description = 'Relationship milestone category: ' || new.event_type, tags = array[new.event_type]
        where source_id = new.id and source_table = 'relationship_events';
    elsif (TG_OP = 'DELETE') then
        delete from public.timeline_events where source_id = old.id and source_table = 'relationship_events';
    end if;
    return new;
end;
$$ language plpgsql;

create trigger trg_sync_relationship_event
    after insert or update or delete on public.relationship_events
    for each row execute procedure sync_relationship_event_to_timeline();


-- C. Quote Synchronization Function
create or replace function sync_quote_to_timeline()
returns trigger as $$
begin
    if (TG_OP = 'INSERT') then
        insert into public.timeline_events (user_id, source_table, source_id, event_date, title, description, mood, tags)
        values (new.user_id, 'quote_vault', new.id, cast(new.quote_date as timestamp with time zone), 'She said: "' || substring(new.quote from 1 for 60) || '"', new.context, new.emotion, new.tags);
    elsif (TG_OP = 'UPDATE') then
        update public.timeline_events 
        set event_date = cast(new.quote_date as timestamp with time zone), title = 'She said: "' || substring(new.quote from 1 for 60) || '"', description = new.context, mood = new.emotion, tags = new.tags
        where source_id = new.id and source_table = 'quote_vault';
    elsif (TG_OP = 'DELETE') then
        delete from public.timeline_events where source_id = old.id and source_table = 'quote_vault';
    end if;
    return new;
end;
$$ language plpgsql;

create trigger trg_sync_quote
    after insert or update or delete on public.quote_vault
    for each row execute procedure sync_quote_to_timeline();


-- D. Conflict Synchronization Function
create or replace function sync_conflict_to_timeline()
returns trigger as $$
begin
    if (TG_OP = 'INSERT') then
        insert into public.timeline_events (user_id, source_table, source_id, event_date, title, description, tags)
        values (new.user_id, 'conflict_logs', new.id, cast(new.conflict_date as timestamp with time zone), 'Conflict Record', substring(new.what_happened from 1 for 250), array['conflict-log']);
    elsif (TG_OP = 'UPDATE') then
        update public.timeline_events 
        set event_date = cast(new.conflict_date as timestamp with time zone), description = substring(new.what_happened from 1 for 250)
        where source_id = new.id and source_table = 'conflict_logs';
    elsif (TG_OP = 'DELETE') then
        delete from public.timeline_events where source_id = old.id and source_table = 'conflict_logs';
    end if;
    return new;
end;
$$ language plpgsql;

create trigger trg_sync_conflict
    after insert or update or delete on public.conflict_logs
    for each row execute procedure sync_conflict_to_timeline();


-- E. Gift Synchronization Function
create or replace function sync_gift_to_timeline()
returns trigger as $$
begin
    -- Only sync if the gift has actually been gifted (completed date available)
    if (new.status = 'gifted' and new.date_gifted is not null) then
        if not exists (select 1 from public.timeline_events where source_id = new.id and source_table = 'gifts_database') then
            insert into public.timeline_events (user_id, source_table, source_id, event_date, title, description, tags, importance_score)
            values (new.user_id, 'gifts_database', new.id, cast(new.date_gifted as timestamp with time zone), 'Gift Presented: ' || new.gift_idea, new.reaction, array['gift'], new.success_score);
        else
            update public.timeline_events 
            set event_date = cast(new.date_gifted as timestamp with time zone), title = 'Gift Presented: ' || new.gift_idea, description = new.reaction, importance_score = new.success_score
            where source_id = new.id and source_table = 'gifts_database';
        end if;
    else
        -- If status reverted from gifted, delete from timeline
        delete from public.timeline_events where source_id = new.id and source_table = 'gifts_database';
    end if;
    return new;
end;
$$ language plpgsql;

create trigger trg_sync_gift
    after insert or update on public.gifts_database
    for each row execute procedure sync_gift_to_timeline();

create or replace function delete_gift_from_timeline()
returns trigger as $$
begin
    delete from public.timeline_events where source_id = old.id and source_table = 'gifts_database';
    return old;
end;
$$ language plpgsql;

create trigger trg_sync_gift_delete
    after delete on public.gifts_database
    for each row execute procedure delete_gift_from_timeline();

-- --------------------------------------------------------------------
-- 17. Life OS — Time Blocks
-- --------------------------------------------------------------------
create table public.time_blocks (
    id uuid primary key default gen_random_uuid(),
    owner_id uuid not null references auth.users(id) on delete cascade,
    title text not null,
    description text,
    start_time timestamp with time zone,
    end_time timestamp with time zone,
    category text,
    color text,
    completed boolean default false,
    recurring boolean default false,
    recurrence_rule text,
    created_at timestamp with time zone default timezone('utc'::text, now()) not null,
    updated_at timestamp with time zone default timezone('utc'::text, now()) not null,
    deleted_at timestamp with time zone
);

alter table public.time_blocks enable row level security;

create policy "Users can perform CRUD on their own time blocks"
    on public.time_blocks for all
    using (auth.uid() = owner_id)
    with check (auth.uid() = owner_id);

create index idx_time_blocks_owner on public.time_blocks(owner_id);
create trigger handle_updated_at_time_blocks
    before update on public.time_blocks
    for each row execute procedure update_updated_at_column();

-- --------------------------------------------------------------------
-- 18. Life OS — Daily Tasks
-- --------------------------------------------------------------------
create table public.tasks (
    id uuid primary key default gen_random_uuid(),
    owner_id uuid not null references auth.users(id) on delete cascade,
    title text not null,
    description text,
    priority integer check (priority >= 1 and priority <= 4), -- 1: Low, 2: Medium, 3: High, 4: Critical
    due_date timestamp with time zone,
    completed boolean default false,
    completed_at timestamp with time zone,
    created_at timestamp with time zone default timezone('utc'::text, now()) not null,
    updated_at timestamp with time zone default timezone('utc'::text, now()) not null,
    deleted_at timestamp with time zone
);

alter table public.tasks enable row level security;

create policy "Users can perform CRUD on their own tasks"
    on public.tasks for all
    using (auth.uid() = owner_id)
    with check (auth.uid() = owner_id);

create index idx_tasks_owner on public.tasks(owner_id);
create trigger handle_updated_at_tasks
    before update on public.tasks
    for each row execute procedure update_updated_at_column();

-- --------------------------------------------------------------------
-- 19. Life OS — Goal Categories
-- --------------------------------------------------------------------
create table public.goal_categories (
    id uuid primary key default gen_random_uuid(),
    owner_id uuid references auth.users(id) on delete cascade,
    name text not null
);

alter table public.goal_categories enable row level security;

create policy "Users can perform CRUD on their own goal categories"
    on public.goal_categories for all
    using (auth.uid() = owner_id)
    with check (auth.uid() = owner_id);

-- --------------------------------------------------------------------
-- 20. Life OS — Goals
-- --------------------------------------------------------------------
create table public.goals (
    id uuid primary key default gen_random_uuid(),
    owner_id uuid references auth.users(id) on delete cascade,
    category_id uuid references public.goal_categories(id) on delete set null,
    title text not null,
    description text,
    target_date date,
    progress numeric default 0.0,
    status text, -- e.g., 'not_started', 'in_progress', 'completed'
    created_at timestamp with time zone default timezone('utc'::text, now()) not null,
    updated_at timestamp with time zone default timezone('utc'::text, now()) not null,
    deleted_at timestamp with time zone
);

alter table public.goals enable row level security;

create policy "Users can perform CRUD on their own goals"
    on public.goals for all
    using (auth.uid() = owner_id)
    with check (auth.uid() = owner_id);

create index idx_goals_owner on public.goals(owner_id);
create trigger handle_updated_at_goals
    before update on public.goals
    for each row execute procedure update_updated_at_column();

-- --------------------------------------------------------------------
-- 21. Life OS — Goal Milestones
-- --------------------------------------------------------------------
create table public.goal_milestones (
    id uuid primary key default gen_random_uuid(),
    goal_id uuid references public.goals(id) on delete cascade,
    title text,
    completed boolean default false,
    completed_at timestamp with time zone,
    created_at timestamp with time zone default timezone('utc'::text, now()) not null,
    updated_at timestamp with time zone default timezone('utc'::text, now()) not null,
    deleted_at timestamp with time zone
);

alter table public.goal_milestones enable row level security;

create policy "Users can perform CRUD on milestones of their goals"
    on public.goal_milestones for all
    using (exists (select 1 from public.goals g where g.id = goal_id and g.owner_id = auth.uid()))
    with check (exists (select 1 from public.goals g where g.id = goal_id and g.owner_id = auth.uid()));

create trigger handle_updated_at_goal_milestones
    before update on public.goal_milestones
    for each row execute procedure update_updated_at_column();

-- --------------------------------------------------------------------
-- 22. Life OS — Habits
-- --------------------------------------------------------------------
create table public.habits (
    id uuid primary key default gen_random_uuid(),
    owner_id uuid references auth.users(id) on delete cascade,
    title text,
    description text,
    target_frequency integer, -- e.g., days per week
    streak integer default 0,
    created_at timestamp with time zone default timezone('utc'::text, now()) not null,
    updated_at timestamp with time zone default timezone('utc'::text, now()) not null,
    deleted_at timestamp with time zone
);

alter table public.habits enable row level security;

create policy "Users can perform CRUD on their own habits"
    on public.habits for all
    using (auth.uid() = owner_id)
    with check (auth.uid() = owner_id);

create index idx_habits_owner on public.habits(owner_id);
create trigger handle_updated_at_habits
    before update on public.habits
    for each row execute procedure update_updated_at_column();

-- --------------------------------------------------------------------
-- 23. Life OS — Habit Logs
-- --------------------------------------------------------------------
create table public.habit_logs (
    id uuid primary key default gen_random_uuid(),
    habit_id uuid references public.habits(id) on delete cascade,
    completed_date date,
    created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

alter table public.habit_logs enable row level security;

create policy "Users can perform CRUD on their own habit logs"
    on public.habit_logs for all
    using (exists (select 1 from public.habits h where h.id = habit_id and h.owner_id = auth.uid()))
    with check (exists (select 1 from public.habits h where h.id = habit_id and h.owner_id = auth.uid()));

-- --------------------------------------------------------------------
-- 24. Life OS — Routines
-- --------------------------------------------------------------------
create table public.routines (
    id uuid primary key default gen_random_uuid(),
    owner_id uuid references auth.users(id) on delete cascade,
    title text,
    routine_type text, -- 'Morning', 'Afternoon', 'Evening', 'Night'
    created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

alter table public.routines enable row level security;

create policy "Users can perform CRUD on their own routines"
    on public.routines for all
    using (auth.uid() = owner_id)
    with check (auth.uid() = owner_id);

-- --------------------------------------------------------------------
-- 25. Life OS — Routine Steps
-- --------------------------------------------------------------------
create table public.routine_steps (
    id uuid primary key default gen_random_uuid(),
    routine_id uuid references public.routines(id) on delete cascade,
    step_order integer,
    title text,
    estimated_minutes integer
);

alter table public.routine_steps enable row level security;

create policy "Users can perform CRUD on routine steps of their routines"
    on public.routine_steps for all
    using (exists (select 1 from public.routines r where r.id = routine_id and r.owner_id = auth.uid()))
    with check (exists (select 1 from public.routines r where r.id = routine_id and r.owner_id = auth.uid()));

-- --------------------------------------------------------------------
-- 26. Life OS — Focus Sessions
-- --------------------------------------------------------------------
create table public.focus_sessions (
    id uuid primary key default gen_random_uuid(),
    owner_id uuid references auth.users(id) on delete cascade,
    title text,
    start_time timestamp with time zone,
    end_time timestamp with time zone,
    duration_minutes integer,
    productivity_score integer check (productivity_score >= 1 and productivity_score <= 5),
    notes text
);

alter table public.focus_sessions enable row level security;

create policy "Users can perform CRUD on their own focus sessions"
    on public.focus_sessions for all
    using (auth.uid() = owner_id)
    with check (auth.uid() = owner_id);

create index idx_focus_sessions_owner on public.focus_sessions(owner_id);

-- --------------------------------------------------------------------
-- 27. Life OS — Daily Reflections
-- --------------------------------------------------------------------
create table public.daily_reflections (
    id uuid primary key default gen_random_uuid(),
    owner_id uuid references auth.users(id) on delete cascade,
    reflection_date date not null,
    wins text,
    challenges text,
    gratitude text,
    lessons_learned text,
    mood integer check (mood >= 1 and mood <= 5),
    created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

alter table public.daily_reflections enable row level security;

create policy "Users can perform CRUD on their own daily reflections"
    on public.daily_reflections for all
    using (auth.uid() = owner_id)
    with check (auth.uid() = owner_id);

create index idx_daily_reflections_owner on public.daily_reflections(owner_id);

-- --------------------------------------------------------------------
-- 28. Life OS — Advanced Analytics Time Logs
-- --------------------------------------------------------------------
create table public.time_logs (
    id uuid primary key default gen_random_uuid(),
    owner_id uuid references auth.users(id) on delete cascade,
    category text, -- 'Work', 'Health', 'Krisha Time', 'Learning', 'Gaming', 'Sleep', 'Other'
    started_at timestamp with time zone,
    ended_at timestamp with time zone,
    duration_minutes integer
);

alter table public.time_logs enable row level security;

create policy "Users can perform CRUD on their own time logs"
    on public.time_logs for all
    using (auth.uid() = owner_id)
    with check (auth.uid() = owner_id);

create index idx_time_logs_owner on public.time_logs(owner_id);

-- --------------------------------------------------------------------
-- 29. Timeline Synchronizations for Life OS Goals & Reflections
-- --------------------------------------------------------------------

-- A. Goals Completed Timeline Sync Trigger
create or replace function sync_goal_to_timeline()
returns trigger as $$
begin
    if (TG_OP = 'INSERT' and new.status = 'completed') then
        insert into public.timeline_events (user_id, source_table, source_id, event_date, title, description, tags)
        values (new.owner_id, 'goals', new.id, timezone('utc'::text, now()), 'Goal Achieved: ' || new.title, new.description, array['goal', 'life-os']);
    elsif (TG_OP = 'UPDATE') then
        if (new.status = 'completed' and (old.status is null or old.status != 'completed')) then
            insert into public.timeline_events (user_id, source_table, source_id, event_date, title, description, tags)
            values (new.owner_id, 'goals', new.id, timezone('utc'::text, now()), 'Goal Achieved: ' || new.title, new.description, array['goal', 'life-os']);
        elsif (new.status != 'completed' and old.status = 'completed') then
            delete from public.timeline_events where source_id = new.id and source_table = 'goals';
        elsif (new.status = 'completed' and old.status = 'completed') then
            update public.timeline_events
            set title = 'Goal Achieved: ' || new.title, description = new.description
            where source_id = new.id and source_table = 'goals';
        end if;
    elsif (TG_OP = 'DELETE') then
        delete from public.timeline_events where source_id = old.id and source_table = 'goals';
    end if;
    return new;
end;
$$ language plpgsql;

create trigger trg_sync_goal
    after insert or update or delete on public.goals
    for each row execute procedure sync_goal_to_timeline();

-- B. Daily Reflection Timeline Sync Trigger
create or replace function sync_reflection_to_timeline()
returns trigger as $$
begin
    if (TG_OP = 'INSERT') then
        insert into public.timeline_events (user_id, source_table, source_id, event_date, title, description, tags, importance_score)
        values (new.owner_id, 'daily_reflections', new.id, cast(new.reflection_date as timestamp with time zone), 'Daily Reflection Logging', 'Gratitude: ' || substring(coalesce(new.gratitude, '') from 1 for 100) || ' | Wins: ' || substring(coalesce(new.wins, '') from 1 for 100), array['reflection', 'journal', 'life-os'], new.mood);
    elsif (TG_OP = 'UPDATE') then
        update public.timeline_events
        set event_date = cast(new.reflection_date as timestamp with time zone),
            description = 'Gratitude: ' || substring(coalesce(new.gratitude, '') from 1 for 100) || ' | Wins: ' || substring(coalesce(new.wins, '') from 1 for 100),
            importance_score = new.mood
        where source_id = new.id and source_table = 'daily_reflections';
    elsif (TG_OP = 'DELETE') then
        delete from public.timeline_events where source_id = old.id and source_table = 'daily_reflections';
    end if;
    return new;
end;
$$ language plpgsql;

create trigger trg_sync_reflection
    after insert or update or delete on public.daily_reflections
    for each row execute procedure sync_reflection_to_timeline();

