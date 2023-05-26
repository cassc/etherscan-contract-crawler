// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

abstract contract AccessControl {
  address internal _admin;
  address internal _owner;

  modifier onlyAdmin() {
    require(msg.sender == _admin, "unauthorized");
    _;
  }

  modifier onlyOwner() {
    require(msg.sender == _owner, "unauthorized");
    _;
  }

  function changeAdmin(address newAdmin) external onlyOwner {
    _admin = newAdmin;
  }

  function changeOwner(address newOwner) external onlyOwner {
    _owner = newOwner;
  }

  function owner() external view returns (address) {
    return _owner;
  }
}