// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface Genesis2 {
    function ownerOf(uint256 tokenId) external view returns (address owner);

    function transferFrom(address from, address to, uint256 tokenId) external;

    function setNFTLock(uint256 _nftNumber) external;

    function setNFTUnLock(uint256 _nftNumber) external;
}