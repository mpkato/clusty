class ClustersController < InheritedResources::Base

  private

    def cluster_params
      params.require(:cluster).permit(:name, :project_id)
    end
end

