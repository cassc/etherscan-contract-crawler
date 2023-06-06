/// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

/// @title IMarketplace
/// @dev Interface for the Marketplace
interface IMarketplace {
    struct Sale {
        address tokenHolder;
        address payable beneficiary;
        address token;
        uint256 tokenId;
        uint256 tokenAmount;
        uint256 pricePerToken;
        uint256 startAt;
        uint256 endAt;
        uint256 maxCountPerWallet;
    }

    event SaleCreated(address indexed seller, uint256 indexed saleId);
    event Purchase(
        address indexed token,
        uint256 indexed tokenId,
        address indexed buyer,
        address seller,
        uint256 saleId,
        uint256 tokenAmount,
        uint256 timestamp
    );

    function createSale(
        address tokenHolder,
        address payable beneficiary,
        address token,
        uint256 tokenId,
        uint256 tokenAmount,
        uint256 pricePerToken,
        uint256 startAt,
        uint256 endAt,
        uint256 maxCountPerWallet
    ) external;

    function purchase(
        address seller,
        uint256 saleIndex,
        uint256 tokenAmount
    ) external payable;

    function saleAt(address seller, uint256 index) external view returns (Sale memory);

    function saleCount(address seller) external view returns (uint256);
}