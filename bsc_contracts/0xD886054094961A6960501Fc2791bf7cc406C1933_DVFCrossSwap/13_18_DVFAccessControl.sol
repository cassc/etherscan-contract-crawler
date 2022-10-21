// SPDX-License-Identifier: UNLICENCED
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "./Storage.sol";

abstract contract DVFAccessControl is AccessControlUpgradeable, Storage {
  bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");
  bytes32 public constant LIQUIDITY_SPENDER_ROLE = keccak256("LIQUIDITY_SPENDER_ROLE");

  // solhint-disable-next-line func-name-mixedcase
  function __DVFAccessControl_init(address admin) internal onlyInitializing {
    __AccessControl_init_unchained();
    _grantRole(DEFAULT_ADMIN_ROLE, admin);
  }
}