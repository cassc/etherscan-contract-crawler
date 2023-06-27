// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IDigitalAnimals {
    function ownerOf(uint256 tokenId) external view returns (address owner);
}