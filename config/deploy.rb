after 'deploy:published', 'clean:restart'
after 'deploy:published', 'pathfinder:generate_paths'
after 'deploy:published', 'pathfinder:generate_mapdata'

set :application, "stellar"
set :repo_url, "git@github.com:venarius/stellarInvictusRails.git"

# Default branch is :master
# ask :branch, `git rev-parse --abbrev-ref HEAD`.chomp

# Default deploy_to directory is /var/www/my_app_name
set :deploy_to, "/home/deploy/app/stellar"

# Default value for :format is :airbrussh.
# set :format, :airbrussh

# You can configure the Airbrussh format using :format_options.
# These are the defaults.
# set :format_options, command_output: true, log_file: "log/capistrano.log", color: :auto, truncate: :auto

# Default value for :pty is false
# set :pty, true

# Default value for :linked_files is []
# append :linked_files, "config/database.yml"

# Default value for linked_dirs is []
append :linked_dirs, "log", "tmp/pids", "tmp/cache", "tmp/sockets", "public/system", "certificates"

# Default value for default_env is {}
# set :default_env, { path: "/opt/ruby/bin:$PATH" }

# Default value for local_user is ENV['USER']
# set :local_user, -> { `git config user.name`.chomp }

# Default value for keep_releases is 5
# set :keep_releases, 5

# Uncomment the following to require manually verifying the host key before first deploy.
# set :ssh_options, verify_host_key: :secure

# Master Key
set :linked_files, %w{config/master.key .env}

namespace :deploy do
  desc "reload the database with seed data"
  task :seed do
    on roles(:app) do
      execute "cd #{current_path}; ~/.rvm/bin/rvm default do bundle exec rails db:seed RAILS_ENV=production"
    end
  end
end

namespace :clean do
  desc 'Cleans up for restart'
  task :restart do
    on roles(:app) do
      within release_path do
        with rails_env: fetch(:rails_env) do
          execute :rake, 'clean:restart'
        end
      end
    end
  end
end

namespace :pathfinder do
  desc 'Generates Paths'
  task :generate_paths do
    on roles(:app) do
      within release_path do
        with rails_env: fetch(:rails_env) do
          execute :rake, 'pathfinder:generate_paths'
        end
      end
    end
  end
  
  desc 'Generates Mapdata'
  task :generate_mapdata do
    on roles(:app) do
      within release_path do
        with rails_env: fetch(:rails_env) do
          execute :rake, 'pathfinder:generate_mapdata'
        end
      end
    end
  end
end

# Whenever
set :whenever_roles, ["app", "db"]