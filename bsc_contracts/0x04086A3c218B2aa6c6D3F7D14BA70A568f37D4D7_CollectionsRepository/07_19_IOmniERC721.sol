// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IOmniERC721 {
    function mint(address owner, uint256 quantity) external;
    function maxSupply() external view returns (uint256);
    function mintPrice() external view returns (uint256);
    function totalMinted() external view returns (uint256);
    function creator() external view returns (address);
    function createdAt() external view returns (uint256);
    function dropFrom() external view returns (uint256);
    function assetName() external view returns (string memory);
}