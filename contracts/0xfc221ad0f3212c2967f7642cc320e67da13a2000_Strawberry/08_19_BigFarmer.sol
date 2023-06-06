// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import "../interfaces/IBigFarmer.sol";

abstract contract BigFarmer is ERC721Enumerable {
  using EnumerableSet for EnumerableSet.AddressSet;

  uint256 public constant BIG_FARMER_THRESHOLD = 20;

  EnumerableSet.AddressSet private _bigFarmers;

  // Returns if address is a Big Farmer
  function isBigFarmer(address sender) external view returns (bool) {
    return _bigFarmers.contains(sender);
  }

  // Returns total number of Big Farmers
  function totalBigFarmers() external view returns (uint256) {
    return _bigFarmers.length();
  }

  // Returns address of Big Farmer by index
  function bigFarmerByIndex(uint256 bigFarmerIndex) external view returns (address) {
    require(bigFarmerIndex < _bigFarmers.length(), 'Big Farmer index out of bounds');

    return _bigFarmers.at(bigFarmerIndex);
  }

  // Check if we need to add or remove a Big Farmer
  function _checkBigFarmerStatus(address from, address to) internal {
    if (from != address(0) && ERC721.balanceOf(from) <= BIG_FARMER_THRESHOLD && _bigFarmers.contains(from)) {
      _bigFarmers.remove(from);
    }

    if (to != address(0) && ERC721.balanceOf(to) >= BIG_FARMER_THRESHOLD - 1 && !_bigFarmers.contains(to)) {
      _bigFarmers.add(to);
    }
  }
}