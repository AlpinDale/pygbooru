# frozen_string_literal: true

# A null StorageManager that doesn't store files at all. Used for testing or
# disabling backups.
class StorageManager::Null < StorageManager
  def initialize
    super(base_url: nil)
  end

  def store(src_file, path)
    # no-op
  end

  def delete(path)
    # no-op
  end

  def open(path)
    # no-op
  end
end
