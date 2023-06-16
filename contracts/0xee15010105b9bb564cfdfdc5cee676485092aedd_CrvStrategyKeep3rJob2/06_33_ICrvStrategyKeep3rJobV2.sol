// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface ICrvStrategyKeep3rJobV2 {
    function v2Keeper() external view returns (address _v2Keeper);

    function strategyIsV1(address _strategy) external view returns (bool);

    function setV2Keep3r(address _v2Keeper) external;
}