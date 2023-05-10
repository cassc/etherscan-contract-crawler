// SPDX-License-Identifier: AGPL-3.0-or-later

/// MakerSecurityAdapter.sol

// Copyright (C) 2023 Oazo Apps Limited

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.
pragma solidity ^0.8.0;

import "../interfaces/IAdapter.sol";
import "../McdView.sol";

contract MakerSecurityAdapter is ISecurityAdapter {
    ManagerLike public immutable manager;
    address public immutable botAddress;
    address private immutable self;
    string private constant CDP_MANAGER_KEY = "CDP_MANAGER";
    string private constant MCD_UTILS_KEY = "MCD_UTILS";
    string private constant AUTOMATION_BOT_KEY = "AUTOMATION_BOT_V2";

    constructor(ServiceRegistry _serviceRegistry) {
        self = address(this);
        manager = ManagerLike(_serviceRegistry.getRegisteredService(CDP_MANAGER_KEY));
        botAddress = _serviceRegistry.getRegisteredService(AUTOMATION_BOT_KEY);
    }

    function decode(
        bytes memory triggerData
    ) public pure returns (uint256 cdpId, uint256 triggerType, uint256 maxCoverage) {
        (cdpId, triggerType, maxCoverage) = abi.decode(triggerData, (uint256, uint16, uint256));
    }

    function canCall(bytes memory triggerData, address operator) public view returns (bool result) {
        (uint256 cdpId, , ) = decode(triggerData);
        address cdpOwner = manager.owns(cdpId);
        result = (manager.cdpCan(cdpOwner, cdpId, operator) == 1) || (operator == cdpOwner);
    }

    function canCall(
        address operator,
        uint256 cdpId,
        address cdpOwner
    ) private view returns (bool) {
        return (manager.cdpCan(cdpOwner, cdpId, operator) == 1) || (operator == cdpOwner);
    }

    function permit(bytes memory triggerData, address target, bool allowance) public {
        (uint256 cdpId, , ) = decode(triggerData);
        address cdpOwner = manager.owns(cdpId);

        require(canCall(address(this), cdpId, cdpOwner), "maker-adapter/not-allowed-to-call");
        if (self == address(this)) {
            require(msg.sender == botAddress, "dpm-adapter/only-bot");
        }
        if (allowance && !canCall(target, cdpId, cdpOwner)) {
            manager.cdpAllow(cdpId, target, 1);
        }
        if (!allowance && canCall(target, cdpId, cdpOwner)) {
            manager.cdpAllow(cdpId, target, 0);
        }
    }
}