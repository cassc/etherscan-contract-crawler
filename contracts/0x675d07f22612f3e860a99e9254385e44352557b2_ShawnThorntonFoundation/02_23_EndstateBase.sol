// contracts/EndstateBase.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";

abstract contract EndstateBase is AccessControl {
    bytes32 public constant ENDSTATE_ADMIN_ROLE =
        keccak256("ENDSTATE_ADMIN_ROLE");

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(ENDSTATE_ADMIN_ROLE, _msgSender());
    }
}