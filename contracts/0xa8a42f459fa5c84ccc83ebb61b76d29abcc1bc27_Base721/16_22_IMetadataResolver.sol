// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

// @author: NFT Studios - Buildtree

interface IMetadataResolver {
    function getTokenURI(uint256 _tokenId) external view returns (string memory);
}