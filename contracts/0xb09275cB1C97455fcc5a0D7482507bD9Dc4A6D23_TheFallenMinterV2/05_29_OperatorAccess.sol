// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";

abstract contract OperatorAccess is AccessControl {
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    // Modifier for operator roles
    modifier onlyOperator() {
        require(hasRole(OPERATOR_ROLE, _msgSender()), "Not an operator");
        _;
    }
}