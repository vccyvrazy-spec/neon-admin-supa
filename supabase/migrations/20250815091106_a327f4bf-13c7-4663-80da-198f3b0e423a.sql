-- Create custom types
CREATE TYPE public.app_role AS ENUM ('admin', 'moderator', 'user');

-- Create profiles table (1-1 with auth.users)
CREATE TABLE public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT NOT NULL,
    full_name TEXT,
    role app_role NOT NULL DEFAULT 'user',
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Create audit logs table
CREATE TABLE public.audit_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    admin_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    admin_email TEXT NOT NULL,
    action TEXT NOT NULL,
    target_type TEXT, -- 'user', 'storage', 'system'
    target_id TEXT,
    details JSONB,
    ip_address INET,
    user_agent TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.audit_logs ENABLE ROW LEVEL SECURITY;

-- Helper functions
CREATE OR REPLACE FUNCTION public.my_role()
RETURNS app_role
LANGUAGE SQL
STABLE
SECURITY DEFINER
AS $$
  SELECT role FROM public.profiles WHERE id = auth.uid();
$$;

CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN
LANGUAGE SQL
STABLE
SECURITY DEFINER
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.profiles 
    WHERE id = auth.uid() AND role = 'admin' AND is_active = true
  );
$$;

CREATE OR REPLACE FUNCTION public.is_moderator()
RETURNS BOOLEAN
LANGUAGE SQL
STABLE
SECURITY DEFINER
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.profiles 
    WHERE id = auth.uid() AND role IN ('admin', 'moderator') AND is_active = true
  );
$$;

-- RLS Policies for profiles
CREATE POLICY "Users can view their own profile"
ON public.profiles FOR SELECT
USING (auth.uid() = id);

CREATE POLICY "Admins can view all profiles"
ON public.profiles FOR SELECT
USING (public.is_admin());

CREATE POLICY "Users can update their own profile (limited)"
ON public.profiles FOR UPDATE
USING (auth.uid() = id)
WITH CHECK (
  auth.uid() = id AND 
  role = (SELECT role FROM public.profiles WHERE id = auth.uid()) AND
  is_active = (SELECT is_active FROM public.profiles WHERE id = auth.uid())
);

CREATE POLICY "Admins can update all profiles"
ON public.profiles FOR UPDATE
USING (public.is_admin());

CREATE POLICY "Admins can insert profiles"
ON public.profiles FOR INSERT
WITH CHECK (public.is_admin());

CREATE POLICY "Admins can delete profiles"
ON public.profiles FOR DELETE
USING (public.is_admin());

-- RLS Policies for audit_logs
CREATE POLICY "Admins can view all audit logs"
ON public.audit_logs FOR SELECT
USING (public.is_admin());

CREATE POLICY "System can insert audit logs"
ON public.audit_logs FOR INSERT
WITH CHECK (true);

-- Create storage buckets
INSERT INTO storage.buckets (id, name, public) VALUES 
('public-products', 'public-products', true),
('private-attachments', 'private-attachments', false),
('logs', 'logs', false);

-- Storage policies for public-products
CREATE POLICY "Public can view public-products"
ON storage.objects FOR SELECT
USING (bucket_id = 'public-products');

CREATE POLICY "Admins and moderators can upload to public-products"
ON storage.objects FOR INSERT
WITH CHECK (
  bucket_id = 'public-products' AND 
  public.is_moderator()
);

CREATE POLICY "Admins and moderators can update public-products"
ON storage.objects FOR UPDATE
USING (
  bucket_id = 'public-products' AND 
  public.is_moderator()
);

CREATE POLICY "Admins and moderators can delete from public-products"
ON storage.objects FOR DELETE
USING (
  bucket_id = 'public-products' AND 
  public.is_moderator()
);

-- Storage policies for private-attachments
CREATE POLICY "Users can view their own private attachments"
ON storage.objects FOR SELECT
USING (
  bucket_id = 'private-attachments' AND 
  auth.uid()::text = (storage.foldername(name))[1]
);

CREATE POLICY "Users can upload their own private attachments"
ON storage.objects FOR INSERT
WITH CHECK (
  bucket_id = 'private-attachments' AND 
  auth.uid()::text = (storage.foldername(name))[1]
);

CREATE POLICY "Users can update their own private attachments"
ON storage.objects FOR UPDATE
USING (
  bucket_id = 'private-attachments' AND 
  auth.uid()::text = (storage.foldername(name))[1]
);

CREATE POLICY "Users can delete their own private attachments"
ON storage.objects FOR DELETE
USING (
  bucket_id = 'private-attachments' AND 
  auth.uid()::text = (storage.foldername(name))[1]
);

-- Storage policies for logs (admin only)
CREATE POLICY "Admins can manage logs bucket"
ON storage.objects FOR ALL
USING (
  bucket_id = 'logs' AND 
  public.is_admin()
);

-- Create trigger for profile updates
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER profiles_updated_at
  BEFORE UPDATE ON public.profiles
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_updated_at();

-- Create trigger for new user signup (creates profile)
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, email, full_name, role)
  VALUES (
    NEW.id,
    NEW.email,
    NEW.raw_user_meta_data->>'full_name',
    'user'
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Seed admin user (will be created when admin signs up with myne7x@gmail.com)
CREATE OR REPLACE FUNCTION public.handle_admin_seed()
RETURNS TRIGGER AS $$
BEGIN
  -- Check if this is the admin seed email
  IF NEW.email = 'myne7x@gmail.com' THEN
    UPDATE public.profiles 
    SET role = 'admin'
    WHERE id = NEW.id;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_admin_seed_created
  AFTER INSERT ON public.profiles
  FOR EACH ROW 
  WHEN (NEW.email = 'myne7x@gmail.com')
  EXECUTE FUNCTION public.handle_admin_seed();