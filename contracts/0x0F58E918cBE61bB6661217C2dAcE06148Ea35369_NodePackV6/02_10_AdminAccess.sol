// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

import "../interfaces/IAdminControl.sol";

abstract contract AdminAccess {

  IAdminControl public adminControl;

  modifier onlyRole(uint8 _role) {
    require(address(adminControl) == address(0) || adminControl.hasRole(_role, msg.sender), "no access");
    _;
  }

  function addAdminControlContract(IAdminControl _contract) external onlyRole(0) {
    adminControl = _contract;
  }

}