require './test/spec_helper'
require 'activerecord-clean-db-structure/clean_dump'

class StorageParametersTest < Minitest::Spec
  described_class = ActiveRecordCleanDbStructure::CleanDump

  describe 'Table with WITH storage parameters' do
    options = {
      indexes_after_tables: true,
      order_column_definitions: true,
      move_unique_constraints_to_tables: true
    }

    dump = <<~SQL
      --
      -- Name: invoices; Type: TABLE; Schema: public; Owner: -
      --

      CREATE TABLE public.invoices (
        id BIGSERIAL,
        name character varying NOT NULL,
        created_at timestamp with time zone NOT NULL
      )
      WITH (autovacuum_vacuum_scale_factor='0.01', autovacuum_vacuum_threshold='1000');

      --
      -- Name: versions; Type: TABLE; Schema: public; Owner: -
      --

      CREATE TABLE public.versions (
        id BIGSERIAL,
        event character varying NOT NULL,
        created_at timestamp with time zone NOT NULL
      );

      --
      -- Name: index_invoices_on_created_at; Type: INDEX; Schema: public; Owner: -
      --

      CREATE INDEX index_invoices_on_created_at ON public.invoices USING btree (created_at);

      --
      -- Name: index_versions_on_created_at; Type: INDEX; Schema: public; Owner: -
      --

      CREATE INDEX index_versions_on_created_at ON public.versions USING btree (created_at);

      --
      -- Name: invoices index_invoices_on_name_and_id; Type: CONSTRAINT; Schema: public; Owner: -
      --

      ALTER TABLE ONLY public.invoices
        ADD CONSTRAINT index_invoices_on_name_and_id UNIQUE (name, id);

      --
      -- PostgreSQL database dump complete
      --
    SQL

    it 'places indexes after the correct tables and sorts columns without bleeding across WITH clause' do
      result = described_class.new(dump, options).run
      # invoices index placed after invoices table
      assert_match(/WITH \(autovacuum_vacuum_scale_factor='0\.01', autovacuum_vacuum_threshold='1000'\);\n\nCREATE INDEX index_invoices_on_created_at/, result)
      # versions index placed after versions table, not after invoices
      assert_match(/CREATE TABLE public\.versions.*CREATE INDEX index_versions_on_created_at/m, result)
      # event column not present inside the invoices CREATE TABLE block
      invoices_block = result[/CREATE TABLE public\.invoices \(.*?\)\nWITH [^\n]+;/m]
      refute_nil invoices_block
      refute_match(/event character varying/, invoices_block)
      # unique constraint moved inline, not lost
      assert_match(/CONSTRAINT index_invoices_on_name_and_id UNIQUE \(name, id\)/, invoices_block)
      # versions table intact
      assert_match(/CREATE TABLE public\.versions \(\n  created_at timestamp with time zone NOT NULL,\n  event character varying NOT NULL,\n  id BIGSERIAL\n\)/, result)
    end
  end
end
