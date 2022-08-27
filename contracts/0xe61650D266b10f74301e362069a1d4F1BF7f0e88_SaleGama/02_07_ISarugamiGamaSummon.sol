// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface ISarugamiGamaSummon {
    function mint(address, uint256) external returns (uint256);
    function ownerOf(uint256) external returns (address);
}