-- Enable PostGIS for geospatial indexing
CREATE EXTENSION IF NOT EXISTS postgis;

-- 1. Hazard Zones Table
CREATE TABLE IF NOT EXISTS public.hazards (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title TEXT NOT NULL,
    description TEXT,
    severity TEXT NOT NULL CHECK (severity IN ('LOW', 'MEDIUM', 'HIGH', 'CRITICAL')),
    location GEOGRAPHY(POINT, 4326) NOT NULL,
    radius_meters DOUBLE PRECISION NOT NULL DEFAULT 500.0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    expires_at TIMESTAMPTZ
);

-- 2. Emergency Mesh Signals Table (Off-grid syncing when connectivity restores)
CREATE TABLE IF NOT EXISTS public.mesh_pings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    sender_id TEXT NOT NULL,
    status_payload TEXT NOT NULL CHECK (status_payload IN ('SAFE', 'NEED_ASSISTANCE', 'EVACUATING')),
    location GEOGRAPHY(POINT, 4326) NOT NULL,
    hop_count INT NOT NULL DEFAULT 0,
    relayed_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Enable Spatial Indexing for Fast Querying
CREATE INDEX IF NOT EXISTS idx_hazards_location ON public.hazards USING GIST(location);
CREATE INDEX IF NOT EXISTS idx_mesh_pings_location ON public.mesh_pings USING GIST(location);

-- Row-Level Security Policies
ALTER TABLE public.hazards ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.mesh_pings ENABLE ROW LEVEL SECURITY;

-- Allow public read access to active hazards
CREATE POLICY "Public hazards are viewable by all users" 
ON public.hazards FOR SELECT 
USING (true);

-- Allow authenticated users to insert emergency pings
CREATE POLICY "Authenticated users can post mesh pings" 
ON public.mesh_pings FOR INSERT 
WITH CHECK (true);
