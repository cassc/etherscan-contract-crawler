// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

interface BotLike {
    function addRecord(
        uint256 triggerType,
        bool continuous,
        uint256 replacedTriggerId,
        bytes memory triggerData,
        bytes memory replacedTriggerData
    ) external;

    function removeRecord(
        // This function should be executed allways in a context of AutomationBot address not DsProxy,
        //msg.sender should be dsProxy
        bytes memory triggersData,
        uint256 triggerId
    ) external;

    function execute(
        bytes calldata executionData,
        bytes calldata triggerData,
        address commandAddress,
        uint256 triggerId,
        uint256 coverageAmount,
        address coverageToken
    ) external;
}