// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

interface IMillionDollarRat {
    function ownerOf(uint256 tokenId) external view returns (address);
    function balanceOf(address owner) external view returns (uint256);
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);
}