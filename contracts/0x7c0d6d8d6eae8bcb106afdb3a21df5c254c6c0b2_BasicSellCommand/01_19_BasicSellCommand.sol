// SPDX-License-Identifier: AGPL-3.0-or-later

/// BasicSellCommand.sol

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

import { MPALike } from "../interfaces/MPALike.sol";
import { VatLike } from "../interfaces/VatLike.sol";
import { SpotterLike } from "../interfaces/SpotterLike.sol";
import { RatioUtils } from "../libs/RatioUtils.sol";
import { McdView } from "../McdView.sol";
import { ServiceRegistry } from "../ServiceRegistry.sol";
import { BaseMPACommand } from "./BaseMPACommand.sol";

contract BasicSellCommand is BaseMPACommand {
    using RatioUtils for uint256;

    struct BasicSellTriggerData {
        uint256 cdpId;
        uint16 triggerType;
        uint256 execCollRatio;
        uint256 targetCollRatio;
        uint256 minSellPrice;
        bool continuous;
        uint64 deviation;
        uint32 maxBaseFeeInGwei;
    }

    constructor(ServiceRegistry _serviceRegistry) BaseMPACommand(_serviceRegistry) {}

    function decode(bytes memory triggerData) public pure returns (BasicSellTriggerData memory) {
        return abi.decode(triggerData, (BasicSellTriggerData));
    }

    function isTriggerDataValid(uint256 _cdpId, bytes memory triggerData)
        external
        pure
        returns (bool)
    {
        BasicSellTriggerData memory trigger = decode(triggerData);

        (uint256 lowerTarget, ) = trigger.targetCollRatio.bounds(trigger.deviation);
        return
            _cdpId == trigger.cdpId &&
            trigger.triggerType == 4 &&
            trigger.execCollRatio <= lowerTarget &&
            deviationIsValid(trigger.deviation);
    }

    function isExecutionLegal(uint256 cdpId, bytes memory triggerData)
        external
        view
        returns (bool)
    {
        BasicSellTriggerData memory trigger = decode(triggerData);

        (, uint256 nextCollRatio, , uint256 nextPrice, bytes32 ilk) = getVaultAndMarketInfo(cdpId);
        uint256 dustLimit = getDustLimit(ilk);
        uint256 debt = getVaultDebt(cdpId);
        uint256 wad = RatioUtils.WAD;
        uint256 futureDebt = (debt * nextCollRatio - debt * wad) /
            (trigger.targetCollRatio.wad() - wad);

        SpotterLike spot = SpotterLike(serviceRegistry.getRegisteredService(MCD_SPOT_KEY));
        (, uint256 liquidationRatio) = spot.ilks(ilk);
        bool validBaseFeeOrNearLiquidation = baseFeeIsValid(trigger.maxBaseFeeInGwei) ||
            nextCollRatio <= liquidationRatio.rayToWad();

        return
            trigger.execCollRatio.wad() > nextCollRatio &&
            trigger.minSellPrice < nextPrice &&
            futureDebt > dustLimit &&
            validBaseFeeOrNearLiquidation;
    }

    function execute(
        bytes calldata executionData,
        uint256 cdpId,
        bytes memory triggerData
    ) external {
        BasicSellTriggerData memory trigger = decode(triggerData);

        validateTriggerType(trigger.triggerType, 4);
        validateSelector(MPALike.decreaseMultiple.selector, executionData);

        executeMPAMethod(executionData);

        if (trigger.continuous) {
            recreateTrigger(cdpId, trigger.triggerType, triggerData);
        }
    }

    function isExecutionCorrect(uint256 cdpId, bytes memory triggerData)
        external
        view
        returns (bool)
    {
        BasicSellTriggerData memory trigger = decode(triggerData);

        McdView mcdView = McdView(serviceRegistry.getRegisteredService(MCD_VIEW_KEY));
        uint256 nextCollRatio = mcdView.getRatio(cdpId, true);

        (uint256 lowerTarget, uint256 upperTarget) = trigger.targetCollRatio.bounds(
            trigger.deviation
        );

        return nextCollRatio >= lowerTarget.wad() && nextCollRatio <= upperTarget.wad();
    }

    function getDustLimit(bytes32 ilk) internal view returns (uint256) {
        VatLike vat = VatLike(serviceRegistry.getRegisteredService(MCD_VAT_KEY));
        (, , , , uint256 radDust) = vat.ilks(ilk);
        return radDust.radToWad();
    }
}