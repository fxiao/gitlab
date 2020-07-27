# frozen_string_literal: true

module Gitlab
  module Analytics
    # Normally each analytics feature should be guarded with a feature flag.
    CYCLE_ANALYTICS_FEATURE_FLAG = :cycle_analytics
    PRODUCTIVITY_ANALYTICS_FEATURE_FLAG = :productivity_analytics
    GROUP_COVERAGE_REPORTS_FEATURE_FLAG = :group_coverage_reports
    GROUP_MERGE_REQUEST_ANALYTICS_FEATURE_FLAG = :group_merge_request_analytics

    FEATURE_FLAGS = [
      CYCLE_ANALYTICS_FEATURE_FLAG,
      GROUP_COVERAGE_REPORTS_FEATURE_FLAG,
      PRODUCTIVITY_ANALYTICS_FEATURE_FLAG
    ].freeze

    FEATURE_FLAG_DEFAULTS = {
      PRODUCTIVITY_ANALYTICS_FEATURE_FLAG => true,
      GROUP_COVERAGE_REPORTS_FEATURE_FLAG => false,
      CYCLE_ANALYTICS_FEATURE_FLAG => true
    }.freeze

    def self.any_features_enabled?
      FEATURE_FLAGS.any? { |flag| Feature.enabled?(flag, default_enabled: feature_enabled_by_default?(flag)) }
    end

    def self.cycle_analytics_enabled?
      feature_enabled?(CYCLE_ANALYTICS_FEATURE_FLAG)
    end

    def self.productivity_analytics_enabled?
      feature_enabled?(PRODUCTIVITY_ANALYTICS_FEATURE_FLAG)
    end

    def self.group_coverage_reports_enabled?
      feature_enabled?(GROUP_COVERAGE_REPORTS_FEATURE_FLAG)
    end

    def self.group_merge_request_analytics_enabled?
      feature_enabled?(GROUP_MERGE_REQUEST_ANALYTICS_FEATURE_FLAG)
    end

    def self.feature_enabled_by_default?(flag)
      !!FEATURE_FLAG_DEFAULTS[flag]
    end

    def self.feature_enabled?(feature)
      Feature.enabled?(feature, default_enabled: feature_enabled_by_default?(feature))
    end
  end
end
