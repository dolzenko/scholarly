require "dolzenko/remote_download"

module Scholarly
  class GitHubCodeSearch
# Returns all repository uris for queries
    def self.repository_uris
      if GitHubCodeSearchResult.count == 0
        start
      end
      cached_repository_uris
    end

    def self.cached_repository_uris
      GitHubCodeSearchResult.all.map do |res|

        d = Nokogiri::HTML.parse(res.result)
        d.remove_namespaces!
        d.css("a").select do |link|
          link["href"] =~ /environment\.rb$/
        end.map do |link|
          "git://github.com#{ link["href"].split("/").first(3).join("/") }.git"
        end
      end.flatten.uniq.compact
    end

    # protected

    def self.start
      start_value = 1
      uri = search_result_page_uri(start_value)

      while result = Dolzenko::RemoteDownload.download_page(uri)
        d = Nokogiri::HTML.parse(result)
        d.remove_namespaces!

        if GitHubCodeSearchResult.exists?(:uri => uri)
          puts "skipped #{ uri }... "
        else
          puts "stored result of #{ uri }"
          GitHubCodeSearchResult.create!(:start_index => start_value,
                                         :result => result,
                                         :uri => uri)
        end

        start_value += 1
        uri = search_result_page_uri(start_value)
      end
    end

    def self.search_result_page_uri(start_value)
      "http://github.com/search?type=Code&language=ruby&q=RAILS_GEM_VERSION&repo=&langOverride=&start_value=#{start_value}&x=18&y=17"
    end
  end
end