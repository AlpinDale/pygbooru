class AddIndexUpdatedAtOnPoolVersions < ActiveRecord::Migration[4.2]
  def up
    execute "set statement_timeout = 0"
    add_index :pool_versions, :updated_at
  end

  def down
    execute "set statement_timeout = 0"
    remove_index :pool_versions, :updated_at
  end
end
