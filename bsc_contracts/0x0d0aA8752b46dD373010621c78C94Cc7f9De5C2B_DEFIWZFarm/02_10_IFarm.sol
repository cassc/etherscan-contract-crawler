// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IFarm{
    function getReward(address account) external;
    function earned(address account) external view returns (uint256);
}