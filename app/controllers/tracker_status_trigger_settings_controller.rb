class TrackerStatusTriggerSettingsController < ApplicationController
  unloadable
  def new
    @tst = TrackerStatusTriggerSetting.new
  end
  
  def show
  end
  
  # TODO: melhorar esse redirecionamento
  def redirect_to_main_screen
    redirect_to Redmine::Utils::relative_url_root + '/settings/plugin/redmine_tracker_status_trigger'
  end
  
  def edit
    @tst = TrackerStatusTriggerSetting.find(params[:id])
  end
  
  def update
    params.require(:tracker_status_trigger_setting).permit(:tracker_id, :status_id_change_from, :status_id_change_to, :relation, :relation_tracker_id, :upd_status_id_from, :upd_status_id_to)
    @tst = TrackerStatusTriggerSetting.find(params[:id])
    @tst.save(params[:tracker_status_trigger_setting])
    
    @tst.tracker_id = params[:tracker_status_trigger_setting][:tracker_id]
    @tst.status_id_change_from = params[:tracker_status_trigger_setting][:status_id_change_from]
    @tst.status_id_change_to = params[:tracker_status_trigger_setting][:status_id_change_to]
    @tst.relation = params[:tracker_status_trigger_setting][:relation]
    @tst.relation_tracker_id = params[:tracker_status_trigger_setting][:relation_tracker_id]
    @tst.upd_status_id_from = params[:tracker_status_trigger_setting][:upd_status_id_from]
    @tst.upd_status_id_to = params[:tracker_status_trigger_setting][:upd_status_id_to]
    @tst.save

    respond_to do |format|
      format.html { 
        flash[:notice] = l(:label_successfully_update)
        redirect_to_main_screen
      }
      format.xml  { head :ok }
    end
  end
  
  def create
    params.require(:tracker_status_trigger_setting).permit!
    @tst = TrackerStatusTriggerSetting.create(params[:tracker_status_trigger_setting])
    respond_to do |format|
      format.html { 
        flash[:notice] = l(:label_successfully_create)
        redirect_to_main_screen
      }
      format.xml  { head :ok }
    end
  end
  
  def index
    @tst = TrackerStatusTriggerSetting.first
  end
  
  def destroy
    @tst = TrackerStatusTriggerSetting.find(params[:id])
    @tst.destroy
    
    respond_to do |format|
      format.html { 
        flash[:notice] = l(:label_successfully_delete)
        redirect_to_main_screen
      }
      format.xml  { head :ok }
    end
  end
end
