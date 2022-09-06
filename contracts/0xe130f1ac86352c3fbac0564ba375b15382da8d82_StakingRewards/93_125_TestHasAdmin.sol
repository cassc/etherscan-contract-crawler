// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "../protocol/core/HasAdmin.sol";

contract TestHasAdmin is HasAdmin {
  event TestEvent();

  constructor(address owner) public {
    __AccessControl_init_unchained();
    _setupRole(OWNER_ROLE, owner);
    _setRoleAdmin(OWNER_ROLE, OWNER_ROLE);
  }

  function adminFunction() public onlyAdmin {
    emit TestEvent();
  }
}