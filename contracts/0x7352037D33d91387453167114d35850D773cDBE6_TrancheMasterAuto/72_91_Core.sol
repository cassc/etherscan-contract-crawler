// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import "./Permissions.sol";

contract Core is Permissions {

    constructor() public {
        _setupGovernor(msg.sender);
    }
}