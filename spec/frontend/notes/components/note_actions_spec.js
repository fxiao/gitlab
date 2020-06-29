import Vue from 'vue';
import { shallowMount, createLocalVue, createWrapper } from '@vue/test-utils';
import { TEST_HOST } from 'spec/test_constants';
import createStore from '~/notes/stores';
import noteActions from '~/notes/components/note_actions.vue';
import { userDataMock } from '../mock_data';
import AxiosMockAdapter from 'axios-mock-adapter';
import axios from '~/lib/utils/axios_utils';

describe('noteActions', () => {
  let wrapper;
  let store;
  let props;
  let actions;
  let axiosMock;

  const shallowMountNoteActions = (propsData, computed) => {
    const localVue = createLocalVue();
    return shallowMount(localVue.extend(noteActions), {
      store,
      propsData,
      localVue,
      computed,
    });
  };

  beforeEach(() => {
    store = createStore();

    props = {
      accessLevel: 'Maintainer',
      authorId: 1,
      author: userDataMock,
      canDelete: true,
      canEdit: true,
      canAwardEmoji: true,
      canReportAsAbuse: true,
      noteId: '539',
      noteUrl: `${TEST_HOST}/group/project/-/merge_requests/1#note_1`,
      reportAbusePath: `${TEST_HOST}/abuse_reports/new?ref_url=http%3A%2F%2Flocalhost%3A3000%2Fgitlab-org%2Fgitlab-ce%2Fissues%2F7%23note_539&user_id=26`,
      showReply: false,
    };

    actions = {
      updateAssignees: jest.fn(),
    };

    axiosMock = new AxiosMockAdapter(axios);
  });

  afterEach(() => {
    wrapper.destroy();
    axiosMock.restore();
  });

  describe('user is logged in', () => {
    beforeEach(() => {
      store.dispatch('setUserData', userDataMock);

      wrapper = shallowMountNoteActions(props);
    });

    it('should render access level badge', () => {
      expect(
        wrapper
          .find('.note-role')
          .text()
          .trim(),
      ).toEqual(props.accessLevel);
    });

    it('should render emoji link', () => {
      expect(wrapper.find('.js-add-award').exists()).toBe(true);
      expect(wrapper.find('.js-add-award').attributes('data-position')).toBe('right');
    });

    describe('actions dropdown', () => {
      it('should be possible to edit the comment', () => {
        expect(wrapper.find('.js-note-edit').exists()).toBe(true);
      });

      it('should be possible to report abuse to admin', () => {
        expect(wrapper.find(`a[href="${props.reportAbusePath}"]`).exists()).toBe(true);
      });

      it('should be possible to copy link to a note', () => {
        expect(wrapper.find('.js-btn-copy-note-link').exists()).toBe(true);
      });

      it('should not show copy link action when `noteUrl` prop is empty', done => {
        wrapper.setProps({
          ...props,
          author: {
            avatar_url: 'mock_path',
            id: 26,
            name: 'Example Maintainer',
            path: '/ExampleMaintainer',
            state: 'active',
            username: 'ExampleMaintainer',
          },
          noteUrl: '',
        });

        Vue.nextTick()
          .then(() => {
            expect(wrapper.find('.js-btn-copy-note-link').exists()).toBe(false);
          })
          .then(done)
          .catch(done.fail);
      });

      it('should be possible to delete comment', () => {
        expect(wrapper.find('.js-note-delete').exists()).toBe(true);
      });

      it('closes tooltip when dropdown opens', done => {
        wrapper.find('.more-actions-toggle').trigger('click');

        const rootWrapper = createWrapper(wrapper.vm.$root);
        Vue.nextTick()
          .then(() => {
            const emitted = Object.keys(rootWrapper.emitted());

            expect(emitted).toEqual(['bv::hide::tooltip']);
            done();
          })
          .catch(done.fail);
      });

      it('should not be possible to assign or unassign the comment author in a merge request', () => {
        const assignUserButton = wrapper.find('[data-testid="assign-user"]');
        expect(assignUserButton.exists()).toBe(false);
      });
    });
  });

  describe('when a user has access to edit an issue', () => {
    beforeEach(() => {
      axiosMock.onPut(`${TEST_HOST}/api/v4/projects/group/project/issues/1`).reply(() => {
        expect(actions.updateAssignees).toHaveBeenCalled();
      });

      store.dispatch('setUserData', userDataMock);
      store.dispatch('setNoteableData', {
        current_user: {
          can_update: true,
        },
      });

      wrapper = shallowMountNoteActions(props, {
        targetType: () => 'issue',
      });
    });

    afterEach(() => {
      wrapper.destroy();
      axiosMock.restore();
    });

    it('should be possible to assign the comment author', () => {
      const assignUserButton = wrapper.find('[data-testid="assign-user"]');
      expect(assignUserButton.exists()).toBe(true);
      assignUserButton.trigger('click');
    });

    it('should be possible to unassign the comment author', () => {
      const assignUserButton = wrapper.find('[data-testid="assign-user"]');
      expect(assignUserButton.exists()).toBe(true);
      assignUserButton.trigger('click');
    });
  });

  describe('when a user does not have access to edit an issue', () => {
    beforeEach(() => {
      wrapper = shallowMountNoteActions(props, {
        targetType: () => 'issue',
      });
    });

    afterEach(() => {
      wrapper.destroy();
    });

    it('should not be possible to assign the comment author', () => {
      const assignUserButton = wrapper.find('[data-testid="assign-user"]');
      expect(assignUserButton.exists()).toBe(false);
    });

    it('should not be possible to unassign the comment author', () => {
      const assignUserButton = wrapper.find('[data-testid="assign-user"]');
      expect(assignUserButton.exists()).toBe(false);
    });
  });

  describe('user is not logged in', () => {
    beforeEach(() => {
      store.dispatch('setUserData', {});
      wrapper = shallowMountNoteActions({
        ...props,
        canDelete: false,
        canEdit: false,
        canAwardEmoji: false,
        canReportAsAbuse: false,
      });
    });

    it('should not render emoji link', () => {
      expect(wrapper.find('.js-add-award').exists()).toBe(false);
    });

    it('should not render actions dropdown', () => {
      expect(wrapper.find('.more-actions').exists()).toBe(false);
    });
  });

  describe('for showReply = true', () => {
    beforeEach(() => {
      wrapper = shallowMountNoteActions({
        ...props,
        showReply: true,
      });
    });

    it('shows a reply button', () => {
      const replyButton = wrapper.find({ ref: 'replyButton' });

      expect(replyButton.exists()).toBe(true);
    });
  });

  describe('for showReply = false', () => {
    beforeEach(() => {
      wrapper = shallowMountNoteActions({
        ...props,
        showReply: false,
      });
    });

    it('does not show a reply button', () => {
      const replyButton = wrapper.find({ ref: 'replyButton' });

      expect(replyButton.exists()).toBe(false);
    });
  });

  describe('Draft notes', () => {
    beforeEach(() => {
      store.dispatch('setUserData', userDataMock);

      wrapper = shallowMountNoteActions({ ...props, canResolve: true, isDraft: true });
    });

    it('should render the right resolve button title', () => {
      const resolveButton = wrapper.find({ ref: 'resolveButton' });

      expect(resolveButton.exists()).toBe(true);
      expect(resolveButton.attributes('title')).toBe('Thread stays unresolved');
    });
  });
});
