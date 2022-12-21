// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IOracle {
    function getNextSeed() external view returns(uint256);
    function getSeed(uint256) external view returns(uint256);
}

error UnsetSeed();