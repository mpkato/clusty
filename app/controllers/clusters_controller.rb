class ClustersController < ApplicationController
  before_action :set_project
  before_action :set_cluster, only: [:show, :edit, :update, :destroy]

  # GET /clusters.json
  def index
    @clusters = @project.clusters.to_a
    @clusters << Cluster.new(elements: find_orphans)
  end

  # GET /clusters/1.json
  def show
  end

  # POST /clusters.json
  def create
    @cluster = Cluster.new(cluster_params)

    if @cluster.save
      render :show, status: :created, location: @cluster
    else
      render json: @cluster.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /clusters/1.json
  def update
    if @cluster.id.nil? # orphans
      render :show, status: :ok, location: @cluster
    else
      case cluster_params[:method]
      when 'create'
        @cluster.elements << @project.elements.find(cluster_params[:element_id])
        render :show, status: :ok, location: @cluster
      when 'destroy'
        @cluster.elements.delete(@project.elements.find(cluster_params[:element_id]))
        render :show, status: :ok, location: @cluster
      when 'update'
        @cluster.update(name: cluster_params[:name])
        render :show, status: :ok, location: @cluster
      else
        render json: @cluster.errors, status: :unprocessable_entity
      end
    end
  end

  # DELETE /clusters/1.json
  def destroy
    @cluster.destroy
    head :no_content
  end

  private

    # Use callbacks to share common setup or constraints between actions.
    def set_project
      @project = Project.includes([:elements, clusters: :elements]).find(params[:project_id])
    end

    # Use callbacks to share common setup or constraints between actions.
    def set_cluster
      if params[:id].to_i == -1
        # orphans
        @cluster = Cluster.new(elements: find_orphans)
      else
        @cluster = Cluster.includes(:elements).find(params[:id])
      end
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def cluster_params
      params.require(:cluster).permit(:name, :project_id, :element_id, :method)
    end
    
    # Find elements that do not belong to any cluster
    def find_orphans
      clustered_elements = Set.new()
      @project.clusters.each {|c| c.elements.each {|e| clustered_elements << e}}
      orphans = @project.elements.select {|e| not clustered_elements.include?(e)}
      return orphans
    end
end

