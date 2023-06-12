// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IERC2981 {
    struct RoyaltyInfo {
        address receiver;
        uint96 royaltyFraction;
    }

    /**
        @notice Called with the sale price to determine how much royalty is owed and to whom.
        @param _tokenId - the NFT asset queried for royalty information
        @param _salePrice - the sale price of the NFT asset specified by _tokenId
        @return receiver - address of who should be sent the royalty payment
        @return royaltyAmount - the royalty payment amount for _salePrice
    */
    function royaltyInfo(
        uint256 _tokenId,
        uint256 _salePrice
    ) external view returns (
        address receiver,
        uint256 royaltyAmount
    );

    function setRoyaltyInfo(
        uint256 _tokenId,
        uint256 _salePrice
    ) external view returns (
        address receiver,
        uint256 royaltyAmount
    );

    function updateRoyaltyPercentage(uint256 percentage) external;
}