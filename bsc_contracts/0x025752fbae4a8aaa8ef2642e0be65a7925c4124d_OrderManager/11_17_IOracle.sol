// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.15;

/// @title IOracle
/// @notice Read price of various token
interface IOracle {
    function getPrice(address token) external view returns (uint256);
}