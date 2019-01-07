import createState from 'ee/security_dashboard/store/modules/filters/state';
import * as getters from 'ee/security_dashboard/store/modules/filters/getters';

describe('filters module getters', () => {
  const mockedGetters = state => {
    const getFilter = filterId => getters.getFilter(state)(filterId);
    const getSelectedOptions = filterId =>
      getters.getSelectedOptions(state, { getFilter })(filterId);
    const getSelectedOptionIds = filterId =>
      getters.getSelectedOptionIds(state, { getSelectedOptions })(filterId);
    const getFilterIds = getters.getFilterIds(state);

    return {
      getFilter,
      getSelectedOptions,
      getSelectedOptionIds,
      getFilterIds,
    };
  };
  let state;

  beforeEach(() => {
    state = createState();
  });

  describe('getFilter', () => {
    it('should return the type filter information', () => {
      const typeFilter = getters.getFilter(state)('report_type');

      expect(typeFilter.name).toEqual('Report type');
    });
  });

  describe('getSelectedOptions', () => {
    describe('with one selected option', () => {
      it('should return "All" as the selected option', () => {
        const selectedOptions = getters.getSelectedOptions(state, mockedGetters(state))(
          'report_type',
        );

        expect(selectedOptions).toHaveLength(1);
        expect(selectedOptions[0].name).toEqual('All');
      });
    });

    describe('with multiple selected options', () => {
      it('should return both "High" and "Critical" ', () => {
        state = {
          filters: [
            {
              id: 'severity',
              options: [{ id: 'critical', selected: true }, { id: 'high', selected: true }],
            },
          ],
        };
        const selectedOptions = getters.getSelectedOptions(state, mockedGetters(state))('severity');

        expect(selectedOptions).toHaveLength(2);
      });
    });
  });

  describe('getSelectedOptionIds', () => {
    it('should return "one" as the selcted dummy ID', () => {
      const dummyFilter = {
        id: 'dummy',
        options: [{ id: 'one', selected: true }, { id: 'anotherone', selected: false }],
      };
      state.filters.push(dummyFilter);
      const selectedOptionIds = getters.getSelectedOptionIds(state, mockedGetters(state))('dummy');

      expect(selectedOptionIds).toHaveLength(1);
      expect(selectedOptionIds[0]).toEqual('one');
    });
  });

  describe('getSelectedOptionNames', () => {
    it('should return "All" as the selected option', () => {
      const selectedOptionNames = getters.getSelectedOptionNames(state, mockedGetters(state))(
        'severity',
      );

      expect(selectedOptionNames).toEqual('All');
    });

    it('should return the correct message when multiple filters are selected', () => {
      state = {
        filters: [
          {
            id: 'severity',
            options: [{ name: 'Critical', selected: true }, { name: 'High', selected: true }],
          },
        ],
      };
      const selectedOptionNames = getters.getSelectedOptionNames(state, mockedGetters(state))(
        'severity',
      );

      expect(selectedOptionNames).toEqual('Critical +1 more');
    });
  });

  describe('activeFilters', () => {
    it('should return no severity filters', () => {
      const activeFilters = getters.activeFilters(state, mockedGetters(state));

      expect(activeFilters.severity).toHaveLength(0);
    });

    it('should return multiple dummy filters"', () => {
      const dummyFilter = {
        id: 'dummy',
        options: [{ id: 'one', selected: true }, { id: 'anotherone', selected: true }],
      };
      state.filters.push(dummyFilter);
      const activeFilters = getters.activeFilters(state, mockedGetters(state));

      expect(activeFilters.dummy).toHaveLength(2);
    });
  });
});
