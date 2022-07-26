// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.10;

import "../libraries/LibSubAccount.sol";
import "./Storage.sol";

contract Getter is Storage {
    using LibSubAccount for bytes32;

    function getAssetInfo(uint8 assetId) external view returns (Asset memory) {
        require(assetId < _storage.assets.length, "LST"); // the asset is not LiSTed
        return _storage.assets[assetId];
    }

    function getAllAssetInfo() external view returns (Asset[] memory) {
        return _storage.assets;
    }

    function getAssetAddress(uint8 assetId) external view returns (address) {
        require(assetId < _storage.assets.length, "LST"); // the asset is not LiSTed
        return _storage.assets[assetId].tokenAddress;
    }

    function getLiquidityPoolStorage()
        external
        view
        returns (
            // [0] shortFundingBaseRate8H
            // [1] shortFundingLimitRate8H
            // [2] lastFundingTime
            // [3] fundingInterval
            // [4] liquidityBaseFeeRate
            // [5] liquidityDynamicFeeRate
            // [6] sequence. note: will be 0 after 0xffffffff
            // [7] strictStableDeviation
            uint32[8] memory u32s,
            // [0] mlpPriceLowerBound
            // [1] mlpPriceUpperBound
            uint96[2] memory u96s
        )
    {
        u32s[0] = _storage.shortFundingBaseRate8H;
        u32s[1] = _storage.shortFundingLimitRate8H;
        u32s[2] = _storage.lastFundingTime;
        u32s[3] = _storage.fundingInterval;
        u32s[4] = _storage.liquidityBaseFeeRate;
        u32s[5] = _storage.liquidityDynamicFeeRate;
        u32s[6] = _storage.sequence;
        u32s[7] = _storage.strictStableDeviation;
        u96s[0] = _storage.mlpPriceLowerBound;
        u96s[1] = _storage.mlpPriceUpperBound;
    }

    function getSubAccount(bytes32 subAccountId)
        external
        view
        returns (
            uint96 collateral,
            uint96 size,
            uint32 lastIncreasedTime,
            uint96 entryPrice,
            uint128 entryFunding
        )
    {
        SubAccount storage subAccount = _storage.accounts[subAccountId];
        collateral = subAccount.collateral;
        size = subAccount.size;
        lastIncreasedTime = subAccount.lastIncreasedTime;
        entryPrice = subAccount.entryPrice;
        entryFunding = subAccount.entryFunding;
    }
}