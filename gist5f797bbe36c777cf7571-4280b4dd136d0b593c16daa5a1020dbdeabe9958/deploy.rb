require "rvm/capistrano"
require "bundler/capistrano"

  # replace <your app anme> with the name of your app
  	set :application, "blog_app"
	
  # user the same ruby as used locally for deployment
	set :rvm_ruby_string, :local
	

	set :scm, :git
	set :username, "socialcloud"
  # replace <your github repo uri> with the uri of your github repo
	set :repository, "git@github.com:CorreyS/blog_app.git"
	set :branch, "master"
	set :use_sudo, true

  # replace <your server dns name> with the dns name of your server
	server "socialclouddev.cloudapp.net", :web, :app, :db, primary: true

	set :deploy_to, "/home/#{username}/apps/#{application}"
	default_run_options[:pty] = true
	ssh_options[:forward_agent] = true

  # install rvm if not installed, and install ruby as well
	before 'deploy', 'rvm:install_rvm'
	before 'deploy', 'rvm:install_ruby'

	namespace :deploy do
	  desc "Remove mingw32 extensions from Gemfile.lock to re-bundle under LINUX"
	  task :rm_mingw32, :except => { :no_release => true }, :role => :app do
	    puts " modifying Gemfile.lock ... removing mingw32 platform ext. before re-bundling on LINUX"
	    run "sed 's/-x86-mingw32//' #{release_path}/Gemfile.lock > #{release_path}/Gemfile.tmp && mv #{release_path}/Gemfile.tmp #{release_path}/Gemfile.lock"
	    run "sed -n '/PLATFORMS/ a\ ruby' #{release_path}/Gemfile.lock"
	  end

	  desc "Fix permission"
	  task :fix_permissions, :roles => [ :app, :db, :web ] do
	    run "chmod +x #{release_path}/config/unicorn_init.sh"
	  end

	  %w[start stop restart].each do |command|
	    desc "#{command} unicorn server"
	    task command, roles: :app, except: {no_release: true} do
	      run "service unicorn_#{application} #{command}"
	    end
	  end

	  task :setup_config, roles: :app do
	    sudo "ln -nfs #{current_path}/config/nginx.conf /etc/nginx/sites-enabled/#{application}"
	    sudo "ln -nfs #{current_path}/config/unicorn_init.sh /etc/init.d/unicorn_#{application}"
	    sudo "mkdir -p #{shared_path}/config"
	  end
	  after "deploy:setup", "deploy:setup_config"

	  task :symlink_config, roles: :app do
	    # db migrate
	    "deploy:migrate" 	
	  end

	  before "bundle:install", "deploy:rm_mingw32"
	  after "deploy:finalize_update", "deploy:fix_permissions"
	  after "deploy:finalize_update", "deploy:symlink_config"
	end