// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IPausable {
    /// @notice Pause the contract.
    function pause() external;

    /// @notice Unpause the contract.
    function unpause() external;
}