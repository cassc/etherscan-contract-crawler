// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface ITypes {
    function createRandomTypeMystery(uint256 count) external view returns (uint256);
    function createRandomTypeGenesis1(uint256 count) external view returns (uint256);
    function createRandomTypeGenesis2(uint256 count) external view returns (uint256);
}