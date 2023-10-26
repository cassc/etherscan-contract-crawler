// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.18;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "./ReserveLogic.sol";
import "./ReserveConfiguration.sol";
import "../utils/WadRayMath.sol";
import "../utils/PercentageMath.sol";
import "../utils/DataTypes.sol";
import "../utils/Errors.sol";
import "../../interfaces/IInterestRateStrategy.sol";

/**
 * @title ValidationLogic library
 * @author Kyoko
 * @notice Implements functions to validate the different actions of the protocol
 */
library ValidationLogic {
    using ReserveLogic for DataTypes.ReserveData;
    using WadRayMath for uint256;
    using PercentageMath for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using ReserveConfiguration for DataTypes.ReserveConfigurationMap;

    uint256 public constant REBALANCE_UP_LIQUIDITY_RATE_THRESHOLD = 4000;
    uint256 public constant REBALANCE_UP_USAGE_RATIO_THRESHOLD = 0.95 * 1e27; //usage ratio of 95%

    /**
     * @dev Validates a deposit action
     * @param reserve The reserve object on which the user is depositing
     * @param amount The amount to be deposited
     */
    function validateDeposit(
        DataTypes.ReserveData storage reserve,
        uint256 amount
    ) external view {
        (bool isActive, bool isFrozen, , ) = reserve.configuration.getFlags();

        require(amount != 0, Errors.VL_INVALID_AMOUNT);
        require(isActive, Errors.VL_NO_ACTIVE_RESERVE);
        require(!isFrozen, Errors.VL_RESERVE_FROZEN);
    }

    /**
     * @dev Validates a withdraw action
     * @param reserve The reserve object
     * @param amount The amount to be withdrawn
     * @param userBalance The balance of the user
     */
    function validateWithdraw(
        DataTypes.ReserveData storage reserve,
        uint256 amount,
        uint256 userBalance
    ) external view {
        require(amount != 0, Errors.VL_INVALID_AMOUNT);
        require(
            amount <= userBalance,
            Errors.VL_NOT_ENOUGH_AVAILABLE_USER_BALANCE
        );

        bool isActive = reserve.configuration.getActive();
        require(isActive, Errors.VL_NO_ACTIVE_RESERVE);
    }

    /**
     * @dev Validates a borrow action
     * @param reserve The reserve state from which the user is borrowing
     * @param asset The address of the asset to borrow
     * @param tokenId The token id of the nft which the user is borrowing
     * @param userAddress The address of the user
     * @param interestRateMode The interest rate mode at which the user is borrowing
     */

    function validateBorrow(
        DataTypes.ReserveData storage reserve,
        address asset,
        uint256 tokenId,
        address userAddress,
        uint256 interestRateMode,
        bool flag
    ) external view {
        (
            bool isActive,
            bool isFrozen,
            bool borrowingEnabled,
            bool stableRateBorrowingEnabled
        ) = reserve.configuration.getFlags();
        require(isActive, Errors.VL_NO_ACTIVE_RESERVE);
        require(!isFrozen, Errors.VL_RESERVE_FROZEN);
        require(borrowingEnabled, Errors.VL_BORROWING_NOT_ENABLED);
        require(
            IERC721Upgradeable(asset).ownerOf(tokenId) == userAddress,
            Errors.VL_NOT_NFT_OWNER
        );

        require(flag, Errors.VL_NOT_SUPPORT);

        //validate interest rate mode
        require(
            uint256(DataTypes.InterestRateMode.VARIABLE) == interestRateMode ||
                uint256(DataTypes.InterestRateMode.STABLE) == interestRateMode,
            Errors.VL_INVALID_INTEREST_RATE_MODE_SELECTED
        );

        if (interestRateMode == uint256(DataTypes.InterestRateMode.STABLE)) {
            //check if the borrow mode is stable and if stable rate borrowing is enabled on this reserve
            require(
                stableRateBorrowingEnabled,
                Errors.VL_STABLE_BORROWING_NOT_ENABLED
            );
        }
    }

    /**
     * @dev Validates a repay action
     * @param reserve The reserve state from which the user is repaying
     * @param borrowInfo The borrow state from which the user is repaying
     * @param user The address of the user msg.sender is repaying for
     * @param amountSent The amount sent for the repayment
     * @param amountPay The amount for user should pay
     * @param floor The floor price of the repay nft
     */
    function validateRepay(
        DataTypes.ReserveData storage reserve,
        DataTypes.BorrowInfo storage borrowInfo,
        address user,
        uint256 amountSent,
        uint256 amountPay,
        uint256 floor
    ) external view {
        bool isActive = reserve.configuration.getActive();
        uint256 liqThreshold = reserve.configuration.getLiquidationThreshold();

        require(isActive, Errors.VL_NO_ACTIVE_RESERVE);
        uint256 minBorrowTime = reserve.configuration.getMinBorrowTime();
        require(
            block.timestamp - borrowInfo.startTime > minBorrowTime,
            Errors.VL_TOO_EARLY
        );
        require(
            borrowInfo.status == DataTypes.Status.BORROW,
            Errors.VL_BAD_STATUS
        );
        require(borrowInfo.user == user, Errors.VL_INVALID_USER);

        require(amountSent > 0, Errors.VL_INVALID_AMOUNT);
        require(amountPay > 0, Errors.VL_NO_DEBT_OF_SELECTED_TYPE);
        require(amountSent >= amountPay, Errors.LP_REQUESTED_AMOUNT_TOO_SMALL);
        if (borrowInfo.rateMode == DataTypes.InterestRateMode.STABLE) {
            require(
                block.timestamp <= borrowInfo.liquidateTime,
                Errors.VL_TOO_LATE
            );
        } else if (borrowInfo.rateMode == DataTypes.InterestRateMode.VARIABLE) {
            require(
                floor > amountPay.percentMul(liqThreshold),
                Errors.VL_BAD_PRICE_TO_REPAY
            );
        }
    }

    /**
     * @dev Validates the liquidation action
     * @param reserve The reserve state from which the user is liquidating
     * @param borrowInfo The borrow state from which the user is liquidating
     * @param amountSent The bid price has been paid
     * @param amountPay The debt should be paid
     * @param floor The floor price of the liquidated nft
     **/
    function validateLiquidationCall(
        DataTypes.ReserveData storage reserve,
        DataTypes.BorrowInfo storage borrowInfo,
        uint256 amountSent,
        uint256 amountPay,
        uint256 floor
    ) external view {
        bool isActive = reserve.configuration.getActive();
        uint256 liqThreshold = reserve.configuration.getLiquidationThreshold();

        require(isActive, Errors.VL_NO_ACTIVE_RESERVE);
        require(
            borrowInfo.user != address(0) &&
                borrowInfo.status == DataTypes.Status.BORROW,
            Errors.VL_BAD_STATUS
        );
        if (borrowInfo.rateMode == DataTypes.InterestRateMode.VARIABLE) {
            require(
                floor < amountPay.percentMul(liqThreshold),
                Errors.KPCM_HEALTH_FACTOR_NOT_BELOW_THRESHOLD
            );
        } else if (borrowInfo.rateMode == DataTypes.InterestRateMode.STABLE) {
            require(
                block.timestamp > borrowInfo.liquidateTime,
                Errors.VL_TOO_EARLY
            );
        }
        require(amountSent > 0, Errors.VL_INVALID_AMOUNT);
        require(amountPay > 0, Errors.VL_NO_DEBT_OF_SELECTED_TYPE);
        require(amountSent >= amountPay, Errors.LP_REQUESTED_AMOUNT_TOO_SMALL);
    }

    /**
     * @dev Validates a stable borrow rate rebalance action
     * @param reserve The reserve state on which the user is getting rebalanced
     * @param reserveAddress The address of the reserve
     * @param stableDebtToken The stable debt token instance
     * @param variableDebtToken The variable debt token instance
     * @param kTokenAddress The address of the kToken contract
     */
    function validateRebalanceStableBorrowRate(
        DataTypes.ReserveData storage reserve,
        address reserveAddress,
        IERC20Upgradeable stableDebtToken,
        IERC20Upgradeable variableDebtToken,
        address kTokenAddress
    ) external view {
        //   DataTypes.Rate memory rate = reserve.rate;
        bool isActive = reserve.configuration.getActive();

        require(isActive, Errors.VL_NO_ACTIVE_RESERVE);

        //if the usage ratio is below 95%, no rebalances are needed
        uint256 totalDebt = (stableDebtToken.totalSupply() +
            variableDebtToken.totalSupply()).wadToRay();
        uint256 availableLiquidity = IERC20Upgradeable(reserveAddress)
            .balanceOf(kTokenAddress)
            .wadToRay();
        uint256 usageRatio = totalDebt == 0
            ? 0
            : totalDebt.rayDiv(availableLiquidity + totalDebt);

        //if the liquidity rate is below REBALANCE_UP_THRESHOLD of the max variable APR at 95% usage,
        //then we allow rebalancing of the stable rate positions.

        uint256 currentLiquidityRate = reserve.currentLiquidityRate;
        // uint256 maxVariableBorrowRate = rate.baseVariableBorrowRate + rate.variableRateSlope1 + rate.variableRateSlope2;
        uint256 maxVariableBorrowRate = IInterestRateStrategy(
            reserve.interestRateStrategyAddress
        ).getMaxVariableBorrowRate(reserve.id);

        require(
            usageRatio >= REBALANCE_UP_USAGE_RATIO_THRESHOLD &&
                currentLiquidityRate <=
                maxVariableBorrowRate.percentMul(
                    REBALANCE_UP_LIQUIDITY_RATE_THRESHOLD
                ),
            Errors.LP_INTEREST_RATE_REBALANCE_CONDITIONS_NOT_MET
        );
    }

    /**
     * @dev Validates the auction action
     * @param auction The auction info
     * @param status The status of borrow nft
     * @param amountSent The bid price has been paid
     **/
    function validateBidCall(
        DataTypes.Auction storage auction,
        DataTypes.Status status,
        uint256 amountSent
    ) internal view {
        require(status == DataTypes.Status.AUCTION, Errors.VL_BAD_STATUS);
        require(!auction.settled, Errors.VL_AUCTION_ALREADY_SETTLED);
        require(
            amountSent > auction.amount,
            Errors.LP_REQUESTED_AMOUNT_TOO_SMALL
        );
        require(block.timestamp < auction.endTime, Errors.VL_TOO_LATE);
    }

    /**
     * @dev Validates the claim action
     * @param borrowInfo The borrow info
     * @param auction The auction info
     * @param user The address of the claim user
     **/
    function validateClaimCall(
        DataTypes.BorrowInfo storage borrowInfo,
        DataTypes.Auction storage auction,
        address user
    ) internal view {
        require(
            borrowInfo.status == DataTypes.Status.AUCTION,
            Errors.VL_BAD_STATUS
        );
        require(!auction.settled, Errors.VL_AUCTION_ALREADY_SETTLED);
        require(auction.bidder == user, Errors.VL_INVALID_USER);
        require(block.timestamp > auction.endTime, Errors.VL_TOO_EARLY);
    }
}