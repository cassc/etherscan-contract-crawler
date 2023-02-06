// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

interface ICommand {
    function isTriggerDataValid(
        bool continuous,
        bytes memory triggerData
    ) external view returns (bool);

    function isExecutionCorrect(bytes memory triggerData) external view returns (bool);

    function isExecutionLegal(bytes memory triggerData) external view returns (bool);

    function execute(bytes calldata executionData, bytes memory triggerData) external;
}