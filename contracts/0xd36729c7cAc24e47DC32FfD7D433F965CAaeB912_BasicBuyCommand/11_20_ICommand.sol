//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface ICommand {
    function isTriggerDataValid(uint256 _cdpId, bytes memory triggerData)
        external
        view
        returns (bool);

    function isExecutionCorrect(uint256 cdpId, bytes memory triggerData)
        external
        view
        returns (bool);

    function isExecutionLegal(uint256 cdpId, bytes memory triggerData) external view returns (bool);

    function execute(
        bytes calldata executionData,
        uint256 cdpId,
        bytes memory triggerData
    ) external;
}