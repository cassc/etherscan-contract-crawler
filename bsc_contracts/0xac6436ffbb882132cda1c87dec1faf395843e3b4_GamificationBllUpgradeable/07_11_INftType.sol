//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface INftType {
    // retrieve count of owned Nfts for a user for a specific Nft type
    function getNftTypeCount(
        address account,
        uint32 nftType
    ) external view returns (uint256);

    // retrieve count of owner Nfts for a user for multiple Nft types
    function getNftTypeCounts(
        address account,
        uint32[] calldata nftTypes
    ) external view returns (uint256 result);

    // returns specific tokenURI is one is assigned to the token
    // if not, then returns URI for Nft type using tokenBaseURI
    function tokenURI(uint256 tokenId) external view returns (string memory);

    function tokenIdToNftType(uint32 tokenId) external view returns (uint32);

    function getNftTypeForTokenId(
        uint32 tokenId
    ) external view returns (uint32);

    function getPointsForTokenIds(
        uint32[] calldata nftIDs
    ) external view returns (uint256[] memory);

    function getTotalPointsForTokenIds(
        uint32[] calldata nftIDs
    ) external view returns (uint256 points);

    function getNftTypesForTokenIds(
        uint32[] calldata tokenIds
    ) external view returns (uint32[] memory);

    function balanceOf(address owner) external view returns (uint256);

    function tokenOfOwnerByIndex(
        address account,
        uint256 index
    ) external view returns (uint256);

    function getNftTypesForUser(
        address user
    ) external view returns (uint32[] memory);

    function getPointsForSeries(
        uint32 seriesId,
        uint32[] calldata tokenIds
    ) external view returns (uint256);

    function checkSeriesForTokenIds(
        uint32 seriesId,
        uint32[] calldata tokenIds
    ) external view returns (bool);

    function getTokenIdNumericInfo(
        uint32 tokenId,
        uint256 num
    ) external view returns (uint256);

    function getAllTokenIdNumericInfo(
        uint32 tokenId
    ) external view returns (uint256, uint256, uint256);
}