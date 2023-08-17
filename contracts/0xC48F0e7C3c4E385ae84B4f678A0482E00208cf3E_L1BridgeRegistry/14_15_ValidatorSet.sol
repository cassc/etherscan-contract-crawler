// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

// LightLink 2023
library ValidatorSet {
  struct Validator {
    address addr;
    uint256 power;
  }

  struct Record {
    Validator[] values;
    mapping(address => uint256) indexes; // value to index
  }

  function add(Record storage _record, address _value, uint256 _power) internal {
    if (contains(_record, _value)) return; // exist
    _record.values.push(Validator(_value, _power));
    _record.indexes[_value] = _record.values.length;
  }

  function modify(Record storage _record, address _value, uint256 _power) internal {
    if (!contains(_record, _value)) {
      add(_record, _value, _power);
      return;
    }
    uint256 valueIndex = _record.indexes[_value];
    _record.values[valueIndex - 1].power = _power;
  }

  function remove(Record storage _record, address _value) internal {
    uint256 valueIndex = _record.indexes[_value];
    if (valueIndex == 0) return; // removed non-exist value
    uint256 toDeleteIndex = valueIndex - 1; // dealing with out of bounds
    uint256 lastIndex = _record.values.length - 1;
    if (lastIndex != toDeleteIndex) {
      Validator memory lastvalue = _record.values[lastIndex];
      _record.values[toDeleteIndex] = lastvalue;
      _record.indexes[lastvalue.addr] = valueIndex; // Replace lastvalue's index to valueIndex
    }
    _record.values.pop();
    _record.indexes[_value] = 0; // set to 0
  }

  function contains(Record storage _record, address _value) internal view returns (bool) {
    return _record.indexes[_value] != 0;
  }

  function size(Record storage _record) internal view returns (uint256) {
    return _record.values.length;
  }

  function at(Record storage _record, uint256 _index) internal view returns (Validator memory) {
    return _record.values[_index];
  }

  function indexOf(Record storage _record, address _value) internal view returns (bool, uint256) {
    if (!contains(_record, _value)) return (false, 0);
    return (true, _record.indexes[_value] - 1);
  }

  function getPower(Record storage _record, address _value) internal view returns (uint256) {
    if (!contains(_record, _value)) return 0;
    return _record.values[_record.indexes[_value] - 1].power;
  }
}