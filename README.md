## Scholarly

Scrupulously studies ~5000 Rails open source projects. This was the experiment
to discover some API usage patterns in Rails project. The internal design is
emergent at best (read that as: absent).

It can be used to generate report like these:

## Hacking

### Preliminary Steps

    > git clone git://github.com/dolzenko/scholarly.git
    > cd scholarly
    > rvm use ruby-1.9.2-head
    > rvm gemset create scholarly
    > rvm gemset use scholarly
    > gem install bundler
    > bundle install

### Retrieving Codes

Code retrieval is split in two phases: repositories URI retrieval and actual
cloning of repositories. Database of ~5000 Rails projects URIs is already
included in `db/development.sqlite3`.

To clone repositories

    

Scholarly comes with scrapers to GitHub and Google Code Search which can fetch
the links to Rails projects. As any screen scraper these are pretty ad-hoc and
fragile so the database of ~5000 Rails projects is already included in
`db/development.sqlite3`.

To scrape GitHub and Google Code Search again replacing bundled DB entries:

    > rails runner 'Scholarly::GoogleCodeSearch.cache_results!'
    > rails runner 'Scholarly::GitHubCodeSearch.cache_results!'
    > rails runner 'Scholarly::CodeCollector.update_rails_codes_from_cached_uris!'


The next step is to clone a bunch of

### Writing Scholars

Scholars which study codes live in `lib/scholarly/scholars` and inherit from
`Scholarly::Base`. Scholars define code they're interested in

  class ValidatesPresenceOfBelongsTo < Scholarly::Base
    self.code_class = "RailsCode"
    self.path_glob = "app/models/**/*.rb"
    self.studies_descendants_of = "ActiveRecord::Base"

    def study(class_level_statements, env)
    end
  end

Then instance method `study` is called for each studied file.