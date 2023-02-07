// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface IUMFTicket {
    function setBaseURI(string memory baseUri) external;

    function batchTransferFrom(address to, uint256[] calldata tokenIds) external;

    function mint(address to, uint256 tokenId) external;

    function mintBatch(address to, uint256 totalCount) external;

    function mintBatchToAddresses(address[] memory toList) external;

    function mintBatchToAddressesWithTokenIds(address[] memory toList, uint256[] memory tokenIdList) external;

    function refreshTokenMetadata(uint256 tokenId) external;

    function batchRefreshMetadata(uint256 fromTokenId, uint256 toTokenId) external;

    function refreshEntireTokenMetadata() external;
}