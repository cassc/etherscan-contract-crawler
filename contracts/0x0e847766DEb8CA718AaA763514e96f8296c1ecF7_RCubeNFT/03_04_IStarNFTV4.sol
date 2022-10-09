// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IStarNFTV4 {
    function owner() external view returns (address);
    function addMinter(address minter) external;
    function mint(address account, uint256 cid) external returns (uint256);
    function balanceOf(address owner) external view returns (uint256);
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function getNumMinted() external view returns (uint256);
}