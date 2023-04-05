class AddPrefixesToTags < ActiveRecord::Migration[5.2]
  def change
    execute "set statement_timeout = 0"
    execute "CREATE INDEX index_tags_on_name_prefix ON tags USING gin (REGEXP_REPLACE(name, '([a-z0-9])[a-z0-9'']*($|[^a-z0-9'']+)', '\\1', 'g') gin_trgm_ops) WHERE post_count > 0"
  end
end
