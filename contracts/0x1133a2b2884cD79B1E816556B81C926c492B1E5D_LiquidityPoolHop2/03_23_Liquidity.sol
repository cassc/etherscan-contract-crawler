// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.10;

import "../libraries/LibAsset.sol";
import "../libraries/LibSubAccount.sol";
import "../libraries/LibMath.sol";
import "../interfaces/IMuxRebalancerCallback.sol";
import "./Account.sol";
import "./Storage.sol";

contract Liquidity is Storage, Account {
    using LibAsset for Asset;
    using LibMath for uint256;
    using LibSubAccount for bytes32;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    /**
     * @dev   Add liquidity
     *
     * @param trader            liquidity provider address
     * @param tokenId           asset.id that added
     * @param rawAmount         asset token amount. decimals = erc20.decimals
     * @param tokenPrice        token price
     * @param mlpPrice          mlp price
     * @param currentAssetValue liquidity USD value of a single asset in all chains (even if tokenId is a stable asset)
     * @param targetAssetValue  weight / Σ weight * total liquidity USD value in all chains
     */
    function addLiquidity(
        address trader,
        uint8 tokenId,
        uint256 rawAmount, // NOTE: OrderBook SHOULD transfer rawAmount collateral to LiquidityPool
        uint96 tokenPrice,
        uint96 mlpPrice,
        uint96 currentAssetValue,
        uint96 targetAssetValue
    ) external onlyOrderBook {
        require(trader != address(0), "T=0"); // Trader address is zero
        require(_hasAsset(tokenId), "LST"); // the asset is not LiSTed
        require(rawAmount != 0, "A=0"); // Amount Is Zero
        require(mlpPrice != 0, "P=0"); // Price Is Zero
        require(mlpPrice <= _storage.mlpPriceUpperBound, "MPO"); // Mlp Price is Out of range
        require(mlpPrice >= _storage.mlpPriceLowerBound, "MPO"); // Mlp Price is Out of range
        Asset storage token = _storage.assets[tokenId];
        require(token.isEnabled(), "ENA"); // the token is temporarily not ENAbled
        require(token.canAddRemoveLiquidity(), "TUL"); // the Token cannot be Used to add Liquidity
        tokenPrice = LibReferenceOracle.checkPriceWithSpread(_storage, token, tokenPrice, SpreadType.Bid);

        // token amount
        uint96 wadAmount = token.toWad(rawAmount);
        token.spotLiquidity += wadAmount; // already reserved fee
        // fee
        uint32 mlpFeeRate = _getLiquidityFeeRate(
            currentAssetValue,
            targetAssetValue,
            true,
            uint256(wadAmount).wmul(tokenPrice).safeUint96(),
            _storage.liquidityBaseFeeRate,
            _storage.liquidityDynamicFeeRate
        );
        uint96 feeCollateral = uint256(wadAmount).rmul(mlpFeeRate).safeUint96();
        token.collectedFee += feeCollateral; // spotLiquidity was modified above
        emit CollectedFee(tokenId, feeCollateral);
        wadAmount -= feeCollateral;
        // mlp
        uint96 mlpAmount = ((uint256(wadAmount) * uint256(tokenPrice)) / uint256(mlpPrice)).safeUint96();
        IERC20Upgradeable(_storage.mlp).transfer(trader, mlpAmount);
        emit AddLiquidity(trader, tokenId, tokenPrice, mlpPrice, mlpAmount, feeCollateral);
        _updateSequence();
        _updateBrokerTransactions();
    }

    /**
     * @dev   Remove liquidity
     *
     * @param trader            liquidity provider address
     * @param mlpAmount         mlp amount
     * @param tokenId           asset.id that removed to
     * @param tokenPrice        token price
     * @param mlpPrice          mlp price
     * @param currentAssetValue liquidity USD value of a single asset in all chains (even if tokenId is a stable asset)
     * @param targetAssetValue  weight / Σ weight * total liquidity USD value in all chains
     */
    function removeLiquidity(
        address trader,
        uint96 mlpAmount, // NOTE: OrderBook SHOULD transfer mlpAmount mlp to LiquidityPool
        uint8 tokenId,
        uint96 tokenPrice,
        uint96 mlpPrice,
        uint96 currentAssetValue,
        uint96 targetAssetValue
    ) external onlyOrderBook {
        require(trader != address(0), "T=0"); // Trader address is zero
        require(_hasAsset(tokenId), "LST"); // the asset is not LiSTed
        require(mlpPrice != 0, "P=0"); // Price Is Zero
        require(mlpPrice <= _storage.mlpPriceUpperBound, "MPO"); // Mlp Price is Out of range
        require(mlpPrice >= _storage.mlpPriceLowerBound, "MPO"); // Mlp Price is Out of range
        require(mlpAmount != 0, "A=0"); // Amount Is Zero
        Asset storage token = _storage.assets[tokenId];
        require(token.isEnabled(), "ENA"); // the token is temporarily not ENAbled
        require(token.canAddRemoveLiquidity(), "TUL"); // the Token cannot be Used to remove Liquidity
        tokenPrice = LibReferenceOracle.checkPriceWithSpread(_storage, token, tokenPrice, SpreadType.Ask);

        // amount
        uint96 wadAmount = ((uint256(mlpAmount) * uint256(mlpPrice)) / uint256(tokenPrice)).safeUint96();
        // fee
        uint96 feeCollateral;
        {
            uint32 mlpFeeRate = _getLiquidityFeeRate(
                currentAssetValue,
                targetAssetValue,
                false,
                uint256(wadAmount).wmul(tokenPrice).safeUint96(),
                _storage.liquidityBaseFeeRate,
                _storage.liquidityDynamicFeeRate
            );
            feeCollateral = uint256(wadAmount).rmul(mlpFeeRate).safeUint96();
        }
        token.collectedFee += feeCollateral; // spotLiquidity will be modified below
        emit CollectedFee(tokenId, feeCollateral);
        wadAmount -= feeCollateral;
        // send token
        require(wadAmount <= token.spotLiquidity, "LIQ"); // insufficient LIQuidity
        token.spotLiquidity -= wadAmount; // already deduct fee
        uint256 rawAmount = token.toRaw(wadAmount);
        token.transferOut(trader, rawAmount, _storage.weth, _storage.nativeUnwrapper);
        emit RemoveLiquidity(trader, tokenId, tokenPrice, mlpPrice, mlpAmount, feeCollateral);
        _updateSequence();
        _updateBrokerTransactions();
    }

    /**
     * @notice Redeem mux token into original tokens
     *
     *         Only strict stable coins and un-stable coins are supported.
     */
    function redeemMuxToken(
        address trader,
        uint8 tokenId,
        uint96 muxTokenAmount // NOTE: OrderBook SHOULD transfer muxTokenAmount to LiquidityPool
    ) external onlyOrderBook {
        require(trader != address(0), "T=0"); // Trader address is zero
        require(_hasAsset(tokenId), "LST"); // the asset is not LiSTed
        require(muxTokenAmount != 0, "A=0"); // Amount Is Zero
        Asset storage token = _storage.assets[tokenId];
        require(token.isEnabled(), "ENA"); // the token is temporarily not ENAbled
        if (token.isStable()) {
            require(token.isStrictStable(), "STR"); // only STRict stable coins and un-stable coins are supported
        }
        require(token.spotLiquidity >= muxTokenAmount, "LIQ"); // insufficient LIQuidity
        uint256 rawAmount = token.toRaw(muxTokenAmount);
        token.spotLiquidity -= muxTokenAmount;
        token.transferOut(trader, rawAmount, _storage.weth, _storage.nativeUnwrapper);
        emit RedeemMuxToken(trader, tokenId, muxTokenAmount);
        _updateSequence();
    }

    /**
     * @notice Broker can update funding each [fundingInterval] seconds by specifying utilizations.
     *
     *         Check _getFundingRate in Liquidity.sol on how to calculate funding rate.
     * @param  stableUtilization    Stable coin utilization in all chains
     * @param  unstableTokenIds     All unstable Asset id(s) MUST be passed in order. ex: 1, 2, 5, 6, ...
     * @param  unstableUtilizations Unstable Asset utilizations in all chains
     * @param  unstablePrices       Unstable Asset prices
     */
    function updateFundingState(
        uint32 stableUtilization, // 1e5
        uint8[] calldata unstableTokenIds,
        uint32[] calldata unstableUtilizations, // 1e5
        uint96[] calldata unstablePrices
    ) external onlyOrderBook {
        uint32 nextFundingTime = (_blockTimestamp() / _storage.fundingInterval) * _storage.fundingInterval;
        if (_storage.lastFundingTime == 0) {
            // init state. just update lastFundingTime
            _storage.lastFundingTime = nextFundingTime;
        } else if (_storage.lastFundingTime + _storage.fundingInterval >= _blockTimestamp()) {
            // do nothing
        } else {
            uint32 timeSpan = nextFundingTime - _storage.lastFundingTime;
            _updateFundingState(stableUtilization, unstableTokenIds, unstableUtilizations, unstablePrices, timeSpan);
            _storage.lastFundingTime = nextFundingTime;
        }
        _updateSequence();
    }

    /**
     * @dev  Rebalance pool liquidity. Swap token 0 for token 1.
     *
     *       rebalancer must implement IMuxRebalancerCallback.
     */
    function rebalance(
        address rebalancer,
        uint8 tokenId0,
        uint8 tokenId1,
        uint96 rawAmount0,
        uint96 maxRawAmount1,
        bytes32 userData,
        uint96 price0,
        uint96 price1
    ) external onlyOrderBook {
        require(rebalancer != address(0), "R=0"); // Rebalancer address is zero
        require(_hasAsset(tokenId0), "LST"); // the asset is not LiSTed
        require(_hasAsset(tokenId1), "LST"); // the asset is not LiSTed
        require(rawAmount0 != 0, "A=0"); // Amount Is Zero
        Asset storage token0 = _storage.assets[tokenId0];
        Asset storage token1 = _storage.assets[tokenId1];
        price0 = LibReferenceOracle.checkPrice(_storage, token0, price0);
        price1 = LibReferenceOracle.checkPrice(_storage, token1, price1);
        require(token0.isEnabled(), "ENA"); // the token is temporarily not ENAbled
        require(token1.isEnabled(), "ENA"); // the token is temporarily not ENAbled
        // send token 0. get amount 1
        uint256 expectedRawAmount1;
        {
            uint96 amount0 = token0.toWad(rawAmount0);
            require(token0.spotLiquidity >= amount0, "LIQ"); // insufficient LIQuidity
            token0.spotLiquidity -= amount0;

            uint96 expectedAmount1 = ((uint256(amount0) * uint256(price0)) / uint256(price1)).safeUint96();
            expectedRawAmount1 = token1.toRaw(expectedAmount1);
        }
        require(expectedRawAmount1 <= maxRawAmount1, "LMT"); // LiMiTed by limitPrice
        // swap. check amount 1
        uint96 rawAmount1;
        {
            IERC20Upgradeable(token0.tokenAddress).safeTransfer(rebalancer, rawAmount0);
            uint256 rawAmount1Old = IERC20Upgradeable(token1.tokenAddress).balanceOf(address(this));
            IMuxRebalancerCallback(rebalancer).muxRebalanceCallback(
                token0.tokenAddress,
                token1.tokenAddress,
                rawAmount0,
                expectedRawAmount1,
                userData
            );
            uint256 rawAmount1New = IERC20Upgradeable(token1.tokenAddress).balanceOf(address(this));
            require(rawAmount1Old <= rawAmount1New, "T1A"); // Token 1 Amount mismatched
            rawAmount1 = (rawAmount1New - rawAmount1Old).safeUint96();
        }
        require(rawAmount1 >= expectedRawAmount1, "T1A"); // Token 1 Amount mismatched
        token1.spotLiquidity += token1.toWad(rawAmount1);

        emit Rebalance(rebalancer, tokenId0, tokenId1, price0, price1, rawAmount0, rawAmount1);
        _updateSequence();
    }

    /**
     * @dev Anyone can withdraw collectedFee into Vault
     */
    function withdrawCollectedFee(uint8[] memory assetIds) external {
        require(_storage.vault != address(0), "VLT"); // bad VauLT
        for (uint256 i = 0; i < assetIds.length; i++) {
            uint8 assetId = assetIds[i];
            Asset storage asset = _storage.assets[assetId];
            uint96 collectedFee = asset.collectedFee;
            require(collectedFee <= asset.spotLiquidity, "LIQ"); // insufficient LIQuidity
            asset.collectedFee = 0;
            asset.spotLiquidity -= collectedFee;
            uint256 rawAmount = asset.toRaw(collectedFee);
            IERC20Upgradeable(asset.tokenAddress).safeTransfer(_storage.vault, rawAmount);
            emit WithdrawCollectedFee(assetId, collectedFee);
        }
        _updateSequence();
    }

    /**
     * @dev Broker can withdraw brokerGasRebate
     */
    function claimBrokerGasRebate(address receiver) external onlyOrderBook returns (uint256 rawAmount) {
        require(receiver != address(0), "RCV"); // bad ReCeiVer
        uint256 assetCount = _storage.assets.length;
        for (uint256 assetId = 0; assetId < assetCount; assetId++) {
            Asset storage asset = _storage.assets[assetId];
            if (asset.tokenAddress == _storage.weth) {
                uint96 rebate = (uint256(_storage.brokerGasRebate) * uint256(_storage.brokerTransactions)).safeUint96();
                require(asset.spotLiquidity >= rebate, "LIQ"); // insufficient LIQuidity
                asset.spotLiquidity -= rebate;
                rawAmount = asset.toRaw(rebate);
                emit ClaimBrokerGasRebate(receiver, _storage.brokerTransactions, rawAmount);
                _storage.brokerTransactions = 0;
                asset.transferOut(receiver, rawAmount, _storage.weth, _storage.nativeUnwrapper);
                _updateSequence();
                return rawAmount;
            }
        }
    }

    function _updateFundingState(
        uint32 stableUtilization, // 1e5
        uint8[] calldata unstableTokenIds,
        uint32[] calldata unstableUtilizations, // 1e5
        uint96[] calldata unstablePrices,
        uint32 timeSpan
    ) internal {
        require(unstableTokenIds.length == unstableUtilizations.length, "LEN"); // LENgth of 2 arguments does not match
        require(unstableTokenIds.length == unstablePrices.length, "LEN"); // LENgth of 2 arguments does not match
        // stable
        uint32 shortFundingRate;
        uint128 shortCumulativeFundingRate;
        (shortFundingRate, shortCumulativeFundingRate) = _getFundingRate(
            _storage.shortFundingBaseRate8H,
            _storage.shortFundingLimitRate8H,
            stableUtilization,
            timeSpan
        );
        // unstable
        uint8 tokenLen = uint8(_storage.assets.length);
        uint8 i = 0;
        for (uint8 tokenId = 0; tokenId < tokenLen; tokenId++) {
            Asset storage asset = _storage.assets[tokenId];
            if (asset.isStable()) {
                continue;
            }
            require(i < unstableTokenIds.length, "LEN"); // invalid LENgth of unstableTokenIds
            require(unstableTokenIds[i] == tokenId, "AID"); // AssetID mismatched
            (uint32 longFundingRate, uint128 longCumulativeFundingRate) = _getFundingRate(
                asset.longFundingBaseRate8H,
                asset.longFundingLimitRate8H,
                unstableUtilizations[i],
                timeSpan
            );
            asset.longCumulativeFundingRate += longCumulativeFundingRate;
            {
                uint96 price = LibReferenceOracle.checkPrice(_storage, asset, unstablePrices[i]);
                asset.shortCumulativeFunding += uint256(shortCumulativeFundingRate).wmul(price).safeUint128();
            }
            emit UpdateFundingRate(
                tokenId,
                longFundingRate,
                asset.longCumulativeFundingRate,
                shortFundingRate,
                asset.shortCumulativeFunding
            );
            i += 1;
        }
    }

    /**
     * @dev   Liquidity fee rate
     *
     *        Lower rates indicate liquidity is closer to target.
     *
     *                                                  targetLiquidity
     *                     <------------------------------------+--------------------------------------> liquidity
     *
     * case 1: high rebate   * currentLiq * newLiq
     *                       * currentLiq                                                    * newLiq
     *
     * case 2: low rebate                 * currentLiq * newLiq
     *                                    * currentLiq                          * newLiq
     *
     * case 3: higher fee                                          * currentLiq * newLiq
     *
     * case 4: max fee                                             * currentLiq              * newLiq
     *                                                                          * currentLiq * newLiq
     *
     * @param currentAssetValue liquidity USD value of a single asset in all chains (even if tokenId is a stable asset)
     * @param targetAssetValue  weight / Σ weight * total liquidity USD value in all chains
     * @param isAdd             true if add liquidity, false if remove liquidity
     * @param deltaValue        add/remove liquidity USD value
     * @param baseFeeRate       base fee
     * @param dynamicFeeRate    dynamic fee
     */
    function _getLiquidityFeeRate(
        uint96 currentAssetValue,
        uint96 targetAssetValue,
        bool isAdd,
        uint96 deltaValue,
        uint32 baseFeeRate, // 1e5
        uint32 dynamicFeeRate // 1e5
    ) internal pure returns (uint32) {
        uint96 newAssetValue;
        if (isAdd) {
            newAssetValue = currentAssetValue + deltaValue;
        } else {
            require(currentAssetValue >= deltaValue, "LIQ"); // insufficient LIQuidity
            newAssetValue = currentAssetValue - deltaValue;
        }
        // | x - target |
        uint96 oldDiff = currentAssetValue > targetAssetValue
            ? currentAssetValue - targetAssetValue
            : targetAssetValue - currentAssetValue;
        uint96 newDiff = newAssetValue > targetAssetValue
            ? newAssetValue - targetAssetValue
            : targetAssetValue - newAssetValue;
        if (targetAssetValue == 0) {
            // avoid division by 0
            return baseFeeRate;
        } else if (newDiff < oldDiff) {
            // improves
            uint32 rebate = ((uint256(dynamicFeeRate) * uint256(oldDiff)) / uint256(targetAssetValue)).safeUint32();
            return baseFeeRate > rebate ? baseFeeRate - rebate : 0;
        } else {
            // worsen
            uint96 avgDiff = (oldDiff + newDiff) / 2;
            avgDiff = LibMath.min(avgDiff, targetAssetValue);
            uint32 dynamic = ((uint256(dynamicFeeRate) * uint256(avgDiff)) / uint256(targetAssetValue)).safeUint32();
            return baseFeeRate + dynamic;
        }
    }

    /**
     * @dev Funding rate formula
     *
     * ^ fr           / limit
     * |            /
     * |          /
     * |        /
     * |______/ base
     * |    .
     * |  .
     * |.
     * +-------------------> %util
     */
    function _getFundingRate(
        uint32 baseRate8H, // 1e5
        uint32 limitRate8H, // 1e5
        uint32 utilization, // 1e5
        uint32 timeSpan // 1e0
    ) internal pure returns (uint32 newFundingRate, uint128 cumulativeFundingRate) {
        require(utilization <= 1e5, "U>1"); // %utilization > 100%
        newFundingRate = uint256(utilization).rmul(limitRate8H).safeUint32();
        newFundingRate = LibMath.max32(newFundingRate, baseRate8H);
        cumulativeFundingRate = ((uint256(newFundingRate) * uint256(timeSpan) * 1e13) / FUNDING_PERIOD).safeUint128();
    }
}