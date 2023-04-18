// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IFactory {
    function registerFarm(address _farmAddress) external;
    function registerFarmV3 (address _farmAddress) external;

    function userEnteredFarm(address _user) external;

    function userLeftFarm(address _user) external;
}