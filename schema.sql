-- Create extension for Python
CREATE EXTENSION IF NOT EXISTS plpython3u;

-- Create tables WITHOUT constraints (they will be added after data generation)
CREATE TABLE public.retail_center(
    id serial,
    type character varying(255) NOT NULL,
    address character varying(255) NOT NULL
    -- PRIMARY KEY will be added after data generation
);

CREATE TABLE public.transport_event(
    seq_number serial,
    type character varying(255) NOT NULL,
    delivery_rout character varying(255) NOT NULL
    -- PRIMARY KEY will be added after data generation
);

CREATE TABLE public.shipped_item(
    item_num serial,
    retail_center_id integer NOT NULL,
    weight numeric(19, 2) NOT NULL,
    dimension numeric(19, 2) NOT NULL,
    insurance_amt numeric(19, 2) NOT NULL,
    destination character varying(255) NOT NULL,
    final_delivery_date date NOT NULL
    -- PRIMARY KEY and FOREIGN KEY constraints will be added after data generation
);

CREATE TABLE public.item_transportation(
    id serial NOT NULL,  -- Add a unique ID column to ensure primary key uniqueness
    transportation_event_seq_number integer NOT NULL,
    comment character varying(255) NOT NULL,
    shipped_item_item_num integer NOT NULL
    -- PRIMARY KEY and FOREIGN KEY constraints will be added after data generation
);

-- Function to add constraints after data generation
CREATE OR REPLACE FUNCTION add_constraints()
    RETURNS VOID
    AS $$
BEGIN
    -- Add primary keys to parent tables
    ALTER TABLE public.retail_center
        ADD CONSTRAINT retail_center_pkey PRIMARY KEY (id);
    
    ALTER TABLE public.transport_event
        ADD CONSTRAINT transport_event_pkey PRIMARY KEY (seq_number);
    
    -- Add primary key and foreign key to shipped_item
    ALTER TABLE public.shipped_item
        ADD CONSTRAINT shipped_item_pkey PRIMARY KEY (item_num);
    
    ALTER TABLE public.shipped_item
        ADD CONSTRAINT "Retail_Center_ID" FOREIGN KEY (retail_center_id) 
        REFERENCES public.retail_center (id) MATCH SIMPLE 
        ON UPDATE CASCADE 
        ON DELETE CASCADE;
    
    -- Add primary key on the id column and foreign keys to item_transportation
    ALTER TABLE public.item_transportation
        ADD CONSTRAINT item_transportation_pkey 
        PRIMARY KEY (id);
    
    -- Create an index on the combination for better query performance
    CREATE INDEX idx_item_transportation_combined ON item_transportation
        (transportation_event_seq_number, shipped_item_item_num);
        
    ALTER TABLE public.item_transportation
        ADD CONSTRAINT "Shipped_item_item_num" FOREIGN KEY (shipped_item_item_num) 
        REFERENCES public.shipped_item (item_num) MATCH SIMPLE 
        ON UPDATE CASCADE 
        ON DELETE CASCADE;
    
    ALTER TABLE public.item_transportation
        ADD CONSTRAINT "Transportation_event_seq_number" 
        FOREIGN KEY (transportation_event_seq_number) 
        REFERENCES public.transport_event (seq_number) MATCH SIMPLE 
        ON UPDATE CASCADE 
        ON DELETE CASCADE;
    
    RAISE NOTICE 'All constraints have been successfully added.';
END;
$$
LANGUAGE plpgsql;
