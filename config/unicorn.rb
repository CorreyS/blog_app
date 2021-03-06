worker_processes 2
timeout 30
listen "/tmp/unicorn.blog.sock"

# replace <your app name> with the name of your app
root = "/home/socialcloud/apps/blog_app/current"

working_directory root

pid "#{root}/tmp/pids/unicorn.pid"
stderr_path "#{root}/log/unicorn.log"
stdout_path "#{root}/log/unicorn.log"