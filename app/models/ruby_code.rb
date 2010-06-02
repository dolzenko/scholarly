class RubyCode < ActiveRecord::Base
  validates :uri, :uniqueness => true

  scope :cloned, where(:clone_state => "cloned")

  def file_uri_from_local_path(local_path)
    raise ArgumentError unless github?
    repo_path = file_repo_path_from_local_path(local_path)
    repo_root_uri = uri.sub(/^git:\/\//, "http://").sub(/\.git$/, "")
    File.join(repo_root_uri, "blob/master", repo_path)
  end

  # Calculates path from repo root from the local clone file path
  def file_repo_path_from_local_path(local_path)
    local_path.sub(/^#{ Regexp.escape path }/, "")
  end

  def github?
    uri.include?("git://github.com")
  end
end
