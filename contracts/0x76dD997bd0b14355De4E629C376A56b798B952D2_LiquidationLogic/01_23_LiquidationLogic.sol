// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "../../interfaces/IUnwrapLp.sol";
import "../../configuration/UserConfiguration.sol";
import "../../types/DataTypes.sol";
import "../math/MathUtils.sol";
import "./ReserveLogic.sol";
import "./TradeLogic.sol";
import "./CollateralLogic.sol";
import "./GeneralLogic.sol";
import "../storage/LedgerStorage.sol";

library LiquidationLogic {
    using MathUtils for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using UserConfiguration for DataTypes.UserConfiguration;
    using ReserveLogic for DataTypes.ReserveData;
    using CollateralLogic for DataTypes.CollateralData;

    uint256 public constant VERSION = 3;

    event Foreclosed(address indexed user, uint256 totalCollateralPreLtv, int256 pnlUsd);
    event ForeclosedCollateral(address indexed user, address indexed asset, address indexed reinvestment, uint256 amount);
    event ForeclosedPosition(address indexed user, address indexed asset, int256 amount);
    event UnwrappedLp(address assetIn, uint256 amountIn, address assetOut, uint256 amountOut);
    event SettledPosition(address assetIn, address assetOut, uint256 amount, bytes data);
    event WithdrawnLiquidationWalletLong(address asset, uint256 amount);

    function executeUnwrapLp(address unwrapper, address assetIn, uint256 amountIn) external {
        DataTypes.MappingStorage storage mStorage = LedgerStorage.getMappingStorage();

        DataTypes.ProtocolConfig memory protocolConfig = LedgerStorage.getProtocolConfig();

        require(amountIn <= mStorage.liquidatedCollaterals[assetIn], Errors.NOT_ENOUGH_BALANCE);

        IERC20Upgradeable(assetIn).safeApprove(unwrapper, amountIn);

        mStorage.liquidatedCollaterals[assetIn] -= amountIn;

        address assetOut = IUnwrapLp(unwrapper).getAssetOut(assetIn);

        uint256 priorBalance = IERC20Upgradeable(assetOut).balanceOf(address(this));

        (, uint256 amountOut) = IUnwrapLp(unwrapper).unwrap(assetIn, amountIn);

        uint256 receivedBalance = IERC20Upgradeable(assetOut).balanceOf(address(this)) - priorBalance;

        require(receivedBalance == amountOut, Errors.ERROR_UNWRAP_LP);

        uint256 pid = LedgerStorage.getReserveStorage().reservesList[assetOut];
        DataTypes.ReserveData storage reserve = LedgerStorage.getReserveStorage().reserves[pid];
        DataTypes.AssetConfig memory assetConfig = LedgerStorage.getAssetStorage().assetConfigs[assetOut];
        reserve.updateIndex();

        DataTypes.ReserveDataCache memory reserveCache = reserve.cache();

        int256 liquidationWalletAssetPosition = IUserData(protocolConfig.userData).getUserPositionInternal(
            DataTypes.LIQUIDATION_WALLET,
            pid,
            reserveCache.currBorrowIndexRay,
            assetConfig.decimals
        );

        // repay if liquidation wallet has short on asset output
        if (liquidationWalletAssetPosition < 0) {
            TradeLogic.executeLonging(
                reserve,
                assetConfig,
                protocolConfig.treasury,
                liquidationWalletAssetPosition,
                amountOut,
                false
            );

        }

        reserve.postUpdateReserveData();

        IUserData(protocolConfig.userData).changePosition(
            DataTypes.LIQUIDATION_WALLET,
            pid,
            int256(amountOut),
            reserveCache.currBorrowIndexRay,
            assetConfig.decimals
        );

        emit UnwrappedLp(assetIn, amountIn, assetOut, amountOut);
    }

    struct ExecuteForeclosureVars {
        address user;
        uint256 i;
        uint256 collateralPid;
        uint256 reservePid;
        DataTypes.CollateralData localCollateral;
        DataTypes.UserConfiguration localUserConfig;
    }

    /**
     * @notice Executes a foreclosure
     * @param users users
     **/
    function executeForeclosure(address[] memory users) external {
        DataTypes.ProtocolConfig memory protocolConfig = LedgerStorage.getProtocolConfig();

        ExecuteForeclosureVars memory vars;

        for (vars.i = 0; vars.i < users.length; vars.i++) {
            vars.user = users[vars.i];

            (
            DataTypes.UserLiquidity memory currUserLiquidity,
            ) = GeneralLogic.getUserLiquidity(
                vars.user,
                address(0),
                address(0)
            );

            if (!currUserLiquidity.isLiquidatable) {
                continue;
            }

            vars.localUserConfig = IUserData(protocolConfig.userData).getUserConfiguration(vars.user);

            // close collaterals
            vars.collateralPid = 0;
            while (vars.localUserConfig.hasCollateral(vars.collateralPid)) {
                if (vars.localUserConfig.isUsingCollateral(vars.collateralPid)) {
                    DataTypes.CollateralData storage collateral = LedgerStorage.getCollateralStorage().collaterals[vars.collateralPid];
                    vars.localCollateral = collateral;

                    vars.reservePid = LedgerStorage.getReserveStorage().reservesList[vars.localCollateral.asset];
                    DataTypes.ReserveData storage reserve = LedgerStorage.getReserveStorage().reserves[vars.reservePid];

                    reserve.updateIndex();

                    _forecloseCollateral(
                        reserve,
                        collateral,
                        ForecloseCollateralParams(
                            vars.user,
                            protocolConfig.treasury,
                            vars.reservePid,
                            reserve.cache().currBorrowIndexRay,
                            vars.collateralPid,
                            IUserData(protocolConfig.userData),
                            LedgerStorage.getAssetStorage().assetConfigs[vars.localCollateral.asset]
                        )
                    );
                }

                vars.collateralPid++;
            }

            // close positions
            vars.reservePid = 0;
            while (vars.localUserConfig.hasPosition(vars.reservePid)) {
                if (vars.localUserConfig.isUsingPosition(vars.reservePid)) {
                    DataTypes.ReserveData storage reserve = LedgerStorage.getReserveStorage().reserves[vars.reservePid];
                    reserve.updateIndex();

                    _foreclosePosition(
                        reserve,
                        LedgerStorage.getAssetStorage().assetConfigs[reserve.asset],
                        vars.user,
                        protocolConfig.treasury,
                        vars.reservePid,
                        reserve.cache().currBorrowIndexRay,
                        IUserData(protocolConfig.userData)
                    );
                }

                vars.reservePid++;
            }

            emit Foreclosed(
                vars.user,
                currUserLiquidity.totalCollateralUsdPreLtv,
                currUserLiquidity.pnlUsd
            );
        }
    }

    struct ForecloseCollateralParams {
        address user;
        address treasury;
        uint256 reservePoolId;
        uint256 reserveBorrowIndexRay;
        uint256 collateralPoolId;
        IUserData userData;
        DataTypes.AssetConfig assetConfig;
    }

    function _forecloseCollateral(
        DataTypes.ReserveData storage reserve,
        DataTypes.CollateralData storage collateral,
        ForecloseCollateralParams memory params
    ) private {
        DataTypes.MappingStorage storage mStorage = LedgerStorage.getMappingStorage();
        DataTypes.CollateralData memory localCollateral = collateral;

        uint256 currCollateralSupply = localCollateral.getCollateralSupply();
        uint256 currUserCollateral = params.userData.getUserCollateral(
            params.user,
            localCollateral.asset,
            localCollateral.reinvestment,
            false
        );

        params.userData.withdrawCollateral(
            params.user,
            params.collateralPoolId,
            currUserCollateral,
            currCollateralSupply,
            params.assetConfig.decimals
        );

        if (localCollateral.reinvestment != address(0)) {
            IReinvestment(localCollateral.reinvestment).checkpoint(params.user, currUserCollateral);
            IReinvestment(localCollateral.reinvestment).divest(currUserCollateral);
        } else {
            collateral.liquidSupply -= currUserCollateral;
        }

        if (params.assetConfig.kind == DataTypes.AssetKind.LP) {
            mStorage.liquidatedCollaterals[localCollateral.asset] += currUserCollateral;
        } else {
            int256 liquidationAssetPosition = params.userData.getUserPositionInternal(
                DataTypes.LIQUIDATION_WALLET,
                params.reservePoolId,
                params.reserveBorrowIndexRay,
                params.assetConfig.decimals
            );

            // make single asset to be position, repay any short position, but don't added to reserve long supply
            TradeLogic.executeLonging(
                reserve,
                params.assetConfig,
                params.treasury,
                liquidationAssetPosition,
                currUserCollateral,
                false
            );

            params.userData.changePosition(
                DataTypes.LIQUIDATION_WALLET,
                params.reservePoolId,
                int256(currUserCollateral),
                params.reserveBorrowIndexRay,
                params.assetConfig.decimals
            );
        }

        reserve.postUpdateReserveData();

        emit ForeclosedCollateral(params.user, localCollateral.asset, localCollateral.reinvestment, currUserCollateral);
    }

    function _foreclosePosition(
        DataTypes.ReserveData storage reserve,
        DataTypes.AssetConfig memory assetConfig,
        address user,
        address treasury,
        uint256 reservePoolId,
        uint256 currBorrowIndexRay,
        IUserData userData
    ) private {
        address asset = reserve.asset;

        int256 userAssetPosition = userData.getUserPositionInternal(
            user,
            reservePoolId,
            currBorrowIndexRay,
            assetConfig.decimals
        );

        int256 liquidationAssetPosition = userData.getUserPositionInternal(
            DataTypes.LIQUIDATION_WALLET,
            reservePoolId,
            currBorrowIndexRay,
            assetConfig.decimals
        );

        if (userAssetPosition >= 0) {

            /*
            userAssetPosition is passed both as currentPosition and incomingPosition
            this is done to withdraw all users long to ledger contract
            `true`: long supply will decrease
            */
            TradeLogic.executeShorting(
                reserve,
                assetConfig,
                userAssetPosition,
                uint256(userAssetPosition),
                true
            );

            userData.changePosition(
                user,
                reservePoolId,
                userAssetPosition * (- 1),
                currBorrowIndexRay,
                assetConfig.decimals
            );

            /*
            add long to liquidation wallet position (without reinvesting and fees)
            `false`: long supply won't increase
            */
            TradeLogic.executeLonging(
                reserve,
                assetConfig,
                treasury,
                liquidationAssetPosition,
                uint256(userAssetPosition),
                false
            );

            userData.changePosition(
                DataTypes.LIQUIDATION_WALLET,
                reservePoolId,
                userAssetPosition,
                currBorrowIndexRay,
                assetConfig.decimals
            );

        } else {
            // NOTE: TradeLogic.executeShorting will not be called since there is no borrowing happening
            // user position short, we assign that position to liquidation wallet, reserve supply remains the same
            uint256 amountToRepay;

            // repay user short with liquidation wallet if has any
            if (liquidationAssetPosition > 0) {
                /*
                expecting there is enough long position to repay user position
                will be reduce if long position available is not enough, will be overwritten with current long amount
                lacking amount will be a shorting to liquidation wallet
                */
                amountToRepay = uint256(userAssetPosition * (- 1));

                // use liquidation wallet long position to repay users' short position
                // only repay upto the liquidation wallet long position
                if (amountToRepay >= uint256(liquidationAssetPosition)) {
                    amountToRepay = uint256(liquidationAssetPosition);
                }

                // this is repays of user's short with existing long position of liquidation wallet in Ledger
                // only repay what is available
                // `false`: long supply won't increase
                TradeLogic.executeLonging(
                    reserve,
                    assetConfig,
                    treasury,
                    userAssetPosition,
                    amountToRepay,
                    false
                );

            }

            // clear user short position
            userData.changePosition(
                user,
                reservePoolId,
                userAssetPosition * (- 1), // make it positive
                currBorrowIndexRay,
                assetConfig.decimals
            );

            // assign users' short position to liquidation wallet by shorting with users' short amount
            userData.changePosition(
                DataTypes.LIQUIDATION_WALLET,
                reservePoolId,
                userAssetPosition - int256(amountToRepay),
                currBorrowIndexRay,
                assetConfig.decimals
            );
        }

        reserve.postUpdateReserveData();

        emit ForeclosedPosition(user, asset, userAssetPosition);
    }

    function executeWithdrawLiquidationWalletLong(
        address asset, uint256 amount
    ) external {
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
            DataTypes.LIQUIDATION_WALLET,
            address(0),
            asset
        );

        require(cachedData.currLongingPosition > 0, Errors.NOT_ENOUGH_LONG_BALANCE);

        if (uint256(cachedData.currLongingPosition) < amount) {
            amount = uint256(cachedData.currLongingPosition);
        }

        require(currUserLiquidity.pnlUsd > 0, Errors.NEGATIVE_PNL);

        // this is always filled whenever `currPosition` is not zero
        uint256 assetPriceInWad = cachedData.longingPrice.unitToWad(cachedData.longingPriceDecimals);

        uint256 maxAmount = uint256(currUserLiquidity.pnlUsd).wadDiv(assetPriceInWad).wadToUnit(assetConfig.decimals);

        if (maxAmount < amount) {
            amount = maxAmount;
        }

        require(amount != 0, Errors.INVALID_ZERO_AMOUNT);

        TradeLogic.executeShorting(
            reserve,
            assetConfig,
            cachedData.currLongingPosition,
            amount,
            false
        );

        IUserData(protocolConfig.userData).changePosition(
            DataTypes.LIQUIDATION_WALLET,
            pid,
            int256(amount) * (-1),
            reserveCache.currBorrowIndexRay,
            assetConfig.decimals
        );

        reserve.postUpdateReserveData();

        IERC20Upgradeable(asset).safeTransfer(protocolConfig.treasury, amount);

        emit WithdrawnLiquidationWalletLong(asset, amount);
    }
}