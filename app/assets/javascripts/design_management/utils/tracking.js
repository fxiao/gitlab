import Tracking from '~/tracking';
import api from '~/api';

// Snowplow tracking constants
const DESIGN_TRACKING_CONTEXT_SCHEMAS = {
  VIEW_DESIGN_SCHEMA: 'iglu:com.gitlab/design_management_context/jsonschema/1-0-0',
};
const DESIGN_TRACKING_EVENTS = {
  VIEW_DESIGN: 'view_design',
  CREATE_DESIGN: 'create_design',
  UPDATE_DESIGN: 'update_design',
};

// Usage ping tracking constants
const DESIGN_ACTION = 'design_action';

export const DESIGN_TRACKING_PAGE_NAME = 'projects:issues:design';

/**
 * Track "design detail" view in Snowplow
 */
export function trackDesignDetailView(
  referer = '',
  owner = '',
  designVersion = 1,
  latestVersion = false,
) {
  const eventName = DESIGN_TRACKING_EVENTS.VIEW_DESIGN;

  Tracking.event(DESIGN_TRACKING_PAGE_NAME, eventName, {
    label: eventName,
    context: {
      schema: DESIGN_TRACKING_CONTEXT_SCHEMAS.VIEW_DESIGN_SCHEMA,
      data: {
        'design-version-number': designVersion,
        'design-is-current-version': latestVersion,
        'internal-object-referrer': referer,
        'design-collection-owner': owner,
      },
    },
  });
}

export function trackDesignCreate() {
  return Tracking.event(DESIGN_TRACKING_PAGE_NAME, DESIGN_TRACKING_EVENTS.CREATE_DESIGN);
}

export function trackDesignUpdate() {
  return Tracking.event(DESIGN_TRACKING_PAGE_NAME, DESIGN_TRACKING_EVENTS.UPDATE_DESIGN);
}

/**
 * Track "design detail" view via usage ping
 */
export function usagePingDesignDetailView() {
  api.trackRedisHllUserEvent(DESIGN_ACTION);
}
