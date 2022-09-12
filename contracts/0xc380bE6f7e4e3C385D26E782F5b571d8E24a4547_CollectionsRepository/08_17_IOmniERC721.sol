// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.7;

interface IOmniERC721 {
    function mint(address owner) external;
    function totalSupply() external view returns (uint256);
    function mintPrice() external view returns (uint256);
    function tokenIds() external view returns (uint256);
    function creator() external view returns (address);
    function createdAt() external view returns (uint256);
    function dropFrom() external view returns (uint256);
    function assetName() external view returns (string memory);
}