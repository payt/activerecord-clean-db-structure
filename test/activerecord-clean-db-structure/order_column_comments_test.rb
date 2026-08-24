# frozen_string_literal: true

require './test/spec_helper'
require 'activerecord-clean-db-structure/clean_dump'

class OrderColumnCommentsTest < Minitest::Spec
  described_class = ActiveRecordCleanDbStructure::CleanDump

  describe 'Ordering column comments' do
    dump = <<~SQL
      --
      -- Name: users; Type: TABLE; Schema: public; Owner: -
      --

      CREATE TABLE public.users (
        id bigint NOT NULL,
        name character varying NOT NULL,
        created_at timestamp(6) without time zone NOT NULL
      );

      --
      -- Name: COLUMN users.created_at; Type: COMMENT
      --

      COMMENT ON COLUMN public.users.created_at IS 'The creation timestamp';

      --
      -- Name: COLUMN users.id; Type: COMMENT
      --

      COMMENT ON COLUMN public.users.id IS 'Primary key';

      --
      -- Name: COLUMN users.name; Type: COMMENT
      --

      COMMENT ON COLUMN public.users.name IS 'User name';

      --
      -- PostgreSQL database dump complete
      --
    SQL

    it 'Orders consecutive column comments alphabetically' do
      result = described_class.new(dump, {}).run

      expected_comments = [
        'COMMENT ON COLUMN public.users.created_at IS \'The creation timestamp\';',
        'COMMENT ON COLUMN public.users.id IS \'Primary key\';',
        'COMMENT ON COLUMN public.users.name IS \'User name\';'
      ]

      # Verify comments are in alphabetical order
      comment_order = result.scan(/COMMENT ON COLUMN [^;]+;/)
      assert_equal expected_comments, comment_order
    end

    it 'Handles comments with quoted identifiers' do
      dump_with_quotes = <<~SQL
        --
        -- Name: COLUMN "MyTable"."ZColumn"; Type: COMMENT
        --

        COMMENT ON COLUMN "MyTable"."ZColumn" IS 'Z comment';

        --
        -- Name: COLUMN "MyTable"."AColumn"; Type: COMMENT
        --

        COMMENT ON COLUMN "MyTable"."AColumn" IS 'A comment';

        --
        -- PostgreSQL database dump complete
        --
      SQL

      result = described_class.new(dump_with_quotes, {}).run
      comment_order = result.scan(/COMMENT ON COLUMN [^;]+;/)

      # Should be sorted by unquoted column name (AColumn, then ZColumn)
      assert_equal 'COMMENT ON COLUMN "MyTable"."AColumn" IS \'A comment\';', comment_order[0]
      assert_equal 'COMMENT ON COLUMN "MyTable"."ZColumn" IS \'Z comment\';', comment_order[1]
    end

    it 'Preserves single comment blocks' do
      dump_single = <<~SQL
        --
        -- Name: users; Type: TABLE; Schema: public; Owner: -
        --

        CREATE TABLE public.users (
          id bigint NOT NULL
        );

        --
        -- Name: COLUMN users.id; Type: COMMENT
        --

        COMMENT ON COLUMN public.users.id IS 'Primary key';

        --
        -- PostgreSQL database dump complete
        --
      SQL

      result = described_class.new(dump_single, {}).run
      assert result.include?('COMMENT ON COLUMN public.users.id IS \'Primary key\';')
    end
  end
end
