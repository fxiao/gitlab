# frozen_string_literal: true

class Groups::SeatUsageController < Groups::ApplicationController
  before_action :verify_top_level_group
  before_action :authorize_admin_group_member!
  before_action :verify_namespace_plan_check_enabled

  layout "group_settings"

  feature_category :purchase

  def show
    respond_to do |format|
      format.html do
      end

      format.csv do
        result = Groups::SeatUsageExportService.execute(group, current_user)

        if result.success?
          stream_csv_headers(csv_filename)

          self.response_body = result.payload
        else
          flash[:alert] = _('Failed to generate export, please try again later.')

          redirect_to group_seat_usage_path(group)
        end
      end
    end
  end

  private

  def csv_filename
    "seat-usage-export-#{Time.current.to_s(:number)}.csv"
  end

  def verify_top_level_group
    not_found unless group.root?
  end
end
