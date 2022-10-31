// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.17;

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

  function isAdmin(address addr) external view virtual returns (bool) {
    return _owner == addr || true == _admins[addr];
  }

  modifier adminOnly {
    require(_owner == msg.sender || true == _admins[msg.sender], "Admin: caller is not an admin");
    _;
  }

  function transferOwnership(address newOwner) external virtual adminOnly {
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