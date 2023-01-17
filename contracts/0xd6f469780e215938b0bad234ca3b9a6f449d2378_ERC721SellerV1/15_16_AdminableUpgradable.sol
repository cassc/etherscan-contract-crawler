// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import '@openzeppelin-upgradable/contracts/access/OwnableUpgradeable.sol';

abstract contract AdminableUpgradable is OwnableUpgradeable {
  error NoPermission();

  event AdminChanged(address account, bool isAdmin);

  mapping(address => bool) public adminMapping;

  function __Adminable_init() internal onlyInitializing {
    __Ownable_init();
    __Adminable_init_unchained();
  }

  function __Adminable_init_unchained() internal onlyInitializing {
    addAdmin(_msgSender());
  }

  function _checkAdmin() internal view virtual {
    if (!adminMapping[msg.sender] && msg.sender != owner()) revert NoPermission();
  }

  modifier onlyAdmin() {
    _checkAdmin();
    _;
  }

  function addAdmin(address adminAddress) public virtual onlyOwner {
    adminMapping[adminAddress] = true;
    emit AdminChanged(adminAddress, true);
  }

  function removeAdmin(address adminAddress) public virtual onlyOwner {
    adminMapping[adminAddress] = false;
    emit AdminChanged(adminAddress, false);
  }
}