//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IRedCat {
    function totalSupply() external view returns (uint);
    function getRarity(uint tokenId) external view returns (uint, uint);
    function ownerOf(uint tokenId) external view returns (address);
    function getUnboxing(uint tokenId) external view returns (uint, bool);
    function unboxing(uint tokenId, uint rarity) external;
}