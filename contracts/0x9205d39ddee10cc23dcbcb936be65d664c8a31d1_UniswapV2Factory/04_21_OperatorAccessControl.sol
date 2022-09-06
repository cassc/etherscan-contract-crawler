// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

abstract contract OperatorAccessControl is AccessControlUpgradeable {
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    function __OperatorAccessControl_init() internal {
      __AccessControl_init();
    }

    function addOperator(address operator) external {
      grantRole(OPERATOR_ROLE, operator);
    }

    function removeOperator(address operator) external {
      revokeRole(OPERATOR_ROLE, operator);
    }
}