// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IReleaseManager {
    function initialize() external;
    function registerInstance(address instanceAddress) external;
    function checkInstance(address instanceAddress) external view returns(bool);
    function checkFactory(address factoryAddress) external view returns(bool);
}