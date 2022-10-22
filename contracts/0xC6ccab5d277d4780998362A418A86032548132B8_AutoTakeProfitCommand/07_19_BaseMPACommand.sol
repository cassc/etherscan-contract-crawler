// SPDX-License-Identifier: AGPL-3.0-or-later

/// BaseMPACommand.sol

// Copyright (C) 2021-2021 Oazo Apps Limited

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

import { RatioUtils } from "../libs/RatioUtils.sol";
import { ICommand } from "../interfaces/ICommand.sol";
import { ManagerLike } from "../interfaces/ManagerLike.sol";
import { ServiceRegistry } from "../ServiceRegistry.sol";
import { McdView } from "../McdView.sol";
import { AutomationBot } from "../AutomationBot.sol";

abstract contract BaseMPACommand is ICommand {
    using RatioUtils for uint256;

    string public constant MCD_VIEW_KEY = "MCD_VIEW";
    string public constant CDP_MANAGER_KEY = "CDP_MANAGER";
    string public constant MPA_KEY = "MULTIPLY_PROXY_ACTIONS";
    string public constant MCD_SPOT_KEY = "MCD_SPOT";
    string public constant MCD_VAT_KEY = "MCD_VAT";

    uint256 public constant MIN_ALLOWED_DEVIATION = 50;

    ServiceRegistry public immutable serviceRegistry;

    constructor(ServiceRegistry _serviceRegistry) {
        serviceRegistry = _serviceRegistry;
    }

    function getVaultAndMarketInfo(uint256 cdpId)
        public
        view
        returns (
            uint256 collRatio,
            uint256 nextCollRatio,
            uint256 currPrice,
            uint256 nextPrice,
            bytes32 ilk
        )
    {
        ManagerLike manager = ManagerLike(serviceRegistry.getRegisteredService(CDP_MANAGER_KEY));
        ilk = manager.ilks(cdpId);

        McdView mcdView = McdView(serviceRegistry.getRegisteredService(MCD_VIEW_KEY));
        collRatio = mcdView.getRatio(cdpId, false);
        nextCollRatio = mcdView.getRatio(cdpId, true);
        currPrice = mcdView.getPrice(ilk);
        nextPrice = mcdView.getNextPrice(ilk);
    }

    function getVaultDebt(uint256 cdpId) internal view returns (uint256) {
        McdView mcdView = McdView(serviceRegistry.getRegisteredService(MCD_VIEW_KEY));
        (, uint256 debt) = mcdView.getVaultInfo(cdpId);
        return debt;
    }

    function baseFeeIsValid(uint256 maxAcceptableBaseFeeInGwei) public view returns (bool) {
        return block.basefee <= maxAcceptableBaseFeeInGwei * (10**9);
    }

    function deviationIsValid(uint256 deviation) public pure returns (bool) {
        return deviation >= MIN_ALLOWED_DEVIATION;
    }

    function validateTriggerType(uint16 triggerType, uint16 expectedTriggerType) public pure {
        require(triggerType == expectedTriggerType, "base-mpa-command/type-not-supported");
    }

    function validateSelector(bytes4 expectedSelector, bytes memory executionData) public pure {
        bytes4 selector = abi.decode(executionData, (bytes4));
        require(selector == expectedSelector, "base-mpa-command/invalid-selector");
    }

    function executeMPAMethod(bytes memory executionData) internal {
        (bool status, bytes memory reason) = serviceRegistry
            .getRegisteredService(MPA_KEY)
            .delegatecall(executionData);
        require(status, string(reason));
    }

    function recreateTrigger(
        uint256 cdpId,
        uint16 triggerType,
        bytes memory triggerData
    ) internal virtual {
        (bool status, ) = msg.sender.delegatecall(
            abi.encodeWithSelector(
                AutomationBot(msg.sender).addTrigger.selector,
                cdpId,
                triggerType,
                0,
                triggerData
            )
        );
        require(status, "base-mpa-command/trigger-recreation-failed");
    }
}