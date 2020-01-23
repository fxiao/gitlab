# frozen_string_literal: true

module Geo
  # Base class for services that handles any type of blob replication
  #
  # GitLab handles this types of blobs:
  #   * user uploads: anything the user can upload on the Web UI (ex: issue attachments, avatars, etc)
  #   * job artifacts: anything generated by the CI (ex: logs, artifacts, etc)
  #   * lfs blobs: anything stored in LFS
  class BaseFileService
    include ExclusiveLeaseGuard
    include ::Gitlab::Geo::LogHelpers

    attr_reader :object_type, :object_db_id

    def initialize(object_type, object_db_id)
      @object_type = object_type.to_sym
      @object_db_id = object_db_id
    end

    def execute
      raise NotImplementedError
    end

    private

    def fail_unimplemented_klass!(type:)
      error_message = "Cannot find a handler for Gitlab::Geo #{type} for object_type = '#{object_type}'"

      log_error(error_message)

      raise NotImplementedError, error_message
    end

    def user_upload?
      Gitlab::Geo::Replication.object_type_from_user_uploads?(object_type)
    end

    def job_artifact?
      object_type == :job_artifact
    end

    def lfs?
      object_type == :lfs
    end

    # This is called by LogHelpers to build json log with context info
    #
    # @see ::Gitlab::Geo::LogHelpers
    def extra_log_data
      {
        object_type: object_type,
        object_db_id: object_db_id
      }.compact
    end
  end
end
