# frozen_string_literal: true

module ActiveRecordCleanDbStructure
  module OrderColumnComments
    # The gem orders the column definitions inside CREATE TABLE alphabetically, but pg_dump
    # emits the COMMENT ON COLUMN statements in the physical column order of the database. A
    # database grown by running migrations one by one therefore dumps those comments in a
    # different order than a database created from db/structure.sql, where the physical order
    # already is the alphabetical one the gem wrote. Ordering them here makes the dump
    # independent of how the database was built.
    COMMENT_BLOCK = /^-- Name: COLUMN (?<name>[^;]+); Type: COMMENT\n+COMMENT ON COLUMN .+;\n+/
    CONSECUTIVE_COMMENT_BLOCKS = /(?:#{COMMENT_BLOCK}){2,}/

    def run
      super

      dump.gsub!(CONSECUTIVE_COMMENT_BLOCKS) do |blocks|
        blocks
          .to_enum(:scan, COMMENT_BLOCK)
          .map { [Regexp.last_match[:name].delete('"'), Regexp.last_match[0]] }
          .sort_by(&:first)
          .map(&:last)
          .join
      end

      dump
    end
  end
end
