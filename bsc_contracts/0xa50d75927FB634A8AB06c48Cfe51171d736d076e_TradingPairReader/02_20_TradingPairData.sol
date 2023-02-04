// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import 'contracts/position_trading/algorithms/TradingPair/FeeSettings.sol';
import 'contracts/position_trading/AssetData.sol';

/// @dev the full trading pair data
struct TradingPairData {
    uint256 positionId;
    address owner;
    address liquidityToken;
    uint256 liquidityTokenTotalSupply;
    FeeSettings feeSettings;
    address feeToken;
    uint256 feeTokenTotalSupply; 
    address feeDistributer;
    uint256 feeDistributerAsset1Count;
    uint256 feeDistributerAsset2Count;
    AssetData asset1;
    AssetData asset2;
}