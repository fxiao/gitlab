# frozen_string_literal: true

module Groups
  class PackagesController < Groups::ApplicationController
    include SortingHelper

    before_action :verify_packages_enabled!

    def index
      @packages = ::Packages::GroupPackagesFinder.new(current_user, group)
        .execute
        .sort_by_attribute(@sort = params[:sort] || sort_value_recently_created)
        .page(params[:page])
    end

    private

    def verify_packages_enabled!
      render_404 unless group.packages_feature_available?
    end
  end
end
