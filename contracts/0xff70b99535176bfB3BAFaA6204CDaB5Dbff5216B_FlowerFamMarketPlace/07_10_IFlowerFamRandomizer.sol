// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

interface IFlowerFamRandomizer {
    function rng(address _address) external view returns (uint256);
    function rngDecision(address _address, uint256 probability, uint256 base) external view returns (bool);
    function getSpeciesOfId(uint256 id) external view returns (uint8);
}