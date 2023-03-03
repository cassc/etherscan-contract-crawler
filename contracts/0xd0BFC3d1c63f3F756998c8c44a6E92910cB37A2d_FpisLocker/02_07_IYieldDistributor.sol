// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface IYieldDistributor {
    function getYield() external returns (uint256);

    function checkpoint() external;
}