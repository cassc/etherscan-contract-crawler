// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IDuende {
    function safeMintSingle(address player) external returns(uint256);
    function safeMint(address player,uint256 quantity) external;
    function ownerOf(uint256 tokenId) external view returns (address);
    function totalSupply() external view returns (uint256);
}