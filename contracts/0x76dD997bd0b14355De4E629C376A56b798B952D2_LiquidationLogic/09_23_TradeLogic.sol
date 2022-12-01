// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "../../types/DataTypes.sol";
import "../../configuration/UserConfiguration.sol";
import "../math/MathUtils.sol";
import "./ReserveLogic.sol";
import "./ReservePoolLogic.sol";
import "./GeneralLogic.sol";
import "./ValidationLogic.sol";
import "../storage/LedgerStorage.sol";

library TradeLogic {
    using MathUtils for uint256;
    using MathUtils for int256;
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using ReserveLogic for DataTypes.ReserveData;
    using UserConfiguration for DataTypes.UserConfiguration;

    uint256 public constant VERSION = 4;

    event Trade(address indexed user, address indexed shortAsset, address indexed longAsset, uint256 soldAmount, uint256 boughtAmount, bytes data, uint256 shortAssetPrice, uint256 longAssetPrice);

    struct ExecuteTradeVars {
        DataTypes.AssetConfig shortAssetConfig;
        DataTypes.AssetConfig longAssetConfig;
        DataTypes.ReserveDataCache shortReserveCache;
        DataTypes.ReserveDataCache longReserveCache;
        DataTypes.ProtocolConfig protocolConfig;
        DataTypes.UserLiquidity currUserLiquidity;
        DataTypes.UserLiquidityCachedData cachedData;
        uint256 shortReservePid;
        uint256 longReservePid;
        uint256 receivedAmount;
        uint256 currShortReserveAvailableSupply;
        uint256 shortAssetPrice;
        uint256 shortAssetPriceDecimals;
        uint256 longAssetPrice;
        uint256 longAssetPriceDecimals;
        uint256 maxSellableAmount;
        uint256 maxBorrowableUsd;
        uint256 additionalSellableUsdFromSelling;
        uint256 additionalSellableUsdFromBuying;
        uint256 maxSellableUsd;
    }

    function executeTrade(
        address user,
        address shortAsset,
        address longAsset,
        uint256 amount,
        bytes memory data
    ) external {
        uint256 userLastTradeBlock = LedgerStorage.getMappingStorage().userLastTradeBlock[user];

        ExecuteTradeVars memory vars;

        vars.protocolConfig = LedgerStorage.getProtocolConfig();

        vars.shortReservePid = LedgerStorage.getReserveStorage().reservesList[shortAsset];
        vars.longReservePid = LedgerStorage.getReserveStorage().reservesList[longAsset];

        DataTypes.ReserveData storage shortReserve = LedgerStorage.getReserveStorage().reserves[vars.shortReservePid];
        DataTypes.ReserveData storage longReserve = LedgerStorage.getReserveStorage().reserves[vars.longReservePid];

        shortReserve.updateIndex();
        longReserve.updateIndex();

        vars.shortAssetConfig = LedgerStorage.getAssetStorage().assetConfigs[shortAsset];
        vars.longAssetConfig = LedgerStorage.getAssetStorage().assetConfigs[longAsset];

        (
        vars.currUserLiquidity,
        vars.cachedData
        ) = GeneralLogic.getUserLiquidity(
            user,
            shortAsset,
            longAsset
        );

        vars.shortReserveCache = shortReserve.cache();
        vars.longReserveCache = longReserve.cache();

        (vars.currShortReserveAvailableSupply,,,,) = shortReserve.getReserveSupplies();

        if (vars.cachedData.shortingPrice == 0) {
            (vars.shortAssetPrice, vars.shortAssetPriceDecimals) = vars.shortAssetConfig.oracle.getAssetPrice(shortAsset);
        } else {
            vars.shortAssetPrice = vars.cachedData.shortingPrice;
            vars.shortAssetPriceDecimals = vars.cachedData.shortingPriceDecimals;
        }

        if (vars.cachedData.longingPrice == 0) {
            (vars.longAssetPrice, vars.longAssetPriceDecimals) = vars.longAssetConfig.oracle.getAssetPrice(longAsset);
        } else {
            vars.longAssetPrice = vars.cachedData.longingPrice;
            vars.longAssetPriceDecimals = vars.cachedData.longingPriceDecimals;
        }

        vars.maxBorrowableUsd = vars.currUserLiquidity.availableLeverageUsd > 0
        ? uint256(vars.currUserLiquidity.availableLeverageUsd)
        : 0;

        // has value if selling asset is a long position
        vars.additionalSellableUsdFromSelling = vars.cachedData.currShortingPosition > 0
        ? GeneralLogic.getAssetUsdFromAmount(
            uint256(vars.cachedData.currShortingPosition),
            vars.shortAssetConfig.decimals,
            vars.shortAssetPrice,
            vars.shortAssetPriceDecimals
        )
        : 0;

        // has value if buying asset is a short position
        vars.additionalSellableUsdFromBuying = vars.cachedData.currLongingPosition < 0
        ? GeneralLogic.getAssetUsdFromAmount(
            uint256((vars.cachedData.currLongingPosition * (- 1))), // make it positive
            vars.longAssetConfig.decimals,
            vars.longAssetPrice,
            vars.longAssetPriceDecimals
        )
        : 0;

        vars.maxSellableUsd = vars.maxBorrowableUsd + vars.additionalSellableUsdFromSelling + vars.additionalSellableUsdFromBuying;

        vars.maxSellableAmount = GeneralLogic.getAssetAmountFromUsd(
            vars.maxSellableUsd,
            vars.shortAssetConfig.decimals,
            vars.shortAssetPrice,
            vars.shortAssetPriceDecimals
        );

        ValidationLogic.validateTrade(
            shortReserve,
            longReserve,
            vars.cachedData.currShortingPosition,
            DataTypes.ValidateTradeParams(
                user,
                amount,
                vars.currShortReserveAvailableSupply,
                vars.maxSellableAmount,
                userLastTradeBlock
            )
        );

        // update reserve data
        executeShorting(
            shortReserve,
            vars.shortAssetConfig,
            vars.cachedData.currShortingPosition,
            amount,
            true
        );

        // update user data
        IUserData(vars.protocolConfig.userData).changePosition(
            user,
            vars.shortReservePid,
            int256(amount) * (- 1),
            vars.shortReserveCache.currBorrowIndexRay,
            vars.shortAssetConfig.decimals
        );

        shortReserve.postUpdateReserveData();

        amount -= transferTradeFee(shortAsset, vars.protocolConfig.treasury, vars.protocolConfig.tradeFeeMantissa, amount);

        vars.receivedAmount = swap(vars.shortAssetConfig, shortAsset, longAsset, amount, data);

        uint256 increasedShortUsd = GeneralLogic.getAssetUsdFromAmount(
            amount,
            vars.shortAssetConfig.decimals,
            vars.shortAssetPrice,
            vars.shortAssetPriceDecimals
        );

        uint256 increasedLongUsd = GeneralLogic.getAssetUsdFromAmount(
            vars.receivedAmount,
            vars.longAssetConfig.decimals,
            vars.longAssetPrice,
            vars.longAssetPriceDecimals
        );

        vars.currUserLiquidity.pnlUsd += (int256(increasedLongUsd) - int256(increasedShortUsd));

        require(
            GeneralLogic.isLiquidatable(
                vars.currUserLiquidity.totalCollateralUsdPreLtv,
                vars.protocolConfig.liquidationRatioMantissa,
                vars.currUserLiquidity.pnlUsd
            ) == false,
            Errors.BAD_TRADE
        );

        // update reserve data
        executeLonging(
            longReserve,
            vars.longAssetConfig,
            vars.protocolConfig.treasury,
            vars.cachedData.currLongingPosition,
            vars.receivedAmount,
            true
        );

        // update user data
        IUserData(vars.protocolConfig.userData).changePosition(
            user,
            vars.longReservePid,
            int256(vars.receivedAmount),
            vars.longReserveCache.currBorrowIndexRay,
            vars.longAssetConfig.decimals
        );

        longReserve.postUpdateReserveData();

        LedgerStorage.getMappingStorage().userLastTradeBlock[user] = block.number;

        emit Trade(
            user,
            shortAsset,
            longAsset,
            amount,
            vars.receivedAmount,
            data,
            vars.shortAssetPrice,
            vars.longAssetPrice
        );
    }

    struct LiquidationTradeVars {
        DataTypes.ProtocolConfig protocolConfig;
        DataTypes.AssetConfig shortAssetConfig;
        DataTypes.AssetConfig longAssetConfig;
        DataTypes.ReserveDataCache shortReserveCache;
        DataTypes.ReserveDataCache longReserveCache;
        uint256 shortReservePid;
        uint256 longReservePid;
        int256 userShortPosition;
        int256 userLongPosition;
        uint256 amountShorted;
        uint256 maxAmountToShort;
        uint256 shortAssetPrice;
        uint256 shortAssetDecimals;
        uint256 longAssetPrice;
        uint256 longAssetDecimals;
        uint256 receivedAmount;
    }

    function liquidationTrade(
        address shortAsset,
        address longAsset,
        uint256 amount,
        bytes memory data
    ) external {
        LiquidationTradeVars memory vars;

        vars.protocolConfig = LedgerStorage.getProtocolConfig();

        vars.shortAssetConfig = LedgerStorage.getAssetStorage().assetConfigs[shortAsset];
        vars.longAssetConfig = LedgerStorage.getAssetStorage().assetConfigs[longAsset];

        vars.shortReservePid = LedgerStorage.getReserveStorage().reservesList[shortAsset];
        vars.longReservePid = LedgerStorage.getReserveStorage().reservesList[longAsset];

        DataTypes.ReserveData storage shortReserve = LedgerStorage.getReserveStorage().reserves[vars.shortReservePid];
        DataTypes.ReserveData storage longReserve = LedgerStorage.getReserveStorage().reserves[vars.longReservePid];

        shortReserve.updateIndex();
        longReserve.updateIndex();

        vars.shortReserveCache = shortReserve.cache();
        vars.longReserveCache = longReserve.cache();

        (vars.shortAssetPrice, vars.shortAssetDecimals) = vars.shortAssetConfig.oracle.getAssetPrice(shortAsset);
        (vars.longAssetPrice, vars.longAssetDecimals) = vars.longAssetConfig.oracle.getAssetPrice(longAsset);

        vars.userShortPosition = IUserData(vars.protocolConfig.userData).getUserPosition(DataTypes.LIQUIDATION_WALLET, shortAsset);
        vars.userLongPosition = IUserData(vars.protocolConfig.userData).getUserPosition(DataTypes.LIQUIDATION_WALLET, longAsset);

        (, vars.amountShorted) = executeShorting(
            shortReserve,
            vars.shortAssetConfig,
            vars.userShortPosition,
            amount,
            false
        );

        if (vars.amountShorted > 0) {
            require(vars.shortAssetConfig.kind == DataTypes.AssetKind.SingleStable, Errors.INVALID_ASSET_INPUT);

            vars.maxAmountToShort = GeneralLogic.getAssetAmountFromUsd(
                GeneralLogic.getAssetUsdFromAmount(
                    vars.userLongPosition.abs(),
                    vars.longAssetConfig.decimals,
                    vars.longAssetPrice,
                    vars.longAssetDecimals
                ),
                vars.shortAssetConfig.decimals,
                vars.shortAssetPrice,
                vars.shortAssetDecimals
            ).unitToWad(vars.shortAssetConfig.decimals)
            .wadMul(vars.protocolConfig.swapBufferLimitPercentage)
            .wadToUnit(vars.shortAssetConfig.decimals);

            require(vars.amountShorted <= vars.maxAmountToShort, Errors.INVALID_AMOUNT_INPUT);
        }

        IUserData(vars.protocolConfig.userData).changePosition(
            DataTypes.LIQUIDATION_WALLET,
            vars.shortReservePid,
            int256(amount) * (- 1),
            vars.shortReserveCache.currBorrowIndexRay,
            vars.shortAssetConfig.decimals
        );

        shortReserve.postUpdateReserveData();

        vars.receivedAmount = swap(vars.shortAssetConfig, shortAsset, longAsset, amount, data);

        executeLonging(
            longReserve,
            vars.longAssetConfig,
            vars.protocolConfig.treasury,
            vars.userLongPosition,
            vars.receivedAmount,
            false
        );

        IUserData(vars.protocolConfig.userData).changePosition(
            DataTypes.LIQUIDATION_WALLET,
            vars.longReservePid,
            int256(vars.receivedAmount),
            vars.longReserveCache.currBorrowIndexRay,
            vars.longAssetConfig.decimals
        );

        longReserve.postUpdateReserveData();

        emit Trade(DataTypes.LIQUIDATION_WALLET, shortAsset, longAsset, amount, vars.receivedAmount, data, vars.shortAssetPrice, vars.longAssetPrice);
    }

    function transferTradeFee(
        address asset,
        address treasury,
        uint256 tradeFeeMantissa,
        uint256 tradeAmount
    ) private returns (uint256) {
        if (tradeFeeMantissa == 0) return 0;

        uint256 feeAmount = tradeAmount.wadMul(tradeFeeMantissa);
        IERC20Upgradeable(asset).safeTransfer(treasury, feeAmount);

        return feeAmount;
    }

    function swap(
        DataTypes.AssetConfig memory shortAssetConfig,
        address shortAsset,
        address longAsset,
        uint256 amount,
        bytes memory data
    ) private returns (uint256) {
        if (
            IERC20Upgradeable(shortAsset).allowance(address(this), address(shortAssetConfig.swapAdapter)) < amount
        ) {
            IERC20Upgradeable(shortAsset).safeApprove(address(shortAssetConfig.swapAdapter), 0);
            IERC20Upgradeable(shortAsset).safeApprove(address(shortAssetConfig.swapAdapter), type(uint256).max);
        }

        return shortAssetConfig.swapAdapter.swap(shortAsset, longAsset, amount, data);
    }

    struct ExecuteShortingVars {
        uint256 unit;
        uint256 amountToBorrow;
        uint256 amountLongToWithdraw;
        uint256 amountReserveToDivest;
        int256 newPosition;
        DataTypes.ReserveDataCache reserveCache;
    }

    /**
     * @notice May decrease long supply, reserve supply and increase utilized supply depending on current users position and shorting amount
     * @param reserve reserveConfig
     * @param assetConfigCache assetConfigCache
     * @param currUserPosition currUserPosition
     * @param amountToShort shorting amount
     * @param fromLongSupply `true` will decrease long supply, `false` will not
     * @return amount
     * @return amount borrowed from the reserve
     **/
    function executeShorting(
        DataTypes.ReserveData storage reserve,
        DataTypes.AssetConfig memory assetConfigCache,
        int256 currUserPosition,
        uint256 amountToShort,
        bool fromLongSupply
    ) public returns (uint256, uint256){
        ExecuteShortingVars memory vars;

        vars.unit = assetConfigCache.decimals;

        vars.reserveCache = reserve.cache();

        if (currUserPosition < 0) {
            // current position is short already
            vars.amountToBorrow = amountToShort;
        } else {
            // use long position to cover for shorting amount when available
            uint256 absCurrUserPosition = currUserPosition.abs();
            if (amountToShort > absCurrUserPosition) {
                // long position is not enough, borrow only lacking amount from reserve
                vars.amountLongToWithdraw = absCurrUserPosition;
                vars.amountToBorrow = amountToShort - absCurrUserPosition;
            } else {
                // long position can cover whole shorting amount, only use required shorting amount
                vars.amountLongToWithdraw = amountToShort;
                vars.amountToBorrow = 0;
            }
        }

        if (vars.amountLongToWithdraw > 0 && fromLongSupply) {
            reserve.longSupply -= vars.amountLongToWithdraw;

            if (reserve.ext.longReinvestment != address(0)) {
                IReinvestment(reserve.ext.longReinvestment).divest(vars.amountLongToWithdraw);
            }
        }

        if (vars.amountToBorrow > 0) {
            reserve.scaledUtilizedSupplyRay += vars.amountToBorrow.unitToRay(vars.unit).rayDiv(vars.reserveCache.currBorrowIndexRay);

            if (reserve.ext.reinvestment != address(0)) {
                IReinvestment(reserve.ext.reinvestment).divest(vars.amountToBorrow);
            } else {
                reserve.liquidSupply -= vars.amountToBorrow;
            }
        }

        require(
            IERC20Upgradeable(reserve.asset).balanceOf(address(this)) >= amountToShort,
            Errors.NOT_ENOUGH_POOL_BALANCE
        );

        return (amountToShort, vars.amountToBorrow);
    }

    struct ExecuteLongingVars {
        uint256 protocolClaimableAmount;
        uint256 amountLongToDeposit;
        uint256 amountToRepay;
        int256 newPosition;
        DataTypes.ReserveDataCache reserveCache;
    }

    /**
     * @notice executeLonging
     * @param reserve reserveConfig
     * @param assetConfigCache assetConfigCache
     * @param treasury treasury
     * @param currUserPosition currUserPosition
     * @param amountToLong amountToLong
     * @param toLongSupply will long amount goes to reserve long supply
     **/
    function executeLonging(
        DataTypes.ReserveData storage reserve,
        DataTypes.AssetConfig memory assetConfigCache,
        address treasury,
        int256 currUserPosition,
        uint256 amountToLong,
        bool toLongSupply
    ) public {
        ExecuteLongingVars memory vars;

        // TODO: can refactor to better condition statement
        require(
            IERC20Upgradeable(reserve.asset).balanceOf(address(this)) >= amountToLong,
            Errors.MISSING_UNDERLYING_ASSET
        );

        vars.reserveCache = reserve.cache();

        if (currUserPosition < 0) {
            // repay current short position
            uint256 absCurrUserPosition = currUserPosition.abs();
            if (amountToLong > absCurrUserPosition) {
                // repay accumulated borrowed amount
                vars.amountToRepay = absCurrUserPosition;
                // long amount can cover all short, remaining long will be added to long supply
                vars.amountLongToDeposit = amountToLong - vars.amountToRepay;
            } else {
                // long amount is enough or not to pay short
                vars.amountLongToDeposit = 0;
                vars.amountToRepay = amountToLong;
            }
        } else {
            // current position is long already
            vars.amountLongToDeposit = amountToLong;
        }

        if (vars.amountLongToDeposit > 0 && toLongSupply) {
            reserve.longSupply += vars.amountLongToDeposit;

            if (reserve.ext.longReinvestment != address(0)) {
                invest(reserve.asset, reserve.ext.longReinvestment, vars.amountLongToDeposit);
            }
        }

        if (vars.amountToRepay > 0) {
            // protocol fee is included to users' debt

            // sent protocol fee portions to treasury
            vars.protocolClaimableAmount = vars.amountToRepay
            .unitToRay(assetConfigCache.decimals)
            .rayDiv(vars.reserveCache.currBorrowIndexRay)
            .rayMul(vars.reserveCache.currProtocolIndexRay)
            .rayToUnit(assetConfigCache.decimals);

            IERC20Upgradeable(reserve.asset).safeTransfer(treasury, vars.protocolClaimableAmount);

            // utilized supply is combination of protocol fee + reserve utilization.
            // reduce utilization according to amount repaid with protocol
            reserve.scaledUtilizedSupplyRay -= vars.amountToRepay
            .unitToRay(assetConfigCache.decimals)
            .rayDiv(vars.reserveCache.currBorrowIndexRay);

            // pay back to reserve pool the remainder
            vars.amountToRepay -= vars.protocolClaimableAmount;

            if (reserve.ext.reinvestment != address(0)) {
                invest(reserve.asset, reserve.ext.reinvestment, vars.amountToRepay);
            } else {
                reserve.liquidSupply += vars.amountToRepay;
            }
        }
    }

    function invest(address asset, address reinvestment, uint256 amount) private {
        if (IERC20Upgradeable(asset).allowance(address(this), reinvestment) < amount) {
            IERC20Upgradeable(asset).safeApprove(reinvestment, 0);
            IERC20Upgradeable(asset).safeApprove(reinvestment, type(uint256).max);
        }
        IReinvestment(reinvestment).invest(amount);
    }
}