// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/**
 * @title Command Interface
 */
interface ICommand {
    /**
     * @notice Checks the validity of the trigger data when the trigger is created
     * @param triggerData  Encoded trigger data struct
     * @return Correctness of the trigger data
     */
    function isTriggerDataValid(
        bool continuous,
        bytes memory triggerData
    ) external view returns (bool);

    function getTriggerType(bytes calldata triggerData) external view returns (uint16);

    /**
     * @notice Returns the correctness of the vault state post execution of the command.
     * @param triggerData Encoded trigger data struct
     * @return Correctness of the trigger execution
     */
    function isExecutionCorrect(bytes memory triggerData) external view returns (bool);

    /**
     * @notice Checks the validity of the trigger data when the trigger is executed
     * @param triggerData  Encoded trigger data struct
     * @return Correctness of the trigger data during execution
     */
    function isExecutionLegal(bytes memory triggerData) external view returns (bool);

    /**
     * @notice Executes the trigger
     * @param executionData Execution data from the Automation Worker
     * @param triggerData  Encoded trigger data struct
     */

    function execute(bytes calldata executionData, bytes memory triggerData) external;
}