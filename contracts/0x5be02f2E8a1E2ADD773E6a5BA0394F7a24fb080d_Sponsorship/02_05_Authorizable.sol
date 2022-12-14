// SPDX-License-Identifier: CC0

/// @author notu @notuart

pragma solidity ^0.8.9;

import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import './interfaces/IAuthorizable.sol';

contract Authorizable is IAuthorizable, ReentrancyGuard {
  mapping(address => bool) public authorized;

  modifier onlyAuthorized() {
    if (authorized[msg.sender] == false) {
      revert Unauthorized();
    }
    _;
  }

  constructor() {
    authorized[msg.sender] = true;
  }

  function grantAuthorization(
    address account
  ) public onlyAuthorized nonReentrant {
    authorized[account] = true;
  }

  function revokeAuthorization(
    address account
  ) public onlyAuthorized nonReentrant {
    authorized[account] = false;
  }
}