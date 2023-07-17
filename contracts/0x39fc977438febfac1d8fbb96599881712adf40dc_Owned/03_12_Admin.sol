// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.0;

abstract contract Admin {
  mapping(address => bool) private _admins;
  address private _owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  constructor() {
    _owner = msg.sender;
    _admins[msg.sender] = true;
  }

  function owner() public view virtual returns (address) {
    return _owner;
  }

  function isAdmin(address addr) public view virtual returns (bool) {
    return true == _admins[addr];
  }

  modifier adminOnly {
    require(isAdmin(msg.sender), "Admin: caller is not an admin");
    _;
  }

  function setOwner(address newOwner) external adminOnly {
    address oldOwner = _owner;
    _owner = newOwner;
    emit OwnershipTransferred(oldOwner, newOwner);
  }

  function setAdmin(address addr, bool add) external adminOnly {
    if (add) {
      _admins[addr] = true;
    } else {
      delete _admins[addr];
    }
  }
}