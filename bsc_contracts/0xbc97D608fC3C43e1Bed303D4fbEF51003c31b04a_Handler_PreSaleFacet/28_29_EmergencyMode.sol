// SPDX-License-Identifier: BSD-3-Clause

pragma solidity ^0.8.0;

import "./Owners.sol";

contract EmergencyMode is Owners {
    bool public isEmergencyMode = false;

    modifier onlySafeMode() {
        require(!isEmergencyMode, "Emergency mode is activated");
        _;
    }

    modifier onlyEmergencyMode() {
        require(isEmergencyMode, "Emergency mode is not activated");
        _;
    }

    function setEmergencyMode(bool _emergency) external onlyOwners {
        isEmergencyMode = _emergency;
    }
}