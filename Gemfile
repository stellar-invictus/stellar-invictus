source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '3.1.2'

gem 'rails', '6.1.7'
gem 'sassc-rails'
gem 'uglifier'
gem 'coffee-rails'
gem 'turbolinks'
gem 'jquery-rails'
gem 'redis', '4.5.0'
gem 'puma'

# Docker
gem 'tzinfo-data'

group :development do
  gem 'listen', '>= 3.0.5', '< 3.3'
  gem 'spring'
  gem 'spring-watcher-listen', '~> 2.0.0'
  gem 'bullet'
  gem 'action-cable-testing' # remove when on Rails 6+
end

group :development, :test do
  gem 'rspec-rails'
  gem 'shoulda-matchers'
  gem 'factory_bot_rails'
  gem 'database_cleaner'
  gem 'rails-controller-testing'
  gem 'simplecov'
  gem 'fuubar'
  gem 'awesome_print'
  gem 'annotate', require: false  # annotate models with their schemas
end

group :production, :development do
  gem 'pg'
end

# Authentication through devise
gem 'devise'
# Client-Side Validations
gem 'client_side_validations'
# Sidekiq for Jobs
gem 'sidekiq'
# Pagination
gem 'kaminari'
gem 'bootstrap4-kaminari-views'
# Faker for Names
gem 'faker'
# Redcarpet for Markdown Player Bios
gem 'redcarpet'
# Jquery-UI for drag and drop
gem 'jquery-ui-rails'
# Whenever for CronJobs
gem 'whenever', require: false
# Perlin Noise for Market
gem 'perlin_noise'
# Dotenv for ENV Variables
gem 'dotenv-rails'
# Acts as Votable for Polls
gem 'acts_as_votable'
# Recaptcha for Registration
gem 'recaptcha'
# Bugsnag for Errors
gem 'bugsnag'
# Social Logins
gem 'omniauth-google-oauth2'
gem 'omniauth-facebook'
# Turnout for maintenance mode
gem 'turnout'
# Hoverintent for faster page loads
gem 'rails-assets-jquery-hoverintent', source: 'https://rails-assets.org'
# Rubocop
gem 'rubocop'
gem 'rubocop-rspec'
# For Service Object functionality
gem 'dry-initializer'
gem 'dry-monads'
gem 'net-smtp'
gem 'matrix'
gem 'sqlite3'
