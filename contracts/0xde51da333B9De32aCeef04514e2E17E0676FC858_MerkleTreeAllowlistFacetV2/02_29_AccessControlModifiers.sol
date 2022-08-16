// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./AccessControlLib.sol";

abstract contract AccessControlModifiers {
    modifier onlyOperator() {
        AccessControlLib._checkRole(AccessControlLib.OPERATOR_ROLE, msg.sender);
        _;
    }

    modifier onlyOwner() {
        AccessControlLib._enforceOwner();
        _;
    }
}