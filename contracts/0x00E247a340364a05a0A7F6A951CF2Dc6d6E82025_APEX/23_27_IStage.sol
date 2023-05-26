// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IStage {
    /// @dev move to next stage
    /// @param currentStage the `bytes32` of current stage's `keccak256`
    /// @param nextStage the `bytes32` of next stage's `keccak256`
    function moveToNextStage(bytes32 currentStage, bytes32 nextStage) external;

    /// @dev return the `bytes32` of current stage's `keccak256`
    /// @return currentStage the `bytes32` of current stage's `keccak256`
    function getCurrentStage() external view returns (bytes32);
}