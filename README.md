## Scholarly

Scrupulously studies ~5000 Rails open source projects. This was the experiment
to discover some API usage patterns in Rails project. The internal design is
emergent at best (read that as: absent). Based on `Ripper` parser bundled with
Ruby 1.9.2.

It can be used to generate report like these:

[Association as <code>delegate</code> target report](http://dolzhenko.org/scholarly/assoc_name_as_delegate_target/report.htm)

[Validation of <code>belongs_to</code> association report](http://dolzhenko.org/scholarly/validates_presence_of_belongs_to/report.htm)

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

    > rails runner 'Scholarly::CodeCollector.collect_rails!'

This will clone under the `silo/` directory, to exclude humongous repositories
any `git clone` process which takes longer than 5 minutes will be interrupted,
and repository will be excluded from cloning.

Scholarly comes with scrapers to GitHub and Google Code Search which can fetch
the links to Rails projects. As any screen scraper these are pretty ad-hoc and
fragile.

To scrape GitHub and Google Code Search again replacing bundled DB entries:

    > rails runner 'Scholarly::GoogleCodeSearch.cache_results!'
    > rails runner 'Scholarly::GitHubCodeSearch.cache_results!'
    > rails runner 'Scholarly::CodeCollector.update_rails_codes_from_cached_uris!'


### Writing Scholars

Scholars which study codes live in `lib/scholarly/scholars` and inherit from
`Scholarly::Base`. Scholars define code they're interested in

    class ValidatesPresenceOfBelongsTo < Scholarly::Base
      self.code_class = "RailsCode"
      self.path_glob = "app/models/**/*.rb"
      self.studies_descendants_of = "ActiveRecord::Base"

      def study(ast, env)
        # called for each studied file
        # study passed ast here and accumulate results in instance variables
      end
    end

### Start Studying

Both bundled Scholars have controllers to format the results. Start Scholarly
with

    rails s

navigate to [http://localhost:3000](http://localhost:3000) and start studying!

MIT License. Copyright &copy; 2010 Evgeniy Dolzhenko.
[http://dolzhenko.org](http://dolzhenko.org)