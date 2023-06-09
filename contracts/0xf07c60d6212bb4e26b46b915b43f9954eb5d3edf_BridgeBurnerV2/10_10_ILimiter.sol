// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

interface ILimiter {
    function getLimit(address bridge) external view returns (uint256);

    function getUsage(address bridge) external view returns (uint256);

    function isLimited(address bridge, uint256 amount) external view returns (bool);

    function increaseUsage(uint256 amount) external;
}