CREATE OR REPLACE FUNCTION table_has_identity_columns(
    p_table_name text,
    p_ignored_columns text[] DEFAULT NULL
) RETURNS boolean AS $$
DECLARE
    v_identity_columns_count int;
    v_schema_name text;
    v_table_only_name text;
BEGIN
    -- if p_table_name contains schema，split schema and table
    IF p_table_name LIKE '%.%' THEN
        v_schema_name := split_part(p_table_name, '.', 1);
        v_table_only_name := split_part(p_table_name, '.', 2);
    ELSE
        -- if not，use curent schema
        v_schema_name := current_schema();
        v_table_only_name := p_table_name;
    END IF;

    -- query all columns defined with GENERATED ALWAYS AS IDENTITY ，except columns in p_ignored_columns
    SELECT COUNT(*) INTO v_identity_columns_count FROM pg_attribute a
      JOIN pg_class c ON c.oid = a.attrelid
      JOIN pg_namespace n ON n.oid = c.relnamespace
      WHERE c.relname = v_table_only_name
      AND n.nspname = v_schema_name
      AND a.attidentity = 'a'     -- GENERATED ALWAYS AS IDENTITY
      AND a.attnum > 0            -- except system column
      AND NOT a.attisdropped      -- except deleted column
      AND (p_ignored_columns IS NULL OR a.attname != ANY(p_ignored_columns));

    IF v_identity_columns_count > 0 THEN
        RETURN true;
    ELSE
        RETURN false;
    END IF;
END;
$$ LANGUAGE plpgsql;

