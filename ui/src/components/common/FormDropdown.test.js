import Enzyme, { shallow } from 'enzyme';
import Adapter from 'enzyme-adapter-react-16';
import React from 'react';
Enzyme.configure({ adapter: new Adapter() });

import FormDropdown from "./FormDropdown";

describe('FormDropdown', () => {
  it('test render', () => {
    const items = ['item1', 'item2'];
    const wrapper = shallow(<FormDropdown items={items} />);
    expect(wrapper.find('Uncontrolled(Dropdown)')).toHaveLength(1);
    expect(wrapper.find('DropdownToggle')).toHaveLength(1);
    expect(wrapper.find('DropdownMenu')).toHaveLength(1);
    expect(wrapper.find('MenuItem')).toHaveLength(items.length);
  });
});