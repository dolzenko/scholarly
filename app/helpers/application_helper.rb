module ApplicationHelper
  def local_path_to_uri(local_path)
    return local_path unless local_path.include?("github.com")
    parts = local_path.split("/")
    github_index = parts.index("github.com")
    repo_path = parts[github_index + 3 .. -1].join("/")
    repo_root_uri = File.join("http://", parts[github_index .. github_index + 2].join("/"), "blob/master")
    File.join(repo_root_uri, repo_path)
  end

  def highlight(source)
    raw("<pre>" + CodeRay.scan(source, :ruby).html(:css => :style) + "</pre>")
  end
end
