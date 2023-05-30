//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IDresNFT {
    function mint(address, uint256) external;

    function mintReservedNFT(address, uint256) external;
}