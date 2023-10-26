// SPDX-License-Identifier: MIT
// @author: NFT Studios

pragma solidity ^0.8.18;

interface IMetadataResolver {
    function getTokenURI(
        uint256 _tokenId
    ) external view returns (string memory);
}