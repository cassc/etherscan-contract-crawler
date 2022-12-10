// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import {GPv2SafeERC20} from "../../../dependencies/gnosis/contracts/GPv2SafeERC20.sol";
import {SafeCast} from "../../../dependencies/openzeppelin/contracts/SafeCast.sol";
import {IERC20} from "../../../dependencies/openzeppelin/contracts/IERC20.sol";
import {IVariableDebtToken} from "../../../interfaces/IVariableDebtToken.sol";
import {IPToken} from "../../../interfaces/IPToken.sol";
import {UserConfiguration} from "../configuration/UserConfiguration.sol";
import {ReserveConfiguration} from "../configuration/ReserveConfiguration.sol";
import {Helpers} from "../helpers/Helpers.sol";
import {DataTypes} from "../types/DataTypes.sol";
import {ValidationLogic} from "./ValidationLogic.sol";
import {ReserveLogic} from "./ReserveLogic.sol";

/**
 * @title BorrowLogic library
 *
 * @notice Implements the base logic for all the actions related to borrowing
 */
library BorrowLogic {
    using ReserveLogic for DataTypes.ReserveData;
    using GPv2SafeERC20 for IERC20;
    using UserConfiguration for DataTypes.UserConfigurationMap;

    // See `IPool` for descriptions
    event Borrow(
        address indexed reserve,
        address user,
        address indexed onBehalfOf,
        uint256 amount,
        uint256 borrowRate,
        uint16 indexed referralCode
    );
    event Repay(
        address indexed reserve,
        address indexed user,
        address indexed repayer,
        uint256 amount,
        bool usePTokens
    );

    /**
     * @notice Implements the borrow feature. Borrowing allows users that provided collateral to draw liquidity from the
     * ParaSpace protocol proportionally to their collateralization power.
     * @dev  Emits the `Borrow()` event
     * @param reservesData The state of all the reserves
     * @param reservesList The addresses of all the active reserves
     * @param userConfig The user configuration mapping that tracks the supplied/borrowed assets
     * @param params The additional parameters needed to execute the borrow function
     */
    function executeBorrow(
        mapping(address => DataTypes.ReserveData) storage reservesData,
        mapping(uint256 => address) storage reservesList,
        DataTypes.UserConfigurationMap storage userConfig,
        DataTypes.ExecuteBorrowParams memory params
    ) public {
        DataTypes.ReserveData storage reserve = reservesData[params.asset];
        DataTypes.ReserveCache memory reserveCache = reserve.cache();

        reserve.updateState(reserveCache);

        ValidationLogic.validateBorrow(
            reservesData,
            reservesList,
            DataTypes.ValidateBorrowParams({
                reserveCache: reserveCache,
                userConfig: userConfig,
                asset: params.asset,
                userAddress: params.onBehalfOf,
                amount: params.amount,
                reservesCount: params.reservesCount,
                oracle: params.oracle,
                priceOracleSentinel: params.priceOracleSentinel
            })
        );

        bool isFirstBorrowing = false;

        (
            isFirstBorrowing,
            reserveCache.nextScaledVariableDebt
        ) = IVariableDebtToken(reserveCache.variableDebtTokenAddress).mint(
            params.user,
            params.onBehalfOf,
            params.amount,
            reserveCache.nextVariableBorrowIndex
        );

        if (isFirstBorrowing) {
            userConfig.setBorrowing(reserve.id, true);
        }

        reserve.updateInterestRates(
            reserveCache,
            params.asset,
            0,
            params.releaseUnderlying ? params.amount : 0
        );

        if (params.releaseUnderlying) {
            IPToken(reserveCache.xTokenAddress).transferUnderlyingTo(
                params.user,
                params.amount
            );
        }

        emit Borrow(
            params.asset,
            params.user,
            params.onBehalfOf,
            params.amount,
            reserve.currentVariableBorrowRate,
            params.referralCode
        );
    }

    /**
     * @notice Implements the repay feature. Repaying transfers the underlying back to the xToken and clears the
     * equivalent amount of debt for the user by burning the corresponding debt token.
     * @dev  Emits the `Repay()` event
     * @param reservesData The state of all the reserves
     * @param userConfig The user configuration mapping that tracks the supplied/borrowed assets
     * @param params The additional parameters needed to execute the repay function
     * @return The actual amount being repaid
     */
    function executeRepay(
        mapping(address => DataTypes.ReserveData) storage reservesData,
        DataTypes.UserConfigurationMap storage userConfig,
        DataTypes.ExecuteRepayParams memory params
    ) external returns (uint256) {
        DataTypes.ReserveData storage reserve = reservesData[params.asset];
        DataTypes.ReserveCache memory reserveCache = reserve.cache();
        reserve.updateState(reserveCache);

        uint256 variableDebt = Helpers.getUserCurrentDebt(
            params.onBehalfOf,
            reserveCache.variableDebtTokenAddress
        );

        ValidationLogic.validateRepay(
            reserveCache,
            params.amount,
            params.onBehalfOf,
            variableDebt
        );

        uint256 paybackAmount = variableDebt;

        // Allows a user to repay with xTokens without leaving dust from interest.
        if (params.usePTokens && params.amount == type(uint256).max) {
            params.amount = IPToken(reserveCache.xTokenAddress).balanceOf(
                msg.sender
            );
        }

        // if amount user is sending is less than payback amount (debt), update the payback amount to what the user is sending
        if (params.amount < paybackAmount) {
            paybackAmount = params.amount;
        }

        reserveCache.nextScaledVariableDebt = IVariableDebtToken(
            reserveCache.variableDebtTokenAddress
        ).burn(
                params.onBehalfOf,
                paybackAmount,
                reserveCache.nextVariableBorrowIndex
            );

        reserve.updateInterestRates(
            reserveCache,
            params.asset,
            params.usePTokens ? 0 : paybackAmount,
            0
        );

        if (variableDebt - paybackAmount == 0) {
            userConfig.setBorrowing(reserve.id, false);
        }

        if (params.usePTokens) {
            IPToken(reserveCache.xTokenAddress).burn(
                msg.sender,
                reserveCache.xTokenAddress,
                paybackAmount,
                reserveCache.nextLiquidityIndex
            );
        } else {
            // send paybackAmount from user to reserve
            IERC20(params.asset).safeTransferFrom(
                msg.sender,
                reserveCache.xTokenAddress,
                paybackAmount
            );
            IPToken(reserveCache.xTokenAddress).handleRepayment(
                msg.sender,
                paybackAmount
            );
        }

        emit Repay(
            params.asset,
            params.onBehalfOf,
            msg.sender,
            paybackAmount,
            params.usePTokens
        );

        return paybackAmount;
    }
}