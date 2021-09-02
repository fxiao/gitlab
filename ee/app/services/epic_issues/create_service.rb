# frozen_string_literal: true

module EpicIssues
  class CreateService < IssuableLinks::CreateService
    private

    # rubocop: disable CodeReuse/ActiveRecord
    def relate_issuables(referenced_issue)
      link = EpicIssue.find_or_initialize_by(issue: referenced_issue)

      params = { user_id: current_user.id }
      params[:original_epic_id] = link.epic_id if link.persisted?

      link.epic = issuable
      link.move_to_start

      link.run_after_commit do
        params.merge!(epic_id: link.epic.id, issue_id: referenced_issue.id)
        Epics::NewEpicIssueWorker.perform_async(params)
      end

      link.save

      link
    end
    # rubocop: enable CodeReuse/ActiveRecord

    def extractor_context
      { group: issuable.group }
    end

    def affected_epics(issues)
      [issuable, Epic.in_issues(issues)].flatten.uniq
    end

    def linkable_issuables(issues)
      @linkable_issues ||= begin
        issues.select do |issue|
          supports_epics?(issue) &&
            can?(current_user, :admin_issue, issue) &&
            issuable_group_descendants.include?(issue.project.group) &&
            !previous_related_issuables.include?(issue)
        end
      end
    end

    def previous_related_issuables
      @related_issues ||= issuable.issues.to_a
    end

    def issuable_group_descendants
      @descendants ||= issuable.group.self_and_descendants
    end

    def supports_epics?(issue)
      issue.supports_epic? && issue.project.group&.feature_available?(:epics)
    end
  end
end
