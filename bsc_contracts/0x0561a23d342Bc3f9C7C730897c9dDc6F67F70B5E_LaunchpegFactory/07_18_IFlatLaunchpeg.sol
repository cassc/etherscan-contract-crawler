// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./IBaseLaunchpeg.sol";

/// @title ILaunchpeg
/// @author Trader Joe
/// @notice Defines the basic interface of FlatLaunchpeg
interface IFlatLaunchpeg is IBaseLaunchpeg {
    struct FlatLaunchpegPrices {
        uint256 salePrice;
        uint256 allowlistPrice;
    }

    function allowlistPrice() external view returns (uint256);

    function salePrice() external view returns (uint256);

    function initialize(
        string memory _name,
        string memory _symbol,
        address _projectOwner,
        address _royaltyReceiver,
        uint256 _maxBatchSize,
        uint256 _collectionSize,
        uint256 _amountForDevs,
        uint256 _amountForAllowlist,
        uint256 _batchRevealSize,
        uint256 _revealStartTime,
        uint256 _revealInterval
    ) external;

    function initializePhases(
        uint256 _allowlistStartTime,
        uint256 _publicSaleStartTime,
        uint256 _allowlistPrice,
        uint256 _salePrice
    ) external;

    function allowlistMint(uint256 _quantity) external payable;

    function publicSaleMint(uint256 _quantity) external payable;
}