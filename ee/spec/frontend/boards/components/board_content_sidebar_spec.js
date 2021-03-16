import { GlDrawer } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vuex from 'vuex';
import SidebarIterationWidget from 'ee_component/sidebar/components/sidebar_iteration_widget';
import { stubComponent } from 'helpers/stub_component';
import BoardContentSidebar from '~/boards/components/board_content_sidebar.vue';
import { ISSUABLE, issuableTypes } from '~/boards/constants';
import { mockIssue, mockIssueGroupPath, mockIssueProjectPath } from '../mock_data';

describe('ee/BoardContentSidebar', () => {
  let wrapper;
  let store;

  const createStore = ({ mockGetters = {}, mockActions = {} } = {}) => {
    store = new Vuex.Store({
      state: {
        sidebarType: ISSUABLE,
        issues: { [mockIssue.id]: mockIssue },
        activeId: mockIssue.id,
        issuableType: issuableTypes.issue,
      },
      getters: {
        activeIssue: () => mockIssue,
        projectPathForActiveIssue: () => mockIssueProjectPath,
        groupPathForActiveIssue: () => mockIssueGroupPath,
        isSidebarOpen: () => true,
        ...mockGetters,
      },
      actions: mockActions,
    });
  };

  const createComponent = () => {
    wrapper = shallowMount(BoardContentSidebar, {
      provide: {
        canUpdate: true,
        rootPath: '/',
        groupId: '#',
      },
      store,
      stubs: {
        GlDrawer: stubComponent(GlDrawer, {
          template: '<div><slot name="header"></slot><slot></slot></div>',
        }),
      },
      mocks: {
        $apollo: {
          queries: {
            participants: {
              loading: false,
            },
          },
        },
      },
    });
  };

  beforeEach(() => {
    createStore();
    createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  it('renders SidebarIterationWidget', () => {
    expect(wrapper.find(SidebarIterationWidget).exists()).toBe(true);
  });
});
