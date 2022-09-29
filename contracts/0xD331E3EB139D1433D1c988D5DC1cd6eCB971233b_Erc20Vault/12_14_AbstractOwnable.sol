// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract AbstractOwnable {

  modifier onlyOwner() {
    require(_owner() == msg.sender, "caller is not the owner");
    _;
  }

  function _owner() internal virtual returns(address);

}