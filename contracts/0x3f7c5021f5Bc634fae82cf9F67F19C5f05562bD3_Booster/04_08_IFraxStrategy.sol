// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

/// @notice Frax Staking Handler Interface.
interface IFraxStrategy {
    function proxyCall(address _to, bytes memory _data) external;
}