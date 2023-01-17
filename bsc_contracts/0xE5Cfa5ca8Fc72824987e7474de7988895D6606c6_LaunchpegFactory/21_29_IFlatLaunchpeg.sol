// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./IBaseLaunchpeg.sol";

/// @title ILaunchpeg
/// @author Trader Joe
/// @notice Defines the basic interface of FlatLaunchpeg
interface IFlatLaunchpeg is IBaseLaunchpeg {
    function initialize(
        CollectionData calldata _collectionData,
        CollectionOwnerData calldata _ownerData
    ) external;

    function initializePhases(
        uint256 _preMintStartTime,
        uint256 _allowlistStartTime,
        uint256 _publicSaleStartTime,
        uint256 _publicSaleEndTime,
        uint256 _allowlistPrice,
        uint256 _salePrice
    ) external;
}