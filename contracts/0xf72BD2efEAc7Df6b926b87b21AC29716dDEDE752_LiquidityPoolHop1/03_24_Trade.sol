// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.10;

import "../libraries/LibAsset.sol";
import "../libraries/LibSubAccount.sol";
import "../libraries/LibMath.sol";
import "../libraries/LibReferenceOracle.sol";
import "./Account.sol";
import "./Storage.sol";

contract Trade is Storage, Account {
    using LibAsset for Asset;
    using LibMath for uint256;
    using LibSubAccount for bytes32;

    function openPosition(
        bytes32 subAccountId,
        uint96 amount,
        uint96 collateralPrice,
        uint96 assetPrice
    ) external onlyOrderBook returns (uint96) {
        LibSubAccount.DecodedSubAccountId memory decoded = subAccountId.decodeSubAccountId();
        require(decoded.account != address(0), "T=0"); // Trader address is zero
        require(_hasAsset(decoded.collateralId), "LST"); // the asset is not LiSTed
        require(_hasAsset(decoded.assetId), "LST"); // the asset is not LiSTed
        require(amount != 0, "A=0"); // Amount Is Zero

        Asset storage asset = _storage.assets[decoded.assetId];
        Asset storage collateral = _storage.assets[decoded.collateralId];
        SubAccount storage subAccount = _storage.accounts[subAccountId];
        require(asset.isOpenable(), "OPN"); // the asset is not OPeNable
        require(!asset.isStable(), "STB"); // can not trade a STaBle coin
        require(asset.isTradable(), "TRD"); // the asset is not TRaDable
        require(asset.isEnabled(), "ENA"); // the token is temporarily not ENAbled
        require(collateral.isEnabled(), "ENA"); // the token is temporarily not ENAbled
        require(decoded.isLong || asset.isShortable(), "SHT"); // can not SHorT this asset
        assetPrice = LibReferenceOracle.checkPriceWithSpread(
            _storage,
            asset,
            assetPrice,
            decoded.isLong ? SpreadType.Ask : SpreadType.Bid
        );
        collateralPrice = LibReferenceOracle.checkPrice(_storage, collateral, collateralPrice);

        // fee & funding
        uint96 feeUsd = _getFeeUsd(subAccount, asset, decoded.isLong, amount, assetPrice);
        _updateEntryFunding(subAccount, asset, decoded.isLong);
        {
            uint96 feeCollateral = uint256(feeUsd).wdiv(collateralPrice).safeUint96();
            require(subAccount.collateral >= feeCollateral, "FEE"); // collateral can not pay Fee
            subAccount.collateral -= feeCollateral;
            collateral.collectedFee += feeCollateral;
            collateral.spotLiquidity += feeCollateral;
            emit CollectedFee(decoded.collateralId, feeCollateral);
        }

        // position
        {
            (, uint96 pnlUsd) = _positionPnlUsd(asset, subAccount, decoded.isLong, subAccount.size, assetPrice);
            uint96 newSize = subAccount.size + amount;
            if (pnlUsd == 0) {
                subAccount.entryPrice = assetPrice;
            } else {
                subAccount.entryPrice = ((uint256(subAccount.entryPrice) *
                    uint256(subAccount.size) +
                    uint256(assetPrice) *
                    uint256(amount)) / newSize).safeUint96();
            }
            subAccount.size = newSize;
        }
        subAccount.lastIncreasedTime = _blockTimestamp();
        {
            OpenPositionArgs memory args = OpenPositionArgs({
                subAccountId: subAccountId,
                collateralId: decoded.collateralId,
                isLong: decoded.isLong,
                amount: amount,
                assetPrice: assetPrice,
                collateralPrice: collateralPrice,
                newEntryPrice: subAccount.entryPrice,
                feeUsd: feeUsd,
                remainPosition: subAccount.size,
                remainCollateral: subAccount.collateral
            });
            emit OpenPosition(decoded.account, decoded.assetId, args);
        }
        // total
        _increaseTotalSize(asset, decoded.isLong, amount, assetPrice);
        // post check
        require(_isAccountImSafe(subAccount, decoded.assetId, decoded.isLong, collateralPrice, assetPrice), "!IM");
        _updateSequence();
        _updateBrokerTransactions();
        return assetPrice;
    }

    struct ClosePositionContext {
        LibSubAccount.DecodedSubAccountId id;
        uint96 totalFeeUsd;
        uint96 paidFeeUsd;
    }

    /**
     * @notice Close a position
     *
     * @param  subAccountId     check LibSubAccount.decodeSubAccountId for detail.
     * @param  amount           position size.
     * @param  profitAssetId    for long position (unless asset.useStable is true), ignore this argument;
     *                          for short position, the profit asset should be one of the stable coin.
     * @param  collateralPrice  price of subAccount.collateral.
     * @param  assetPrice       price of subAccount.asset.
     * @param  profitAssetPrice price of profitAssetId. ignore this argument if profitAssetId is ignored.
     */
    function closePosition(
        bytes32 subAccountId,
        uint96 amount,
        uint8 profitAssetId, // only used when !isLong
        uint96 collateralPrice,
        uint96 assetPrice,
        uint96 profitAssetPrice // only used when !isLong
    ) external onlyOrderBook returns (uint96) {
        ClosePositionContext memory ctx;
        ctx.id = subAccountId.decodeSubAccountId();
        require(ctx.id.account != address(0), "T=0"); // Trader address is zero
        require(_hasAsset(ctx.id.collateralId), "LST"); // the asset is not LiSTed
        require(_hasAsset(ctx.id.assetId), "LST"); // the asset is not LiSTed
        require(amount != 0, "A=0"); // Amount Is Zero

        Asset storage asset = _storage.assets[ctx.id.assetId];
        Asset storage collateral = _storage.assets[ctx.id.collateralId];
        SubAccount storage subAccount = _storage.accounts[subAccountId];
        require(!asset.isStable(), "STB"); // can not trade a STaBle coin
        require(asset.isTradable(), "TRD"); // the asset is not TRaDable
        require(asset.isEnabled(), "ENA"); // the token is temporarily not ENAbled
        require(collateral.isEnabled(), "ENA"); // the token is temporarily not ENAbled
        require(ctx.id.isLong || asset.isShortable(), "SHT"); // can not SHorT this asset
        require(amount <= subAccount.size, "A>S"); // close Amount is Larger than position Size
        assetPrice = LibReferenceOracle.checkPriceWithSpread(
            _storage,
            asset,
            assetPrice,
            ctx.id.isLong ? SpreadType.Bid : SpreadType.Ask
        );
        collateralPrice = LibReferenceOracle.checkPrice(_storage, collateral, collateralPrice);
        if (ctx.id.isLong && !asset.useStableTokenForProfit()) {
            profitAssetId = ctx.id.assetId;
            profitAssetPrice = assetPrice;
        } else {
            require(_isStable(profitAssetId), "STB"); // profit asset should be a STaBle coin
            profitAssetPrice = LibReferenceOracle.checkPrice(
                _storage,
                _storage.assets[profitAssetId],
                profitAssetPrice
            );
        }
        require(_storage.assets[profitAssetId].isEnabled(), "ENA"); // the token is temporarily not ENAbled

        // total
        _decreaseTotalSize(asset, ctx.id.isLong, amount, subAccount.entryPrice);
        // fee & funding
        ctx.totalFeeUsd = _getFeeUsd(subAccount, asset, ctx.id.isLong, amount, assetPrice);
        _updateEntryFunding(subAccount, asset, ctx.id.isLong);
        // realize pnl
        (bool hasProfit, uint96 pnlUsd) = _positionPnlUsd(asset, subAccount, ctx.id.isLong, amount, assetPrice);
        if (hasProfit) {
            ctx.paidFeeUsd = _realizeProfit(
                ctx.id.account,
                pnlUsd,
                ctx.totalFeeUsd,
                _storage.assets[profitAssetId],
                profitAssetPrice
            );
        } else {
            _realizeLoss(subAccount, collateral, collateralPrice, pnlUsd, true);
        }
        subAccount.size -= amount;
        if (subAccount.size == 0) {
            subAccount.entryPrice = 0;
            subAccount.entryFunding = 0;
            subAccount.lastIncreasedTime = 0;
        }
        // ignore fees if can not afford
        if (ctx.totalFeeUsd > ctx.paidFeeUsd) {
            uint96 feeCollateral = uint256(ctx.totalFeeUsd - ctx.paidFeeUsd).wdiv(collateralPrice).safeUint96();
            feeCollateral = LibMath.min(feeCollateral, subAccount.collateral);
            subAccount.collateral -= feeCollateral;
            collateral.collectedFee += feeCollateral;
            collateral.spotLiquidity += feeCollateral;
            emit CollectedFee(ctx.id.collateralId, feeCollateral);
            ctx.paidFeeUsd += uint256(feeCollateral).wmul(collateralPrice).safeUint96();
        }
        {
            ClosePositionArgs memory args = ClosePositionArgs({
                subAccountId: subAccountId,
                collateralId: ctx.id.collateralId,
                profitAssetId: profitAssetId,
                isLong: ctx.id.isLong,
                amount: amount,
                assetPrice: assetPrice,
                collateralPrice: collateralPrice,
                profitAssetPrice: profitAssetPrice,
                feeUsd: ctx.paidFeeUsd,
                hasProfit: hasProfit,
                pnlUsd: pnlUsd,
                remainPosition: subAccount.size,
                remainCollateral: subAccount.collateral
            });
            emit ClosePosition(ctx.id.account, ctx.id.assetId, args);
        }
        // post check
        require(_isAccountMmSafe(subAccount, ctx.id.assetId, ctx.id.isLong, collateralPrice, assetPrice), "!MM");
        _updateSequence();
        _updateBrokerTransactions();
        return assetPrice;
    }

    struct LiquidateContext {
        LibSubAccount.DecodedSubAccountId id;
        uint96 totalFeeUsd;
        uint96 paidFeeUsd;
        uint96 oldPositionSize;
    }

    function liquidate(
        bytes32 subAccountId,
        uint8 profitAssetId, // only used when !isLong
        uint96 collateralPrice,
        uint96 assetPrice,
        uint96 profitAssetPrice // only used when !isLong
    ) external onlyOrderBook returns (uint96) {
        LiquidateContext memory ctx;
        ctx.id = subAccountId.decodeSubAccountId();
        require(ctx.id.account != address(0), "T=0"); // Trader address is zero
        require(_hasAsset(ctx.id.collateralId), "LST"); // the asset is not LiSTed
        require(_hasAsset(ctx.id.assetId), "LST"); // the asset is not LiSTed

        Asset storage asset = _storage.assets[ctx.id.assetId];
        Asset storage collateral = _storage.assets[ctx.id.collateralId];
        SubAccount storage subAccount = _storage.accounts[subAccountId];
        require(!asset.isStable(), "STB"); // can not trade a STaBle coin
        require(asset.isTradable(), "TRD"); // the asset is not TRaDable
        require(asset.isEnabled(), "ENA"); // the token is temporarily not ENAbled
        require(collateral.isEnabled(), "ENA"); // the token is temporarily not ENAbled
        require(ctx.id.isLong || asset.isShortable(), "SHT"); // can not SHorT this asset
        require(subAccount.size > 0, "S=0"); // position Size Is Zero
        assetPrice = LibReferenceOracle.checkPriceWithSpread(
            _storage,
            asset,
            assetPrice,
            ctx.id.isLong ? SpreadType.Bid : SpreadType.Ask
        );
        collateralPrice = LibReferenceOracle.checkPrice(_storage, collateral, collateralPrice);
        if (ctx.id.isLong && !asset.useStableTokenForProfit()) {
            profitAssetId = ctx.id.assetId;
            profitAssetPrice = assetPrice;
        } else {
            require(_isStable(profitAssetId), "STB"); // profit asset should be a STaBle coin
            profitAssetPrice = LibReferenceOracle.checkPrice(
                _storage,
                _storage.assets[profitAssetId],
                profitAssetPrice
            );
        }
        require(_storage.assets[profitAssetId].isEnabled(), "ENA"); // the token is temporarily not ENAbled

        // total
        _decreaseTotalSize(asset, ctx.id.isLong, subAccount.size, subAccount.entryPrice);
        // fee & funding
        bool hasProfit;
        uint96 pnlUsd;
        {
            uint96 fundingFee = _getFundingFeeUsd(subAccount, asset, ctx.id.isLong, assetPrice);
            {
                uint96 positionFee = _getPositionFeeUsd(asset, subAccount.size, assetPrice);
                ctx.totalFeeUsd = fundingFee + positionFee;
            }
            // should mm unsafe
            (hasProfit, pnlUsd) = _positionPnlUsd(asset, subAccount, ctx.id.isLong, subAccount.size, assetPrice);
            require(
                !_isAccountSafe(
                    subAccount,
                    collateralPrice,
                    assetPrice,
                    asset.maintenanceMarginRate,
                    hasProfit,
                    pnlUsd,
                    fundingFee
                ),
                "MMS"
            ); // Maintenance Margin Safe
        }
        // realize pnl
        ctx.oldPositionSize = subAccount.size;
        if (hasProfit) {
            // this case is impossible unless MMRate changes
            ctx.paidFeeUsd = _realizeProfit(
                ctx.id.account,
                pnlUsd,
                ctx.totalFeeUsd,
                _storage.assets[profitAssetId],
                profitAssetPrice
            );
        } else {
            _realizeLoss(subAccount, collateral, collateralPrice, pnlUsd, false);
        }
        subAccount.size = 0;
        subAccount.entryPrice = 0;
        subAccount.entryFunding = 0;
        subAccount.lastIncreasedTime = 0;
        // ignore fees if can not afford
        if (ctx.totalFeeUsd > ctx.paidFeeUsd) {
            uint96 feeCollateral = uint256(ctx.totalFeeUsd - ctx.paidFeeUsd).wdiv(collateralPrice).safeUint96();
            feeCollateral = LibMath.min(feeCollateral, subAccount.collateral);
            subAccount.collateral -= feeCollateral;
            collateral.collectedFee += feeCollateral;
            collateral.spotLiquidity += feeCollateral;
            emit CollectedFee(ctx.id.collateralId, feeCollateral);
            ctx.paidFeeUsd += uint256(feeCollateral).wmul(collateralPrice).safeUint96();
        }
        {
            LiquidateArgs memory args = LiquidateArgs({
                subAccountId: subAccountId,
                collateralId: ctx.id.collateralId,
                profitAssetId: profitAssetId,
                isLong: ctx.id.isLong,
                amount: ctx.oldPositionSize,
                assetPrice: assetPrice,
                collateralPrice: collateralPrice,
                profitAssetPrice: profitAssetPrice,
                feeUsd: ctx.paidFeeUsd,
                hasProfit: hasProfit,
                pnlUsd: pnlUsd,
                remainCollateral: subAccount.collateral
            });
            emit Liquidate(ctx.id.account, ctx.id.assetId, args);
        }
        _updateSequence();
        _updateBrokerTransactions();
        return assetPrice;
    }

    struct WithdrawProfitContext {
        LibSubAccount.DecodedSubAccountId id;
    }

    /**
     *  long : (exit - entry) size = (exit - entry') size + withdrawUSD
     *  short: (entry - exit) size = (entry' - exit) size + withdrawUSD
     */
    function withdrawProfit(
        bytes32 subAccountId,
        uint256 rawAmount,
        uint8 profitAssetId, // only used when !isLong
        uint96 collateralPrice,
        uint96 assetPrice,
        uint96 profitAssetPrice // only used when !isLong
    ) external onlyOrderBook {
        require(rawAmount != 0, "A=0"); // Amount Is Zero
        WithdrawProfitContext memory ctx;
        ctx.id = subAccountId.decodeSubAccountId();
        require(ctx.id.account != address(0), "T=0"); // Trader address is zero
        require(_hasAsset(ctx.id.collateralId), "LST"); // the asset is not LiSTed
        require(_hasAsset(ctx.id.assetId), "LST"); // the asset is not LiSTed

        Asset storage asset = _storage.assets[ctx.id.assetId];
        Asset storage collateral = _storage.assets[ctx.id.collateralId];
        SubAccount storage subAccount = _storage.accounts[subAccountId];
        require(!asset.isStable(), "STB"); // can not trade a STaBle coin
        require(asset.isTradable(), "TRD"); // the asset is not TRaDable
        require(asset.isEnabled(), "ENA"); // the token is temporarily not ENAbled
        require(collateral.isEnabled(), "ENA"); // the token is temporarily not ENAbled
        require(ctx.id.isLong || asset.isShortable(), "SHT"); // can not SHorT this asset
        require(subAccount.size > 0, "S=0"); // position Size Is Zero
        assetPrice = LibReferenceOracle.checkPriceWithSpread(
            _storage,
            asset,
            assetPrice,
            ctx.id.isLong ? SpreadType.Bid : SpreadType.Ask
        );
        collateralPrice = LibReferenceOracle.checkPrice(_storage, collateral, collateralPrice);
        if (ctx.id.isLong && !asset.useStableTokenForProfit()) {
            profitAssetId = ctx.id.assetId;
            profitAssetPrice = assetPrice;
        } else {
            require(_isStable(profitAssetId), "STB"); // profit asset should be a STaBle coin
            profitAssetPrice = LibReferenceOracle.checkPrice(
                _storage,
                _storage.assets[profitAssetId],
                profitAssetPrice
            );
        }
        require(_storage.assets[profitAssetId].isEnabled(), "ENA"); // the token is temporarily not ENAbled

        // fee & funding
        uint96 totalFeeUsd = _getFundingFeeUsd(subAccount, asset, ctx.id.isLong, assetPrice);
        _updateEntryFunding(subAccount, asset, ctx.id.isLong);
        // withdraw
        uint96 deltaUsd = _storage.assets[profitAssetId].toWad(rawAmount);
        deltaUsd = uint256(deltaUsd).wmul(profitAssetPrice).safeUint96();
        deltaUsd += totalFeeUsd;
        // profit
        {
            (bool hasProfit, uint96 pnlUsd) = _positionPnlUsd(
                asset,
                subAccount,
                ctx.id.isLong,
                subAccount.size,
                assetPrice
            );
            require(hasProfit, "U<0"); // profitUsd is negative
            require(pnlUsd >= deltaUsd, "U<W"); // profitUsd can not pay fee or is less than the amount requested for Withdrawal
        }
        _realizeProfit(ctx.id.account, deltaUsd, totalFeeUsd, _storage.assets[profitAssetId], profitAssetPrice);
        // new entry price
        if (ctx.id.isLong) {
            subAccount.entryPrice += uint256(deltaUsd).wdiv(subAccount.size).safeUint96();
            asset.averageLongPrice += uint256(deltaUsd).wdiv(asset.totalLongPosition).safeUint96();
        } else {
            subAccount.entryPrice -= uint256(deltaUsd).wdiv(subAccount.size).safeUint96();
            asset.averageShortPrice -= uint256(deltaUsd).wdiv(asset.totalShortPosition).safeUint96();
        }
        require(_isAccountImSafe(subAccount, ctx.id.assetId, ctx.id.isLong, collateralPrice, assetPrice), "!IM");
        {
            WithdrawProfitArgs memory args = WithdrawProfitArgs({
                subAccountId: subAccountId,
                collateralId: ctx.id.collateralId,
                profitAssetId: profitAssetId,
                isLong: ctx.id.isLong,
                withdrawRawAmount: rawAmount,
                assetPrice: assetPrice,
                collateralPrice: collateralPrice,
                profitAssetPrice: profitAssetPrice,
                entryPrice: subAccount.entryPrice,
                feeUsd: totalFeeUsd
            });
            emit WithdrawProfit(ctx.id.account, ctx.id.assetId, args);
        }
        _updateSequence();
        _updateBrokerTransactions();
    }

    function _increaseTotalSize(
        Asset storage asset,
        bool isLong,
        uint96 amount,
        uint96 price
    ) internal {
        if (isLong) {
            uint96 newPosition = asset.totalLongPosition + amount;
            asset.averageLongPrice = ((uint256(asset.averageLongPrice) *
                uint256(asset.totalLongPosition) +
                uint256(price) *
                uint256(amount)) / uint256(newPosition)).safeUint96();
            asset.totalLongPosition = newPosition;
        } else {
            uint96 newPosition = asset.totalShortPosition + amount;
            asset.averageShortPrice = ((uint256(asset.averageShortPrice) *
                uint256(asset.totalShortPosition) +
                uint256(price) *
                uint256(amount)) / uint256(newPosition)).safeUint96();
            asset.totalShortPosition = newPosition;
        }
    }

    function _decreaseTotalSize(
        Asset storage asset,
        bool isLong,
        uint96 amount,
        uint96 oldEntryPrice
    ) internal {
        if (isLong) {
            uint96 newPosition = asset.totalLongPosition - amount;
            if (newPosition == 0) {
                asset.averageLongPrice = 0;
            } else {
                asset.averageLongPrice = ((uint256(asset.averageLongPrice) *
                    uint256(asset.totalLongPosition) -
                    uint256(oldEntryPrice) *
                    uint256(amount)) / uint256(newPosition)).safeUint96();
            }
            asset.totalLongPosition = newPosition;
        } else {
            uint96 newPosition = asset.totalShortPosition - amount;
            if (newPosition == 0) {
                asset.averageShortPrice = 0;
            } else {
                asset.averageShortPrice = ((uint256(asset.averageShortPrice) *
                    uint256(asset.totalShortPosition) -
                    uint256(oldEntryPrice) *
                    uint256(amount)) / uint256(newPosition)).safeUint96();
            }
            asset.totalShortPosition = newPosition;
        }
    }

    function _realizeProfit(
        address trader,
        uint96 pnlUsd,
        uint96 feeUsd,
        Asset storage profitAsset,
        uint96 profitAssetPrice
    ) internal returns (uint96 paidFeeUsd) {
        paidFeeUsd = LibMath.min(feeUsd, pnlUsd);
        // pnl
        pnlUsd -= paidFeeUsd;
        if (pnlUsd > 0) {
            uint96 profitCollateral = uint256(pnlUsd).wdiv(profitAssetPrice).safeUint96();
            // transfer profit token
            uint96 spot = LibMath.min(profitCollateral, profitAsset.spotLiquidity);
            if (spot > 0) {
                profitAsset.spotLiquidity -= spot; // already deduct fee
                uint256 rawAmount = profitAsset.toRaw(spot);
                profitAsset.transferOut(trader, rawAmount, _storage.weth, _storage.nativeUnwrapper);
            }
            // debt
            {
                uint96 muxTokenAmount = profitCollateral - spot;
                if (muxTokenAmount > 0) {
                    profitAsset.issueMuxToken(trader, uint256(muxTokenAmount));
                    emit IssueMuxToken(profitAsset.isStable() ? 0 : profitAsset.id, profitAsset.isStable(), muxTokenAmount);
                }
            }
        }
        // fee
        if (paidFeeUsd > 0) {
            uint96 paidFeeCollateral = uint256(paidFeeUsd).wdiv(profitAssetPrice).safeUint96();
            profitAsset.collectedFee += paidFeeCollateral; // spotLiquidity was modified above
            emit CollectedFee(profitAsset.id, paidFeeCollateral);
        }
    }

    function _realizeLoss(
        SubAccount storage subAccount,
        Asset storage collateral,
        uint96 collateralPrice,
        uint96 pnlUsd,
        bool isThrowBankrupt
    ) internal {
        if (pnlUsd == 0) {
            return;
        }
        uint96 pnlCollateral = uint256(pnlUsd).wdiv(collateralPrice).safeUint96();
        if (isThrowBankrupt) {
            require(subAccount.collateral >= pnlCollateral, "M=0"); // Margin balance Is Zero. the account is bankrupt
        } else {
            pnlCollateral = LibMath.min(pnlCollateral, subAccount.collateral);
        }
        subAccount.collateral -= pnlCollateral;
        collateral.spotLiquidity += pnlCollateral;
    }
}