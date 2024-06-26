require './test/spec_helper'
require 'activerecord-clean-db-structure/clean_dump'

class PartitionTest < Minitest::Spec
  described_class = ActiveRecordCleanDbStructure::CleanDump

  describe 'Keep storage tables partitions' do
    options = {
      keep_partitions: ['storage_tables_blobs_partition_'],
      indexes_after_tables: true,
      order_column_definitions: true,
      move_unique_constraints_to_tables: true
    }

    dump = <<~SQL
      --
      -- Name: storage_tables_blobs; Type: TABLE; Schema: public; Owner: -
      --

      CREATE TABLE public.storage_tables_blobs (
        partition_key character(1) NOT NULL,
        checksum character(85) NOT NULL,
        attachments_count_modified timestamp(6) with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
        attachments_count integer DEFAULT 0 NOT NULL,
        byte_size bigint NOT NULL,
        content_type character varying,
        metadata jsonb
      )
      PARTITION BY LIST (partition_key);

      --
      -- Name: storage_tables_blobs_partition_9; Type: TABLE
      --

      CREATE TABLE public.storage_tables_blobs_partition_9 (
        partition_key character(1) NOT NULL,
        checksum character(85) NOT NULL,
        attachments_count_modified timestamp(6) with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
        attachments_count integer DEFAULT 0 NOT NULL,
        byte_size bigint NOT NULL,
        content_type character varying,
        metadata jsonb
      );
      ALTER TABLE ONLY public.storage_tables_blobs ATTACH PARTITION public.storage_tables_blobs_partition_9 FOR VALUES IN ('J');

      --
      -- PostgreSQL database dump complete
      --
    SQL

    it 'refactors the partitioned table' do
      assert_equal <<~SQL, described_class.new(dump, options).run

        -- Name: storage_tables_blobs; Type: TABLE

        CREATE TABLE public.storage_tables_blobs (
          attachments_count integer DEFAULT 0 NOT NULL,
          attachments_count_modified timestamp(6) with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
          byte_size bigint NOT NULL,
          checksum character(85) NOT NULL,
          content_type character varying,
          metadata jsonb,
          partition_key character(1) NOT NULL
        )
        PARTITION BY LIST (partition_key);

        -- Name: storage_tables_blobs_partition_9; Type: TABLE

        CREATE TABLE public.storage_tables_blobs_partition_9 (
          attachments_count integer DEFAULT 0 NOT NULL,
          attachments_count_modified timestamp(6) with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
          byte_size bigint NOT NULL,
          checksum character(85) NOT NULL,
          content_type character varying,
          metadata jsonb,
          partition_key character(1) NOT NULL
        );
        ALTER TABLE ONLY public.storage_tables_blobs ATTACH PARTITION public.storage_tables_blobs_partition_9 FOR VALUES IN ('J');

        -- PostgreSQL database dump complete
      SQL
    end
  end
end
