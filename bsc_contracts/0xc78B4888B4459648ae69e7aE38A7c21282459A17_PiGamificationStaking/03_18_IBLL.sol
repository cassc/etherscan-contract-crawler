//SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

interface IBLL {
    // retrieve count of owned NFTs for a user for a specific NFT type
    function getNFTTypeCount(address account, uint32 nftType)
        external
        view
        returns (uint256);

    // retrieve count of owner NFTs for a user for multiple NFT types
    function getNFTTypeCounts(address account, uint32[] calldata nftTypes)
        external
        view
        returns (uint256 result);

    // returns specific tokenURI is one is assigned to the token
    // if not, then returns URI for NFT type using tokenBaseURI
    function tokenURI(uint256 tokenID) external view returns (string memory);

    function tokenIDToNFTType(uint32 tokenId) external view returns (uint32);

    function getNFTTypeForTokenID(uint32 tokenID)
        external
        view
        returns (uint32);

    function getPointsForTokenID(uint32 nftIDs)
        external
        view
        returns (uint256);

    function getPointsForTokenIDs(uint32[] calldata nftIDs)
        external
        view
        returns (uint256[] memory);

    function getTotalPointsForTokenIDs(uint32[] calldata nftIDs)
        external
        view
        returns (uint256 points);

    function getNFTTypesForTokenIDs(uint32[] calldata tokenIDs)
        external
        view
        returns (uint32[] memory);

    function balanceOf(address owner) external view returns (uint256);

    function tokenOfOwnerByIndex(address account, uint256 index)
        external
        view
        returns (uint256);

    function getNFTTypesForUser(address user)
        external
        view
        returns (uint32[] memory);

    function getPointsForSeries(uint32 seriesId, uint32[] calldata tokenIds)
        external
        view
        returns (uint256);

    function checkSeriesForTokenIDs(uint32 seriesId, uint32[] calldata tokenIds)
        external
        view
        returns (bool);           
}