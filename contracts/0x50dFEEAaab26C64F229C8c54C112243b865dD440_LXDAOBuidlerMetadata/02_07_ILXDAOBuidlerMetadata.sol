// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface ILXDAOBuidlerMetadata {
    function create(uint256 tokenId, bytes calldata metadataURI) external;

    function update(uint256 tokenId, bytes calldata metadataURI) external;

    function batchUpdate(
        uint256[] calldata tokenIds,
        bytes[] calldata metadataURIs
    ) external;

    function tokenURI(uint256 tokenId) external view returns (string memory);
}