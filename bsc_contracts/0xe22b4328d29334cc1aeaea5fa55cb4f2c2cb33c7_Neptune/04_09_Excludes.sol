// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import './EnumerableSet.sol';
import './Ownable.sol';

contract Excludes is Ownable{

  using EnumerableSet for EnumerableSet.AddressSet;
  EnumerableSet.AddressSet private values;



  function addExcludeAddress(address[] memory excludeAddress) external onlyOwner{
    _add(excludeAddress);
  }

  function _add(address[] memory excludeAddress) internal {
    for(uint256 i;i < excludeAddress.length;i++){
      values.add(excludeAddress[i]);
    }
  }

  function removeExcludeAddress(address[] memory excludeAddress) external onlyOwner{
    for(uint256 i;i < excludeAddress.length;i++){
      values.remove(excludeAddress[i]);
    }
  }

  function excludeValues() external view returns(address[] memory){
    return values.values();
  }

  function excludeContains(address excludeAddress) public view returns(bool){
    return values.contains(excludeAddress);
  }
}