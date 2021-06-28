# frozen_string_literal: true

class Projects::RunnersController < Projects::ApplicationController
  before_action :authorize_admin_build!
  before_action :runner, only: [:edit, :update, :destroy, :pause, :resume, :show]

  feature_category :runner

  def index
    unless Feature.enabled?(:runner_list_project_view_vue_ui, @project, default_enabled: :yaml)
      render_404
    end
  end

  def settings
    redirect_to project_settings_ci_cd_path(@project, anchor: 'js-runners-settings')
  end

  def edit
  end

  def update
    if Ci::UpdateRunnerService.new(@runner).update(runner_params)
      redirect_to project_runner_path(@project, @runner), notice: _('Runner was successfully updated.')
    else
      render 'edit'
    end
  end

  def destroy
    if @runner.only_for?(project)
      @runner.destroy
    end

    redirect_to settings_project_runners_path(@project), status: :found
  end

  def resume
    if Ci::UpdateRunnerService.new(@runner).update(active: true)
      redirect_to settings_project_runners_path(@project), notice: _('Runner was successfully updated.')
    else
      redirect_to settings_project_runners_path(@project), alert: _('Runner was not updated.')
    end
  end

  def pause
    if Ci::UpdateRunnerService.new(@runner).update(active: false)
      redirect_to settings_project_runners_path(@project), notice: _('Runner was successfully updated.')
    else
      redirect_to settings_project_runners_path(@project), alert: _('Runner was not updated.')
    end
  end

  def show
  end

  def toggle_shared_runners
    update_params = { shared_runners_enabled: !project.shared_runners_enabled }
    result = Projects::UpdateService.new(project, current_user, update_params).execute

    if result[:status] == :success
      render json: {}, status: :ok
    else
      render json: { error: result[:message] }, status: :unauthorized
    end
  end

  def toggle_group_runners
    project.toggle_ci_cd_settings!(:group_runners_enabled)

    redirect_to project_settings_ci_cd_path(@project, anchor: 'js-runners-settings')
  end

  protected

  def runner
    @runner ||= project.runners.find(params[:id])
  end

  def runner_params
    params.require(:runner).permit(Ci::Runner::FORM_EDITABLE)
  end
end
