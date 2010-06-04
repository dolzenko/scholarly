require "dolzenko/remote_download"

module Scholarly
  class GitHubCodeSearch

    def self.cache_results!
      GitHubCodeSearchResult.delete_all
      start
    end

    # Returns all repository uris for queries
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
    MAX_START_VALUE = 282 # number of pages here http://github.com/search?type=Code&language=ruby&q=RAILS_GEM_VERSION&repo=&langOverride=&start_value=1&x=6&y=28
    def self.start
      start_value = 1
      uri = search_result_page_uri(start_value)

      while result = Dolzenko::RemoteDownload.download_page(uri)
        break unless result
        break if result.empty?
        
        d = Nokogiri::HTML.parse(result)
        d.remove_namespaces!

        if GitHubCodeSearchResult.exists?(:uri => uri)
          puts "Skipped #{ uri } (already exists in DB)"
        else
          GitHubCodeSearchResult.create!(:start_index => start_value,
                                         :result => result,
                                         :uri => uri)
          puts "Stored result of #{ uri }"
        end

        start_value += 1
        uri = search_result_page_uri(start_value)

        break if start_value > MAX_START_VALUE
      end
    end

    def self.search_result_page_uri(start_value)
      "http://github.com/search?type=Code&language=ruby&q=RAILS_GEM_VERSION&repo=&langOverride=&start_value=#{start_value}&x=18&y=17"
    end
  end
end