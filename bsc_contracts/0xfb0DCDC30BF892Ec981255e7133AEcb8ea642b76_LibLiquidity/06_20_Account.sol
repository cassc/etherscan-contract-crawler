// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.10;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";

import "../libraries/LibSubAccount.sol";
import "../libraries/LibMath.sol";
import "../libraries/LibAsset.sol";
import "../libraries/LibReferenceOracle.sol";
import "./Storage.sol";

contract Account is Storage {
    using LibMath for uint256;
    using LibSubAccount for bytes32;
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using SafeMathUpgradeable for uint256;
    using LibAsset for Asset;

    event DepositCollateral(
        bytes32 indexed subAccountId,
        address indexed trader,
        uint8 collateralId,
        uint256 rawAmount,
        uint96 wadAmount
    );
    event WithdrawCollateral(
        bytes32 indexed subAccountId,
        address indexed trader,
        uint8 collateralId,
        uint256 rawAmount,
        uint96 wadAmount
    );

    function depositCollateral(
        bytes32 subAccountId,
        uint256 rawAmount // NOTE: OrderBook SHOULD transfer rawAmount collateral to LiquidityPool
    ) external onlyOrderBook {
        LibSubAccount.DecodedSubAccountId memory decoded = subAccountId.decodeSubAccountId();
        require(decoded.account != address(0), "T=0"); // Trader address is zero
        require(_hasAsset(decoded.collateralId), "LST"); // the asset is not LiSTed
        require(_hasAsset(decoded.assetId), "LST"); // the asset is not LiSTed
        require(rawAmount != 0, "A=0"); // Amount Is Zero

        SubAccount storage subAccount = _storage.accounts[subAccountId];
        Asset storage asset = _storage.assets[decoded.assetId];
        Asset storage collateral = _storage.assets[decoded.collateralId];
        require(asset.isEnabled(), "ENA"); // the token is temporarily not ENAbled
        require(collateral.isEnabled(), "ENA"); // the token is temporarily not ENAbled
        uint96 wadAmount = collateral.toWad(rawAmount);
        subAccount.collateral += wadAmount;

        emit DepositCollateral(subAccountId, decoded.account, decoded.collateralId, rawAmount, wadAmount);
        _updateSequence();
    }

    function withdrawCollateral(
        bytes32 subAccountId,
        uint256 rawAmount,
        uint96 collateralPrice,
        uint96 assetPrice
    ) external onlyOrderBook {
        require(rawAmount != 0, "A=0"); // Amount Is Zero
        LibSubAccount.DecodedSubAccountId memory decoded = subAccountId.decodeSubAccountId();
        require(decoded.account != address(0), "T=0"); // Trader address is zero
        require(_hasAsset(decoded.collateralId), "LST"); // the asset is not LiSTed
        require(_hasAsset(decoded.assetId), "LST"); // the asset is not LiSTed

        Asset storage asset = _storage.assets[decoded.assetId];
        Asset storage collateral = _storage.assets[decoded.collateralId];
        require(asset.isEnabled(), "ENA"); // the token is temporarily not ENAbled
        require(collateral.isEnabled(), "ENA"); // the token is temporarily not ENAbled
        SubAccount storage subAccount = _storage.accounts[subAccountId];
        assetPrice = LibReferenceOracle.checkPrice(_storage, asset, assetPrice);
        collateralPrice = LibReferenceOracle.checkPrice(_storage, collateral, collateralPrice);

        // fee & funding
        uint96 feeUsd = _getFundingFeeUsd(subAccount, asset, decoded.isLong, assetPrice);
        if (subAccount.size > 0) {
            _updateEntryFunding(subAccount, asset, decoded.isLong);
        }
        {
            uint96 feeCollateral = uint256(feeUsd).wdiv(collateralPrice).safeUint96();
            require(subAccount.collateral >= feeCollateral, "FEE"); // remaining collateral can not pay FEE
            subAccount.collateral -= feeCollateral;
            collateral.collectedFee += feeCollateral;
            collateral.spotLiquidity += feeCollateral;
            emit CollectedFee(decoded.collateralId, feeCollateral);
        }
        // withdraw
        uint96 wadAmount = collateral.toWad(rawAmount);
        require(subAccount.collateral >= wadAmount, "C<W"); // Collateral can not pay fee or is less than the amount requested for Withdrawal
        subAccount.collateral = subAccount.collateral - wadAmount;
        collateral.transferOut(decoded.account, rawAmount, _storage.weth, _storage.nativeUnwrapper);
        require(_isAccountImSafe(subAccount, decoded.assetId, decoded.isLong, collateralPrice, assetPrice), "!IM");

        emit WithdrawCollateral(subAccountId, decoded.account, decoded.collateralId, rawAmount, wadAmount);
        _updateSequence();
    }

    function withdrawAllCollateral(bytes32 subAccountId) external onlyOrderBook {
        LibSubAccount.DecodedSubAccountId memory decoded = subAccountId.decodeSubAccountId();
        SubAccount storage subAccount = _storage.accounts[subAccountId];
        require(subAccount.size == 0, "S>0"); // position Size should be Zero
        require(subAccount.collateral > 0, "C=0"); // Collateral Is Zero

        Asset storage asset = _storage.assets[decoded.assetId];
        Asset storage collateral = _storage.assets[decoded.collateralId];
        require(asset.isEnabled(), "ENA"); // the token is temporarily not ENAbled
        require(collateral.isEnabled(), "ENA"); // the token is temporarily not ENAbled
        uint96 wadAmount = subAccount.collateral;
        uint256 rawAmount = collateral.toRaw(wadAmount);
        subAccount.collateral = 0;
        collateral.transferOut(decoded.account, rawAmount, _storage.weth, _storage.nativeUnwrapper);
        emit WithdrawCollateral(subAccountId, decoded.account, decoded.collateralId, rawAmount, wadAmount);
        _updateSequence();
    }

    function _positionPnlUsd(
        Asset storage asset,
        SubAccount storage subAccount,
        bool isLong,
        uint96 amount,
        uint96 assetPrice
    ) internal view returns (bool hasProfit, uint96 pnlUsd) {
        if (amount == 0) {
            return (false, 0);
        }
        require(assetPrice > 0, "P=0"); // Price Is Zero
        hasProfit = isLong ? assetPrice > subAccount.entryPrice : assetPrice < subAccount.entryPrice;
        uint96 priceDelta = assetPrice >= subAccount.entryPrice
            ? assetPrice - subAccount.entryPrice
            : subAccount.entryPrice - assetPrice;
        if (
            hasProfit &&
            _blockTimestamp() < subAccount.lastIncreasedTime + asset.minProfitTime &&
            priceDelta < uint256(subAccount.entryPrice).rmul(asset.minProfitRate).safeUint96()
        ) {
            hasProfit = false;
            return (false, 0);
        }
        pnlUsd = uint256(priceDelta).wmul(amount).safeUint96();
    }

    // NOTE: settle funding by modify subAccount.collateral before this function
    function _isAccountImSafe(
        SubAccount storage subAccount,
        uint32 assetId,
        bool isLong,
        uint96 collateralPrice,
        uint96 assetPrice
    ) internal view returns (bool) {
        Asset storage asset = _storage.assets[assetId];
        (bool hasProfit, uint96 pnlUsd) = _positionPnlUsd(asset, subAccount, isLong, subAccount.size, assetPrice);
        return _isAccountSafe(subAccount, collateralPrice, assetPrice, asset.initialMarginRate, hasProfit, pnlUsd, 0);
    }

    // NOTE: settle funding by modify subAccount.collateral before this function
    function _isAccountMmSafe(
        SubAccount storage subAccount,
        uint32 assetId,
        bool isLong,
        uint96 collateralPrice,
        uint96 assetPrice
    ) internal view returns (bool) {
        Asset storage asset = _storage.assets[assetId];
        (bool hasProfit, uint96 pnlUsd) = _positionPnlUsd(asset, subAccount, isLong, subAccount.size, assetPrice);
        return
            _isAccountSafe(subAccount, collateralPrice, assetPrice, asset.maintenanceMarginRate, hasProfit, pnlUsd, 0);
    }

    function _isAccountSafe(
        SubAccount storage subAccount,
        uint96 collateralPrice,
        uint96 assetPrice,
        uint32 marginRate,
        bool hasProfit,
        uint96 pnlUsd,
        uint96 fundingFee // fundingFee = 0 if subAccount.collateral was modified
    ) internal view returns (bool) {
        uint256 thresholdUsd = (uint256(subAccount.size) * uint256(assetPrice) * uint256(marginRate)) / 1e18 / 1e5;
        thresholdUsd += fundingFee;
        uint256 collateralUsd = uint256(subAccount.collateral).wmul(collateralPrice);
        // break down "collateralUsd +/- pnlUsd >= thresholdUsd >= 0"
        if (hasProfit) {
            return collateralUsd + pnlUsd >= thresholdUsd;
        } else {
            return collateralUsd >= thresholdUsd + pnlUsd;
        }
    }

    function _getFeeUsd(
        SubAccount storage subAccount,
        Asset storage asset,
        bool isLong,
        uint96 amount,
        uint96 assetPrice
    ) internal view returns (uint96) {
        return _getFundingFeeUsd(subAccount, asset, isLong, assetPrice) + _getPositionFeeUsd(asset, amount, assetPrice);
    }

    function _getFundingFeeUsd(
        SubAccount storage subAccount,
        Asset storage asset,
        bool isLong,
        uint96 assetPrice
    ) internal view returns (uint96) {
        if (subAccount.size == 0) {
            return 0;
        }
        uint256 cumulativeFunding;
        if (isLong) {
            cumulativeFunding = asset.longCumulativeFundingRate - subAccount.entryFunding;
            cumulativeFunding = cumulativeFunding.wmul(assetPrice);
        } else {
            cumulativeFunding = asset.shortCumulativeFunding - subAccount.entryFunding;
        }
        return cumulativeFunding.wmul(subAccount.size).safeUint96();
    }

    function _getPositionFeeUsd(
        Asset storage asset,
        uint96 amount,
        uint96 assetPrice
    ) internal view returns (uint96) {
        uint256 feeUsd = ((uint256(assetPrice) * uint256(asset.positionFeeRate)) * uint256(amount)) / 1e5 / 1e18;
        return feeUsd.safeUint96();
    }

    function _getLiquidationFeeUsd(
        Asset storage asset,
        uint96 amount,
        uint96 assetPrice
    ) internal view returns (uint96) {
        uint256 feeUsd = ((uint256(assetPrice) * uint256(asset.liquidationFeeRate)) * uint256(amount)) / 1e5 / 1e18;
        return feeUsd.safeUint96();
    }

    // note: you can skip this function if newPositionSize > 0
    function _updateEntryFunding(
        SubAccount storage subAccount,
        Asset storage asset,
        bool isLong
    ) internal {
        if (isLong) {
            subAccount.entryFunding = asset.longCumulativeFundingRate;
        } else {
            subAccount.entryFunding = asset.shortCumulativeFunding;
        }
    }
}