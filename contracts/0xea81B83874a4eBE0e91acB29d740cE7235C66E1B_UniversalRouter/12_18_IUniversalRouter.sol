// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IUniversalRouter {
    /// @notice Thrown when deadline for execution is more than timestamp
    error DeadlinePassed();

    /// @notice Thrown when the commands array and input array mismatch
    error InvalidInputLength();

    /// @notice Thrown when a command fails
    error FailedCommand(bytes1 command, uint256 commandNum, bytes output);

    /// @notice Thrown when an unauthorized address tries to call a function
    error Unauthorized();

    /// @notice Thrown when invalid token is used for Stargate bridge
    error InvalidToken();

    /// @notice Thrown when invalid amount is used for Stargate bridge
    error InvalidTokenAmount();

    /// @notice Thrown when ethBalance is less than start
    error InsufficientEth();
}