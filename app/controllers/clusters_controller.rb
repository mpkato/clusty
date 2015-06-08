class ClustersController < ApplicationController
  before_action :set_project
  before_action :set_cluster, only: [:show, :edit, :update, :destroy]

  # GET /clusters.json
  def index
    @clusters = @project.clusters.includes(:elements)
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
    if @cluster.update(cluster_params)
      render :show, status: :ok, location: @cluster
    else
      render json: @cluster.errors, status: :unprocessable_entity
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
      @project = Project.includes(:clusters).find(params[:project_id])
    end

    # Use callbacks to share common setup or constraints between actions.
    def set_cluster
      @cluster = Cluster.includes(:elements).find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def cluster_params
      params.require(:cluster).permit(:name, :project_id)
    end
end

