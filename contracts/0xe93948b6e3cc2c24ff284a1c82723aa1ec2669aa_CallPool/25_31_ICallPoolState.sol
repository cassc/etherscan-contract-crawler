// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import {DataTypes} from '../../DataTypes.sol';

/// @title Pool state that can change
/// @notice These methods compose the pool's state, and can change with any frequency including multiple times
/// per transaction
interface ICallPoolState {

    function balanceOf(address user) external view returns(uint256);

    // Get NFTStatus
    function getNFTStatus(uint256 tokenId) external view returns (DataTypes.NFTStatusOutput memory);

    function getNFTStatusBatch(uint256[] memory tokenIds) external view returns (DataTypes.NFTStatusOutput[] memory);

    function previewOpenCall( uint256 tokenId, uint8 strikePriceGapIdx, uint8 durationIdx) external view 
        returns( uint256 strikePrice, uint256 premiumToOwner, uint256 premiumToReserve, uint256 errorCode );

    function previewOpenCallBatch( uint256[] memory tokenIds, uint8[] memory strikePriceGaps, uint8[] memory durations) external view
        returns( uint256[] memory strikePrices, uint256[] memory premiumsToOwner, uint256[] memory premiumsToReserve, uint256[] memory errorCodes);

    function totalOpenInterest() external view returns(uint256);

    function getEndTime(uint256 tokenId) external view returns(uint256);
}