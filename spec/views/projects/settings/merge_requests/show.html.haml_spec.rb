# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'projects/settings/merge_requests/show' do
  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user) }

  let_it_be(:error_tracking_setting) do
    create(:project_error_tracking_setting, project: project)
  end

  let_it_be_with_reload(:tracing_setting) do
    create(:project_tracing_setting, project: project)
  end

  let_it_be(:prometheus_service) { create(:prometheus_service, project: project) }

  before_all do
    project.add_maintainer(user)
  end

  before do
    assign :project, project

    allow(view).to receive(:error_tracking_setting)
      .and_return(error_tracking_setting)
    allow(view).to receive(:tracing_setting)
      .and_return(tracing_setting)
    allow(view).to receive(:prometheus_service)
      .and_return(prometheus_service)
    allow(view).to receive(:current_user).and_return(user)
  end

  describe 'Merge requests' do
    it 'renders the Merge requests settings page' do
      render

      expect(rendered).to have_content _('Merge requests')
      expect(rendered).to have_content _('Choose your merge method, merge options, merge checks, merge suggestions, and set up a default description template for merge requests.')
    end
  end
end
