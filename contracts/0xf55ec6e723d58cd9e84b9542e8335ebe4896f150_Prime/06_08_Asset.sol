// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.17;

library Asset {
  struct Data {
    mapping(address => bool) flags;
    mapping(address => uint256) addressIndex;
    address[] addresses;
    uint256 id;
  }

  function insert(Data storage self, address asset) internal returns (bool) {
    if (self.flags[asset]) {
      return false;
    }

    self.flags[asset] = true;
    self.addresses.push(asset);
    self.addressIndex[asset] = self.id;
    self.id++;
    return true;
  }

  function contains(Data storage self, address asset) internal view returns (bool) {
    return self.flags[asset];
  }

  function getList(Data storage self) internal view returns (address[] memory) {
    return self.addresses;
  }
}