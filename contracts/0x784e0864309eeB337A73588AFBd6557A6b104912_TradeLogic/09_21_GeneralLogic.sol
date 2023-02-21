// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "../../interfaces/IPriceOracleGetter.sol";
import "../../configuration/UserConfiguration.sol";
import "../../types/DataTypes.sol";
import "../math/MathUtils.sol";
import "./ReserveLogic.sol";
import "./CollateralLogic.sol";
import "../storage/LedgerStorage.sol";
import "../../interfaces/IUserData.sol";

library GeneralLogic {
    using MathUtils for uint256;
    using MathUtils for int256;
    using UserConfiguration for DataTypes.UserConfiguration;
    using ReserveLogic for DataTypes.ReserveData;
    using CollateralLogic for DataTypes.CollateralData;

    uint256 public constant VERSION = 3;

    function getAssetAmountFromUsd(
        uint256 usdAmount,
        uint256 assetUnit,
        uint256 assetPrice,
        uint256 assetPriceUnit
    ) public pure returns (uint256) {
        return usdAmount.wadDiv(assetPrice.unitToWad(assetPriceUnit)).wadToUnit(assetUnit);
    }

    function getAssetUsdFromAmount(
        uint256 amount,
        uint256 assetUnit,
        uint256 assetPrice,
        uint256 assetPriceUnit
    ) public pure returns (uint256) {
        return amount.unitToWad(assetUnit).wadMul(assetPrice.unitToWad(assetPriceUnit));
    }

    struct CalculateUserLiquidityVars {
        address asset;
        address reinvestment;
        uint256 currUserCollateral;
        uint256 collateralUsd;
        uint256 positionUsd;
        uint16 i;
        uint256 ltv;
        uint256 assetPrice;
        uint256 assetPriceDecimal;
        int256 currUserPosition;
        DataTypes.ReserveData reserve;
        DataTypes.CollateralData collateral;
        DataTypes.AssetConfig assetConfig;
        DataTypes.UserConfiguration localUserConfig;
    }

    function getUserLiquidity(
        address user,
        address shortingAssetAddress,
        address longingAssetAddress
    ) external view returns (
        DataTypes.UserLiquidity memory,
        DataTypes.UserLiquidityCachedData memory
    ) {
        DataTypes.UserLiquidity memory result;
        DataTypes.UserLiquidityCachedData memory cachedData;
        CalculateUserLiquidityVars memory vars;

        DataTypes.ProtocolConfig memory protocolConfig = LedgerStorage.getProtocolConfig();

        vars.localUserConfig = IUserData(protocolConfig.userData).getUserConfiguration(user);

        if (vars.localUserConfig.isEmpty()) {
            return (result, cachedData);
        }

        vars.i = 0;

        while (vars.localUserConfig.collateral != 0 || vars.localUserConfig.position != 0) {
            // TODO: can it use vars.i?
            if (vars.localUserConfig.isUsingCollateral(0)) {

                vars.collateral = LedgerStorage.getCollateralStorage().collaterals[vars.i];

                vars.asset = vars.collateral.asset;

                vars.reinvestment = vars.collateral.reinvestment;

                vars.assetConfig = LedgerStorage.getAssetStorage().assetConfigs[vars.asset];

                vars.currUserCollateral = IUserData(protocolConfig.userData).getUserCollateralInternal(
                    user,
                    vars.i,
                    vars.collateral.getCollateralSupply(),
                    vars.assetConfig.decimals
                );

                (vars.assetPrice, vars.assetPriceDecimal) = vars.assetConfig.oracle.getAssetPrice(vars.asset);

                vars.collateralUsd = getAssetUsdFromAmount(
                    vars.currUserCollateral,
                    vars.assetConfig.decimals,
                    vars.assetPrice,
                    vars.assetPriceDecimal
                );

                result.totalCollateralUsdPreLtv += vars.collateralUsd;

                result.totalCollateralUsdPostLtv += vars.collateralUsd.wadMul(
                    uint256(vars.collateral.configuration.ltvGwei).unitToWad(9)
                );
            }

            if (vars.localUserConfig.isUsingPosition(0)) {
                vars.reserve = LedgerStorage.getReserveStorage().reserves[vars.i];

                vars.asset = vars.reserve.asset;
                vars.assetConfig = LedgerStorage.getAssetStorage().assetConfigs[vars.asset];

                (,,uint256 borrowIndex) = vars.reserve.getReserveIndexes();

                vars.currUserPosition = IUserData(protocolConfig.userData).getUserPositionInternal(
                    user,
                    vars.reserve.poolId,
                    borrowIndex,
                    vars.assetConfig.decimals
                );

                (vars.assetPrice, vars.assetPriceDecimal) = vars.assetConfig.oracle.getAssetPrice(vars.asset);

                if (shortingAssetAddress == vars.asset) {
                    cachedData.currShortingPosition = vars.currUserPosition;
                    cachedData.shortingPrice = vars.assetPrice;
                    cachedData.shortingPriceDecimals = vars.assetPriceDecimal;
                } else if (longingAssetAddress == vars.asset) {
                    cachedData.currLongingPosition = vars.currUserPosition;
                    cachedData.longingPrice = vars.assetPrice;
                    cachedData.longingPriceDecimals = vars.assetPriceDecimal;
                }

                vars.positionUsd = getAssetUsdFromAmount(
                    vars.currUserPosition.abs(),
                    vars.assetConfig.decimals,
                    vars.assetPrice,
                    vars.assetPriceDecimal
                );

                if (vars.currUserPosition < 0) {
                    result.totalShortUsd += vars.positionUsd;
                } else {
                    result.totalLongUsd += vars.positionUsd;
                }
            }

            vars.localUserConfig.collateral = vars.localUserConfig.collateral >> 1;

            vars.localUserConfig.position = vars.localUserConfig.position >> 1;

            vars.i++;
        }

        result.pnlUsd = int256(result.totalLongUsd) - int256(result.totalShortUsd);

        result.isLiquidatable = isLiquidatable(result.totalCollateralUsdPreLtv, protocolConfig.liquidationRatioMantissa, result.pnlUsd);

        result.totalLeverageUsd = (int256(result.totalCollateralUsdPostLtv) + result.pnlUsd) * int256(protocolConfig.leverageFactor) / int256(1e18);

        result.availableLeverageUsd = result.totalLeverageUsd - int(result.totalShortUsd);

        return (result, cachedData);
    }

    function isLiquidatable(
        uint256 totalCollateralUsdPreLtv,
        uint256 liquidationRatioMantissa,
        int256 pnlUsd
    ) public pure returns (bool) {
        return (int256(totalCollateralUsdPreLtv.wadMul(liquidationRatioMantissa)) + pnlUsd) < 0;
    }

}