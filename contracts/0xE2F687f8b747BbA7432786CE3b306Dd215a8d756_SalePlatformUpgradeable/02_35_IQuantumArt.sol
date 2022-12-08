// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IQuantumArt {
    function mintTo(uint256 dropId, address artist) external returns (uint256);
    function burn(uint256 tokenId) external;
    function getArtist(uint256 dropId) external view returns (address);
    function balanceOf(address user) external view returns (uint256);
}