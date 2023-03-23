// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface IPoolFactory {
    function registerPool(address _poolAddress) external;

    function userEnteredPool(address _user) external;

    function userLeftPool(address _user) external;
}