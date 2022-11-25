// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IWLLCardMetadata {
    function hasOnchainMetadata(uint256 tokenId) external view returns(bool);
    function tokenURI(uint256 tokenId) external view returns (string memory);
}