// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IBurnVF {
    function transferFrom(address from, address to, uint256 tokenId) external;

    function burn(uint256 tokenId) external;

    function burn(address from, uint256 tokenId) external;
}