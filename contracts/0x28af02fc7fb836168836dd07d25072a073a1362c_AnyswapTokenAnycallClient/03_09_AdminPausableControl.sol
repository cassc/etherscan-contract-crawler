// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.10;

import "./AdminControl.sol";
import "./PausableControl.sol";

abstract contract AdminPausableControl is AdminControl, PausableControl {
    constructor(address _admin) AdminControl(_admin) {}

    function pause(bytes32 role) external onlyAdmin {
        _pause(role);
    }

    function unpause(bytes32 role) external onlyAdmin {
        _unpause(role);
    }
}
