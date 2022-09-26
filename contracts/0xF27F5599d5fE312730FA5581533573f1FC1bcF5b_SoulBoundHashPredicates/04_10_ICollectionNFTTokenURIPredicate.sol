// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

interface ICollectionNFTTokenURIPredicate {
    function getTokenURI(
        uint256 _tokenId,
        uint256 _hashesTokenId,
        bytes32 _hashesHash
    ) external view returns (string memory);
}