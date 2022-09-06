// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface INft {
    function burn(uint256 tokenId) external;
    function burn(address owner, uint256 tokenId) external;
}