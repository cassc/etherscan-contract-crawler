// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;


import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "../math/MathUtils.sol";
import "./ReserveLogic.sol";
import "./GeneralLogic.sol";
import "./TradeLogic.sol";
import "../../types/DataTypes.sol";

library PositionLogic {
    using MathUtils for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using ReserveLogic for DataTypes.ReserveData;

    uint256 public constant VERSION = 3;

    event RepaidShort(address user, address asset, uint256 amount, address behalfOf);
    event WithdrawnLong(address user, address asset, uint256 amount);

    function executeRepayShort(
        address user,
        address behalfOf,
        address asset,
        uint256 amount
    ) external {
        uint256 userLastTradeBlock = LedgerStorage.getMappingStorage().userLastTradeBlock[user];

        DataTypes.ProtocolConfig memory protocolConfig = LedgerStorage.getProtocolConfig();

        uint256 pid = LedgerStorage.getReserveStorage().reservesList[asset];
        DataTypes.ReserveData storage reserve = LedgerStorage.getReserveStorage().reserves[pid];
        DataTypes.AssetConfig memory assetConfig = LedgerStorage.getAssetStorage().assetConfigs[asset];

        reserve.updateIndex();

        DataTypes.ReserveDataCache memory reserveCache = reserve.cache();

        int256 currNormalizedPosition = IUserData(protocolConfig.userData).getUserPositionInternal(
            behalfOf,
            pid,
            reserveCache.currBorrowIndexRay,
            assetConfig.decimals
        );

        // cap amount to max repayable
        if (currNormalizedPosition < 0) {
            uint256 absCurrPosition = uint256(currNormalizedPosition * (- 1));
            if (amount > absCurrPosition) {
                amount = absCurrPosition;
            }
        } else {
            amount = 0;
        }

        ValidationLogic.validateRepayShort(
            currNormalizedPosition,
            userLastTradeBlock,
            user,
            asset,
            amount,
            reserve.configuration.state,
            reserve.configuration.mode
        );

        IERC20Upgradeable(asset).safeTransferFrom(user, address(this), amount);

        // repaid amount cannot exceed current short position
        // amount will not be invested to long
        TradeLogic.executeLonging(
            reserve,
            assetConfig,
            protocolConfig.treasury,
            currNormalizedPosition,
            amount,
            true
        );

        reserve.postUpdateReserveData();

        IUserData(protocolConfig.userData).changePosition(
            behalfOf,
            pid,
            int256(amount),
            reserveCache.currBorrowIndexRay,
            assetConfig.decimals
        );

        emit RepaidShort(user, asset, amount, behalfOf);
    }

    struct ExecuteWithdrawLongVars {
        int256 pnlUsd;
        uint256 assetPrice;
        uint256 assetPriceDecimal;
        uint256 assetPriceInWad;
        uint256 assetUnit;
        uint256 maxAmount;
        int256 userAssetPosition;
    }

    function executeWithdrawLong(
        address user,
        address asset,
        uint256 amount
    ) external {
        uint256 userLastTradeBlock = LedgerStorage.getMappingStorage().userLastTradeBlock[user];

        DataTypes.ProtocolConfig memory protocolConfig = LedgerStorage.getProtocolConfig();

        uint256 pid = LedgerStorage.getReserveStorage().reservesList[asset];
        DataTypes.ReserveData storage reserve = LedgerStorage.getReserveStorage().reserves[pid];
        DataTypes.AssetConfig memory assetConfig = LedgerStorage.getAssetStorage().assetConfigs[asset];

        reserve.updateIndex();

        DataTypes.ReserveDataCache memory reserveCache = reserve.cache();

        (
        DataTypes.UserLiquidity memory currUserLiquidity,
        DataTypes.UserLiquidityCachedData memory cachedData
        ) = GeneralLogic.getUserLiquidity(
            user,
            asset,
            address(0)
        );

        ExecuteWithdrawLongVars memory vars;

        require(currUserLiquidity.pnlUsd > 0, Errors.NEGATIVE_AVAILABLE_LEVERAGE);

        if (cachedData.shortingPrice > 0) {
            vars.assetPrice = cachedData.shortingPrice;
            vars.assetPriceDecimal = cachedData.shortingPriceDecimals;
        } else {
            (vars.assetPrice, vars.assetPriceDecimal) = assetConfig.oracle.getAssetPrice(asset);
        }

        vars.assetPriceInWad = vars.assetPrice.unitToWad(vars.assetPriceDecimal);

        // Note: we calculate by wad, which may result in 1 wei less than expected
        // It is okay to be less then to be over
        vars.maxAmount = uint256(currUserLiquidity.pnlUsd).wadDiv(vars.assetPriceInWad).wadToUnit(assetConfig.decimals);

        if (amount > vars.maxAmount) {
            amount = vars.maxAmount;
        }

        vars.userAssetPosition = cachedData.currShortingPosition;

        ValidationLogic.validateWithdrawLong(
            vars.userAssetPosition,
            userLastTradeBlock,
            amount,
            reserve.configuration.state,
            reserve.configuration.mode
        );

        TradeLogic.executeShorting(
            reserve,
            assetConfig,
            vars.userAssetPosition,
            amount,
            true
        );

        IUserData(protocolConfig.userData).changePosition(
            user,
            pid,
            int256(amount) * (- 1),
            reserveCache.currBorrowIndexRay,
            assetConfig.decimals
        );

        reserve.postUpdateReserveData();

        IERC20Upgradeable(asset).safeTransfer(user, amount);

        emit WithdrawnLong(user, asset, amount);
    }
}