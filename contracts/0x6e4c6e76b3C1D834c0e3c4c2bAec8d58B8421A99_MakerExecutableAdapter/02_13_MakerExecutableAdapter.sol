// SPDX-License-Identifier: AGPL-3.0-or-later

/// MakerExecutableAdapter.sol

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
import "../McdUtils.sol";

contract MakerExecutableAdapter is IExecutableAdapter {
    ManagerLike public immutable manager;
    address public immutable utilsAddress;
    address public immutable botAddress;
    address private immutable dai;
    string private constant CDP_MANAGER_KEY = "CDP_MANAGER";
    string private constant MCD_UTILS_KEY = "MCD_UTILS";
    string private constant AUTOMATION_BOT_KEY = "AUTOMATION_BOT_V2";

    constructor(ServiceRegistry _serviceRegistry, address _dai) {
        dai = _dai;
        manager = ManagerLike(_serviceRegistry.getRegisteredService(CDP_MANAGER_KEY));
        utilsAddress = _serviceRegistry.getRegisteredService(MCD_UTILS_KEY);
        botAddress = _serviceRegistry.getRegisteredService(AUTOMATION_BOT_KEY);
    }

    function decode(
        bytes memory triggerData
    ) public pure returns (uint256 cdpId, uint256 triggerType, uint256 maxCoverage) {
        (cdpId, triggerType, maxCoverage) = abi.decode(triggerData, (uint256, uint16, uint256));
    }

    function getCoverage(
        bytes memory triggerData,
        address receiver,
        address coverageToken,
        uint256 amount
    ) external {
        require(msg.sender == botAddress, "dpm-adapter/only-bot");
        require(coverageToken == dai, "maker-adapter/not-dai");

        (uint256 cdpId, , uint256 maxCoverage) = decode(triggerData);
        require(amount <= maxCoverage, "maker-adapter/coverage-too-high");

        McdUtils utils = McdUtils(utilsAddress);
        manager.cdpAllow(cdpId, utilsAddress, 1);
        utils.drawDebt(amount, cdpId, manager, receiver);
        manager.cdpAllow(cdpId, utilsAddress, 0);
    }
}