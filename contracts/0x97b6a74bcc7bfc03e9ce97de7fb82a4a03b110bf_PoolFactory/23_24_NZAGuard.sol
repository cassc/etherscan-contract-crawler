// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.17;

/// @title NZAGuard contract contains modifiers to check inputs for non-zero address, non-zero value, non-same address, non-same value, and non-more-than-one
abstract contract NZAGuard {
  modifier nonZeroAddress(address _address) {
    require(_address != address(0), 'NZA');
    _;
  }
  modifier nonZeroValue(uint256 _value) {
    require(_value != 0, 'ZVL');
    _;
  }
  modifier nonSameValue(uint256 _value1, uint256 _value2) {
    require(_value1 != _value2, 'SVR');
    _;
  }
  modifier nonSameAddress(address _address1, address _address2) {
    require(_address1 != _address2, 'SVA');
    _;
  }
  modifier nonMoreThenOne(uint256 _value) {
    require(_value <= 1e18, 'UTR');
    _;
  }
}