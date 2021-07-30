# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::SeatUsageController do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group, :private) }

  describe 'GET show' do
    before do
      sign_in(user)
      stub_application_setting(check_namespace_plan: true)
    end

    def get_show(format: :html)
      get :show, params: { group_id: group }, format: format
    end

    subject { response }

    context 'when authorized' do
      before do
        group.add_owner(user)
      end

      context 'when html format' do
        before do
          stub_feature_flags(seat_usage_export: false)
        end

        it 'renders show with 200 status code' do
          get_show

          expect(response).to have_gitlab_http_status(:ok)
          expect(response).to render_template(:show)
        end
      end

      context 'when csv format' do
        context 'when seat_usage_export feature flag is disabled' do
          before do
            stub_feature_flags(seat_usage_export: false)
          end

          it 'responds with 404 status code' do
            get_show(format: :csv)

            expect(response).to have_gitlab_http_status(:not_found)
          end
        end

        context 'when seat_usage_export feature flag is enabled' do
          before do
            stub_feature_flags(seat_usage_export: true)
            expect(Groups::SeatUsageExportService).to receive(:execute).with(group, user).and_return(result)
          end

          context 'when export is successful' do
            let(:csv_data) do
              <<~CSV
                Name,Username,State
                Administrator,root,active
              CSV
            end

            let(:result) { ServiceResponse.success(payload: csv_data) }

            it 'streams the csv with 200 status code' do
              get_show(format: :csv)

              expect(response).to have_gitlab_http_status(:ok)
              expect(response.headers['Content-Type']).to eq('text/csv; charset=utf-8; header=present')
              expect(response.body).to eq(csv_data)
            end
          end

          context 'when export fails' do
            let(:result) { ServiceResponse.error(message: 'Something went wrong!') }

            it 'sets alert message and redirects' do
              get_show(format: :csv)

              expect(flash[:alert]).to eq 'Failed to generate export, please try again later.'
              expect(response).to redirect_to(group_seat_usage_path(group))
            end
          end
        end
      end
    end

    context 'when unauthorized' do
      before do
        group.add_developer(user)
      end

      context 'when html format' do
        it 'renders 403 when user is not an owner' do
          get_show

          is_expected.to have_gitlab_http_status(:forbidden)
        end
      end

      context 'when csv format' do
        it 'renders 403 when user is not an owner' do
          get_show(format: :csv)

          is_expected.to have_gitlab_http_status(:forbidden)
        end
      end
    end
  end
end
