module ApplicationHelper
  def local_path_to_uri(local_path)
    if local_path.include?("github.com")
      local_github_path_to_uri(local_path)
    elsif local_path.include?(".gem/")
      local_gem_path_to_uri(local_path)
    else
      local_path
    end
  end

  def local_github_path_to_uri(local_github_path)
    parts = local_github_path.split("/")
    github_index = parts.index("github.com")
    repo_path = parts[github_index + 3 .. -1].join("/")
    repo_root_uri = File.join("http://", parts[github_index .. github_index + 2].join("/"), "blob/master")
    File.join(repo_root_uri, repo_path)
  end

  # Maps
  # /mnt/hgfs/ubuntu_shared/scholarly/silo/rubygems/cache/3mix-castronaut-0.5.0.2.gem/vendor/sinatra/lib/sinatra.rb
  # to
  # http://github.com/3mix/castronaut/blob/master/vendor/sinatra/lib/sinatra.rb
  def local_gem_path_to_uri(local_gem_path)

    parts = local_gem_path.split("/")
    gem_name_index = parts.index { |part| part =~ /\.gem$/ }

    gem_name  = parts[gem_name_index]
    owner, *repo, _ = gem_name.split("-")
    repo = repo.join("-")

    file_path = parts[gem_name_index + 1 .. -1].join("/")
    File.join("http://github.com/", owner, repo, "blob/master", file_path)
  end

  def highlight(source)
    raw("<pre>" + CodeRay.scan(source, :ruby).html(:css => :style) + "</pre>")
  end
end
