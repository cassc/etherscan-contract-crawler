// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IGroupNFT {

    function balanceOf(address owner) external view returns (uint256 balance);

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    function lock(uint256 tokenId) external;

    function unlock(uint256 tokenId) external;

}