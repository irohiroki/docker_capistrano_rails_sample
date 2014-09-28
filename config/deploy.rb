# config valid only for Capistrano 3.1
lock '3.2.1'

set :application, 'docker_capistrano_rails_sample'
set :repo_url, 'git@github.com:irohiroki/docker_capistrano_rails_sample.git'
set :containers_log, deploy_path + 'containers.log'

# Default branch is :master
# ask :branch, proc { `git rev-parse --abbrev-ref HEAD`.chomp }.call

# Default deploy_to directory is /var/www/my_app
# set :deploy_to, '/var/www/my_app'

# Default value for :scm is :git
# set :scm, :git

# Default value for :format is :pretty
# set :format, :pretty

# Default value for :log_level is :debug
# set :log_level, :debug

# Default value for :pty is false
set :pty, true  # for sudo

# Default value for :linked_files is []
# set :linked_files, %w{config/database.yml}

# Default value for linked_dirs is []
# set :linked_dirs, %w{bin log tmp/pids tmp/cache tmp/sockets vendor/bundle public/system}

# Default value for default_env is {}
# set :default_env, { path: "/opt/ruby/bin:$PATH" }

# Default value for keep_releases is 5
# set :keep_releases, 5

def docker_run_opts
  %W(
    -e RAILS_ENV=#{fetch(:rails_env)}
    -e SECRET_KEY_BASE=#{fetch(:secret_key_base)}
    -e DB_HOST=#{fetch(:db_host)}
    -e DB_USERNAME=#{fetch(:db_username)}
    -e DB_PASSWORD=#{fetch(:db_password)}
    -v #{shared_path}/log:/app/log
    -v #{shared_path}/public/assets:/app/public/assets
    -v #{shared_path}/tmp/cache:/app/tmp/cache
    -v #{shared_path}/tmp/sessions:/app/tmp/sessions
    -v #{shared_path}/tmp/sockets:/app/tmp/sockets
    #{fetch(:application)}
  )
end

namespace :deploy do
  namespace :docker do
    desc 'Make rake run in container'
    task :map_rake do
      SSHKit.config.command_map[:rake] = "sudo docker run --rm #{docker_run_opts.join(' ')} rake"
    end

    before 'deploy:updated', 'deploy:docker:map_rake'

    desc 'Build image'
    task :build do
      on roles(:app) do
        within release_path do
          sudo :docker, "build", "-t", fetch(:application), "."
        end
      end
    end

    after 'deploy:updating', 'deploy:docker:build'

    desc 'Run application container'
    task :run do
      on roles(:app) do
        set :cid, capture(:sudo, "docker", "run", "-d", "-P", *docker_run_opts)
        set :host_port, capture(:sudo, "docker", "port", fetch(:cid), 3000)
      end
    end

    desc 'Stop old container'
    task :stop do
      on roles(:app) do
        if test "[ -e #{fetch(:containers_log)} ]"
          old_cid = capture(:tail, "-1", fetch(:containers_log)).split(' ').last
          test :sudo, "docker", "stop", old_cid  # ignore failure
        end
      end
    end

    desc 'Log container id'
    task :log do
      on roles(:app) do
        execute %|echo "Tree #{fetch(:current_revision)} run in #{fetch(:cid)}" >> #{fetch(:containers_log)}|
      end
    end

    after 'deploy:docker:run', 'deploy:docker:stop'
    after 'deploy:docker:run', 'deploy:docker:log'
  end

  # example task to reconfigure web server
  # namespace :web do
  #   desc 'Restart web frontend'
  #   task :restart do
  #     on roles(:web) do
  #       sudo :sed, "-i", "/proxy_pass/s/[0-9][.:0-9]*/#{fetch(:host_port)}/", "/etc/nginx/sites-available/app"
  #       sudo :service, "nginx", "reload"
  #     end
  #   end
  # end

  desc 'Restart application'
  task :restart do
    invoke 'deploy:docker:run'
    # route your web server to the new container. eg.:
    # invoke 'deploy:web:restart'
  end

  after :publishing, :restart

  after :restart, :clear_cache do
    on roles(:web), in: :groups, limit: 3, wait: 10 do
      # Here we can do anything such as:
      # within release_path do
      #   execute :rake, 'cache:clear'
      # end
    end
  end

end
