require "dolzenko/remote_download"

module Scholarly
  class GoogleCodeSearch
    RAILS_QUERIES = ["lang:ruby RAILS_GEM_VERSION\\s=\\s['\"]2 file:environment\\.rb",
            "lang:ruby RAILS_GEM_VERSION\\s=\\s['\"]2\\.3\\.2 file:environment\\.rb",
            "lang:ruby RAILS_GEM_VERSION\\s=\\s['\"]2\\.3\\.3 file:environment\\.rb",
            "lang:ruby RAILS_GEM_VERSION\\s=\\s['\"]2\\.3\\.4 file:environment\\.rb",
            "lang:ruby RAILS_GEM_VERSION\\s=\\s['\"]2\\.3\\.5 file:environment\\.rb",
            "lang:ruby RAILS_GEM_VERSION\\s=\\s['\"]2\\.3\\.6 file:environment\\.rb",
            "lang:ruby RAILS_GEM_VERSION\\s=\\s['\"]2\\.3\\.0 file:environment\\.rb",
            "lang:ruby RAILS_GEM_VERSION\\s=\\s['\"]2\\.3\\.1 file:environment\\.rb",
            "lang:ruby RAILS_GEM_VERSION\\s=\\s['\"]2\\.2\\.3 file:environment\\.rb",
            "lang:ruby RAILS_GEM_VERSION\\s=\\s['\"]2\\.2\\.2 file:environment\\.rb",
            "lang:ruby RAILS_GEM_VERSION\\s=\\s['\"]2\\.2\\.1 file:environment\\.rb",
            "lang:ruby RAILS_GEM_VERSION\\s=\\s['\"]2\\.2\\.0 file:environment\\.rb",
            "lang:ruby RAILS_GEM_VERSION\\s=\\s['\"]2\\.1\\.2 file:environment\\.rb",
            "lang:ruby RAILS_GEM_VERSION\\s=\\s['\"]2\\.1\\.1 file:environment\\.rb",
            "lang:ruby RAILS_GEM_VERSION\\s=\\s['\"]2\\.1\\.0 file:environment\\.rb",
            "lang:ruby RAILS_GEM_VERSION\\s=\\s['\"]2\\.0\\.1 file:environment\\.rb",
            "lang:ruby RAILS_GEM_VERSION\\s=\\s['\"]2\\.0\\.2 file:environment\\.rb",
            "lang:ruby RAILS_GEM_VERSION\\s=\\s['\"]2\\.0\\.3 file:environment\\.rb",
            "lang:ruby RAILS_GEM_VERSION\\s=\\s['\"]2\\.0\\.4 file:environment\\.rb",
            "lang:ruby RAILS_GEM_VERSION\\s=\\s['\"]2\\.0\\.5 file:environment\\.rb",].reverse

    # Returns all repository uris for queries
    def self.repository_uris
      if GoogleCodeSearchResult.count == 0
        for q in RAILS_QUERIES
          start(q)
        end
      end
      cached_repository_uris
    end

    def self.cached_repository_uris
      GoogleCodeSearchResult.all.map do |res|
        d = Nokogiri::XML(res.result)
        d.remove_namespaces!
        d.xpath("//package").map { |package| package["uri"] }
      end.flatten.uniq.compact
    end

    private

    def self.start(q)
      uri = "http://www.google.com/codesearch/feeds/search?#{ { :q => q }.to_query }"

      while result = Dolzenko::RemoteDownload.download_page(uri)
        d = Nokogiri::XML(result)
        d.remove_namespaces!

        if GoogleCodeSearchResult.exists?(:uri => uri)
          puts "skipped #{ uri }... "
        else
          puts "stored result of #{ uri }"
          GoogleCodeSearchResult.create!(:start_index => d.xpath("//startIndex")[0].text,
                                         :result => result,
                                         :uri => uri)
        end
        next_link = d.xpath("//link").detect { |link| link["rel"] == "next" }
        unless next_link
          puts "next_link not found"
          break
        end
        new_uri = next_link["href"]
        break if new_uri == uri
        uri = new_uri
      end
    end
  end
end