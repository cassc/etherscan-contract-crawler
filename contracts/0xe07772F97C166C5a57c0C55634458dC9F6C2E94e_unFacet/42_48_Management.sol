// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import "./ManagementStorage.sol";

abstract contract Management {
    function getManagerInfo() view external returns (address untradingManager, uint256 managerCut) {
        ManagementStorage.Layout storage f = ManagementStorage.layout();
        return (f.untradingManager, f.managerCut);
    }

    function setManagerCut(uint256 newManagerCut) external {
        ManagementStorage.Layout storage f = ManagementStorage.layout();
        require(msg.sender == f.untradingManager, "Caller not permitted");
        f.managerCut = newManagerCut;
    }
}