namespace :edit do
  desc 'copy the projects'
  task :copy => :environment do
    src = ENV['src']
    dst = ENV['dst']
    Project.transaction do
      projects = Project.where(user_id: src).all
      projects.each do |project|
        new_project = project.dup
        new_project.user_id = dst
        new_project.save!(validate: false)
        cluster_elem = {}
        project.elements.each do |elem|
          new_elem = elem.dup
          new_elem.project_id = new_project.id
          new_elem.save!
          elem.clusters.each do |cluster|
            cluster_elem[cluster.id] ||= []
            cluster_elem[cluster.id] << new_elem
          end
        end
        project.clusters.each do |cluster|
          new_cluster = cluster.dup
          new_cluster.project_id = new_project.id
          new_cluster.save!
          if cluster_elem.include?(cluster.id)
            cluster_elem[cluster.id].each do |elem|
              new_cluster.elements << elem
            end
          end
        end
      end
    end
  end
end

