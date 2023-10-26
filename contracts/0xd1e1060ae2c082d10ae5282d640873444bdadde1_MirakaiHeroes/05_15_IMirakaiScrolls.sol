//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IMirakaiScrolls {
    function dna(uint256 tokenId) external view returns (uint256);

    function cc0Traits(uint256 tokenId) external view returns (uint256);

    function burn(uint256 tokenId) external;
}