// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

interface IReflectable {
    function reflectionOwed(address user) external view returns (uint256);

    function updateReflection(address user) external;

    function claimReflection() external;
}