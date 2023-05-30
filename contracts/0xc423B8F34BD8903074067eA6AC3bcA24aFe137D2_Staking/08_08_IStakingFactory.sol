// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IStakingFactory {
    function createPool(address token) external;

    function rewardPerBlock(address stake) external view returns (uint256);
}