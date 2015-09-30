namespace :edit do
  desc 'copy the projects'
  task :copy do
    on roles(:app), in: :groups, limit: 3 do
      within current_path do
        with rails_env: :production do
          execute :rake, 'edit:copy', "src=#{ENV["src"]}", "dst=#{ENV["dst"]}"
        end
      end
    end
  end
end
