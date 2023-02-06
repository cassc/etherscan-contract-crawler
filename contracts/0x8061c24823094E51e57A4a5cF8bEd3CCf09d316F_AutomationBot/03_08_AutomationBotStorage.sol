// SPDX-License-Identifier: AGPL-3.0-or-later

/// AutomationBotStorage.sol

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

import "./interfaces/IAdapter.sol";
import "./ServiceRegistry.sol";

contract AutomationBotStorage {
    string private constant AUTOMATION_BOT_KEY = "AUTOMATION_BOT_V2";
    uint64 private constant COUNTER_OFFSET = 10 ** 10;

    struct TriggerRecord {
        bytes32 triggerHash;
        address commandAddress; // or type ? do we allow execution of the same command with new contract - waht if contract rev X is broken ? Do we force migration (can we do it)?
        bool continuous;
    }

    struct Counters {
        uint64 triggersCounter;
        uint64 triggersGroupCounter;
    }

    mapping(uint256 => TriggerRecord) public activeTriggers;

    Counters public counter;

    ServiceRegistry public immutable serviceRegistry;

    constructor(ServiceRegistry _serviceRegistry) {
        serviceRegistry = _serviceRegistry;
        counter.triggersCounter = COUNTER_OFFSET;
        counter.triggersGroupCounter = COUNTER_OFFSET + 1;
    }

    modifier auth(address caller) {
        require(
            serviceRegistry.getRegisteredService(AUTOMATION_BOT_KEY) == caller,
            "bot-storage/not-automation-bot"
        );
        _;
    }

    function increaseGroupCounter() external auth(msg.sender) {
        counter.triggersGroupCounter++;
    }

    function triggersCounter() external view returns (uint256) {
        return uint256(counter.triggersCounter);
    }

    function triggersGroupCounter() external view returns (uint256) {
        return uint256(counter.triggersGroupCounter);
    }

    function updateTriggerRecord(
        uint256 id,
        TriggerRecord memory record
    ) external auth(msg.sender) {
        activeTriggers[id] = record;
    }

    function appendTriggerRecord(TriggerRecord memory record) external auth(msg.sender) {
        counter.triggersCounter++;
        activeTriggers[counter.triggersCounter] = record;
    }

    function executePermit(
        bytes memory triggerData,
        address target,
        address adapter,
        bool allowance
    ) external auth(msg.sender) {
        (bool status, ) = adapter.delegatecall(
            abi.encodeWithSelector(ISecurityAdapter.permit.selector, triggerData, target, allowance)
        );
        require(status, "bot-storage/permit-failed");
    }

    function executeCoverage(
        bytes memory triggerData,
        address receiver,
        address adapter,
        address coverageToken,
        uint256 coverageAmount
    ) external auth(msg.sender) {
        (bool status, ) = adapter.delegatecall(
            abi.encodeWithSelector(
                IExecutableAdapter.getCoverage.selector,
                triggerData,
                receiver,
                coverageToken,
                coverageAmount
            )
        );
        require(status, "bot-storage/failed-to-draw-coverage");
    }
}