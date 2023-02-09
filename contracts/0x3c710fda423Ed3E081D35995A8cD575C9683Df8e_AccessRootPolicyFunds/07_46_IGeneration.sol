// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IGeneration {
    // generations index from 1000, see GENERATION_START in PolicedUtils.sol
    // @return uint256 generation number
    function generation() external view returns (uint256);
}