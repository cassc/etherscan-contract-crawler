// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./IBaseLaunchpeg.sol";

/// @title ILaunchpeg
/// @author Trader Joe
/// @notice Defines the basic interface of Launchpeg
interface ILaunchpeg is IBaseLaunchpeg {
    function amountForAuction() external view returns (uint256);

    function auctionSaleStartTime() external view returns (uint256);

    function auctionStartPrice() external view returns (uint256);

    function auctionEndPrice() external view returns (uint256);

    function auctionSaleDuration() external view returns (uint256);

    function auctionDropInterval() external view returns (uint256);

    function auctionDropPerStep() external view returns (uint256);

    function allowlistDiscountPercent() external view returns (uint256);

    function publicSaleDiscountPercent() external view returns (uint256);

    function amountMintedDuringAuction() external view returns (uint256);

    function lastAuctionPrice() external view returns (uint256);

    function initialize(
        string memory _name,
        string memory _symbol,
        address _projectOwner,
        address _royaltyReceiver,
        uint256 _maxBatchSize,
        uint256 _collectionSize,
        uint256 _amountForAuction,
        uint256 _amountForAllowlist,
        uint256 _amountForDevs,
        uint256 _batchRevealSize,
        uint256 _revealStartTime,
        uint256 _revealInterval
    ) external;

    function initializePhases(
        uint256 _auctionSaleStartTime,
        uint256 _auctionStartPrice,
        uint256 _auctionEndPrice,
        uint256 _auctionDropInterval,
        uint256 _allowlistStartTime,
        uint256 _allowlistDiscountPercent,
        uint256 _publicSaleStartTime,
        uint256 _publicSaleDiscountPercent
    ) external;

    function auctionMint(uint256 _quantity) external payable;

    function allowlistMint(uint256 _quantity) external payable;

    function publicSaleMint(uint256 _quantity) external payable;

    function getAuctionPrice(uint256 _saleStartTime)
        external
        view
        returns (uint256);

    function getAllowlistPrice() external view returns (uint256);

    function getPublicSalePrice() external view returns (uint256);
}