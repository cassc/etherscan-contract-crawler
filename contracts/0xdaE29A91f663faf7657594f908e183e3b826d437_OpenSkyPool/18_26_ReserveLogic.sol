// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import './types/DataTypes.sol';
import './helpers/Errors.sol';
import './math/WadRayMath.sol';
import './math/PercentageMath.sol';

import '../interfaces/IOpenSkyInterestRateStrategy.sol';
import '../interfaces/IOpenSkyOToken.sol';
import '../interfaces/IOpenSkyMoneyMarket.sol';

/**
 * @title ReserveLogic library
 * @author OpenSky Labs
 * @notice Implements the logic to update the reserves state
 */
library ReserveLogic {
    using WadRayMath for uint256;
    using PercentageMath for uint256;
    using SafeERC20 for IERC20;

    /**
     * @dev Implements the deposit feature.
     * @param sender The address that called deposit function
     * @param amount The amount of deposit
     * @param onBehalfOf The address that will receive otokens
     **/
    function deposit(
        DataTypes.ReserveData storage reserve,
        address sender,
        uint256 amount,
        address onBehalfOf
    ) external {
        updateState(reserve, 0);

        updateLastMoneyMarketBalance(reserve, amount, 0);

        IOpenSkyOToken oToken = IOpenSkyOToken(reserve.oTokenAddress);
        oToken.mint(onBehalfOf, amount, reserve.lastSupplyIndex);

        IERC20(reserve.underlyingAsset).safeTransferFrom(sender, reserve.oTokenAddress, amount);
        oToken.deposit(amount);
    }

    /**
     * @dev Implements the withdrawal feature.
     * @param sender The address that called withdraw function
     * @param amount The withdrawal amount
     * @param onBehalfOf The address that will receive token
     **/
    function withdraw(
        DataTypes.ReserveData storage reserve,
        address sender,
        uint256 amount,
        address onBehalfOf
    ) external {
        updateState(reserve, 0);

        updateLastMoneyMarketBalance(reserve, 0, amount);

        IOpenSkyOToken oToken = IOpenSkyOToken(reserve.oTokenAddress);
        oToken.burn(sender, amount, reserve.lastSupplyIndex);
        oToken.withdraw(amount, onBehalfOf);
    }

    /**
     * @dev Implements the borrow feature.
     * @param loan the loan data
     **/
    function borrow(DataTypes.ReserveData storage reserve, DataTypes.LoanData memory loan) external {
        updateState(reserve, 0);
        updateInterestPerSecond(reserve, loan.interestPerSecond, 0);
        updateLastMoneyMarketBalance(reserve, 0, loan.amount);

        IOpenSkyOToken oToken = IOpenSkyOToken(reserve.oTokenAddress);
        oToken.withdraw(loan.amount, msg.sender);

        reserve.totalBorrows = reserve.totalBorrows + loan.amount;
    }

    /**
     * @dev Implements the repay function.
     * @param loan The loan data
     * @param amount The amount that will be repaid, including penalty
     * @param borrowBalance The borrow balance
     **/
    function repay(
        DataTypes.ReserveData storage reserve,
        DataTypes.LoanData memory loan,
        uint256 amount,
        uint256 borrowBalance
    ) external {
        updateState(reserve, amount - borrowBalance);
        updateInterestPerSecond(reserve, 0, loan.interestPerSecond);
        updateLastMoneyMarketBalance(reserve, amount, 0);

        IOpenSkyOToken oToken = IOpenSkyOToken(reserve.oTokenAddress);

        IERC20(reserve.underlyingAsset).safeTransferFrom(msg.sender, reserve.oTokenAddress, amount);
        oToken.deposit(amount);

        reserve.totalBorrows = reserve.totalBorrows > borrowBalance ? reserve.totalBorrows - borrowBalance : 0;
    }

    /**
     * @dev Implements the extend feature.
     * @param oldLoan The data of old loan
     * @param newLoan The data of new loan
     * @param borrowInterestOfOldLoan The borrow interest of old loan
     * @param inAmount The amount of token that will be deposited
     * @param outAmount The amount of token that will be withdrawn
     * @param additionalIncome The additional income
     **/
    function extend(
        DataTypes.ReserveData storage reserve,
        DataTypes.LoanData memory oldLoan,
        DataTypes.LoanData memory newLoan,
        uint256 borrowInterestOfOldLoan,
        uint256 inAmount,
        uint256 outAmount,
        uint256 additionalIncome
    ) external {
        updateState(reserve, additionalIncome);
        updateInterestPerSecond(reserve, newLoan.interestPerSecond, oldLoan.interestPerSecond);
        updateLastMoneyMarketBalance(reserve, inAmount, outAmount);

        IOpenSkyOToken oToken = IOpenSkyOToken(reserve.oTokenAddress);
        if (inAmount > 0) {
            IERC20(reserve.underlyingAsset).safeTransferFrom(msg.sender, reserve.oTokenAddress, inAmount);
            oToken.deposit(inAmount);
        }
        if (outAmount > 0) oToken.withdraw(outAmount, msg.sender);

        uint256 sum1 = reserve.totalBorrows + newLoan.amount;
        uint256 sum2 = oldLoan.amount + borrowInterestOfOldLoan;
        reserve.totalBorrows = sum1 > sum2 ? sum1 - sum2 : 0;
    }

    /**
     * @dev Implements start liquidation mechanism.
     * @param loan Loan data
     **/
    function startLiquidation(DataTypes.ReserveData storage reserve, DataTypes.LoanData memory loan) external {
        updateState(reserve, 0);
        updateLastMoneyMarketBalance(reserve, 0, 0);
        updateInterestPerSecond(reserve, 0, loan.interestPerSecond);
    }

    /**
     * @dev Implements end liquidation mechanism.
     * @param amount The amount of token paid
     * @param borrowBalance The borrow balance of loan
     **/
    function endLiquidation(
        DataTypes.ReserveData storage reserve,
        uint256 amount,
        uint256 borrowBalance
    ) external {
        updateState(reserve, amount - borrowBalance);
        updateLastMoneyMarketBalance(reserve, amount, 0);

        IERC20(reserve.underlyingAsset).safeTransferFrom(msg.sender, reserve.oTokenAddress, amount);
        IOpenSkyOToken oToken = IOpenSkyOToken(reserve.oTokenAddress);
        oToken.deposit(amount);

        reserve.totalBorrows = reserve.totalBorrows > borrowBalance ? reserve.totalBorrows - borrowBalance : 0;
    }

    /**
     * @dev Updates the liquidity cumulative index and total borrows
     * @param reserve The reserve object
     * @param additionalIncome The additional income
     **/
    function updateState(DataTypes.ReserveData storage reserve, uint256 additionalIncome) internal {
        (
            uint256 newIndex,
            ,
            uint256 treasuryIncome,
            uint256 borrowingInterestDelta,

        ) = calculateIncome(reserve, additionalIncome);

        require(newIndex <= type(uint128).max, Errors.RESERVE_INDEX_OVERFLOW);
        reserve.lastSupplyIndex = uint128(newIndex);

        // treasury
        treasuryIncome = treasuryIncome / WadRayMath.ray();
        if (treasuryIncome > 0) {
            IOpenSkyOToken(reserve.oTokenAddress).mintToTreasury(treasuryIncome, reserve.lastSupplyIndex);
        }

        reserve.totalBorrows = reserve.totalBorrows + borrowingInterestDelta / WadRayMath.ray();
        reserve.lastUpdateTimestamp = uint40(block.timestamp);
    }

    /**
     * @dev Updates the interest per second, when borrowing and repaying
     * @param reserve The reserve object
     * @param amountToAdd The amount to be added
     * @param amountToRemove The amount to be subtracted
     **/
    function updateInterestPerSecond(
        DataTypes.ReserveData storage reserve,
        uint256 amountToAdd,
        uint256 amountToRemove
    ) internal {
        reserve.borrowingInterestPerSecond = reserve.borrowingInterestPerSecond + amountToAdd - amountToRemove;
    }

    /**
     * @dev Updates last money market balance, after updating the liquidity cumulative index.
     * @param reserve The reserve object
     * @param amountToAdd The amount to be added
     * @param amountToRemove The amount to be subtracted
     **/
    function updateLastMoneyMarketBalance(
        DataTypes.ReserveData storage reserve,
        uint256 amountToAdd,
        uint256 amountToRemove
    ) internal {
        uint256 moneyMarketBalance = getMoneyMarketBalance(reserve);
        reserve.lastMoneyMarketBalance = moneyMarketBalance + amountToAdd - amountToRemove;
    }

    function openMoneyMarket(
        DataTypes.ReserveData storage reserve
    ) internal {
        reserve.isMoneyMarketOn = true;

        uint256 amount = IERC20(reserve.underlyingAsset).balanceOf(reserve.oTokenAddress);
        IOpenSkyOToken(reserve.oTokenAddress).deposit(amount);
    }

    function closeMoneyMarket(
        DataTypes.ReserveData storage reserve
    ) internal {
        address oTokenAddress = reserve.oTokenAddress;
        uint256 amount = IOpenSkyMoneyMarket(reserve.moneyMarketAddress).getBalance(reserve.underlyingAsset, oTokenAddress);
        IOpenSkyOToken(oTokenAddress).withdraw(amount, oTokenAddress);

        reserve.isMoneyMarketOn = false;
    }

    /**
     * @dev Updates last money market balance, after updating the liquidity cumulative index.
     * @param reserve The reserve object
     * @param additionalIncome The amount to be added
     * @return newIndex The new liquidity cumulative index from the last update
     * @return usersIncome The user's income from the last update
     * @return treasuryIncome The treasury income from the last update
     * @return borrowingInterestDelta The treasury income from the last update
     * @return moneyMarketDelta The money market income from the last update
     **/
    function calculateIncome(DataTypes.ReserveData memory reserve, uint256 additionalIncome)
        internal
        view
        returns (
            uint256 newIndex,
            uint256 usersIncome,
            uint256 treasuryIncome,
            uint256 borrowingInterestDelta,
            uint256 moneyMarketDelta
        )
    {
        moneyMarketDelta = getMoneyMarketDelta(reserve) * WadRayMath.ray();
        borrowingInterestDelta = getBorrowingInterestDelta(reserve);
        // ray
        uint256 totalIncome = additionalIncome * WadRayMath.ray() + moneyMarketDelta + borrowingInterestDelta;
        treasuryIncome = totalIncome.percentMul(reserve.treasuryFactor);
        usersIncome = totalIncome - treasuryIncome;

        // index
        newIndex = reserve.lastSupplyIndex;
        uint256 scaledTotalSupply = IOpenSkyOToken(reserve.oTokenAddress).scaledTotalSupply();
        if (scaledTotalSupply > 0) {
            newIndex = usersIncome / scaledTotalSupply + reserve.lastSupplyIndex;
        }

        return (newIndex, usersIncome, treasuryIncome, borrowingInterestDelta, moneyMarketDelta);
    }

    /**
     * @dev Returns the ongoing normalized income for the reserve
     * A value of 1e27 means there is no income. As time passes, the income is accrued
     * A value of 2*1e27 means for each unit of asset one unit of income has been accrued
     * @param reserve The reserve object
     * @return The normalized income. expressed in ray
     **/
    function getNormalizedIncome(DataTypes.ReserveData storage reserve) external view returns (uint256) {
        (uint256 newIndex, , , , ) = calculateIncome(reserve, 0);
        return newIndex;
    }

    /**
     * @dev Returns the available liquidity of the reserve
     * @param reserve The reserve object
     * @return The available liquidity
     **/
    function getMoneyMarketBalance(DataTypes.ReserveData memory reserve) internal view returns (uint256) {
        if (reserve.isMoneyMarketOn) {
            return IOpenSkyMoneyMarket(reserve.moneyMarketAddress).getBalance(reserve.underlyingAsset, reserve.oTokenAddress);
        } else {
            return IERC20(reserve.underlyingAsset).balanceOf(reserve.oTokenAddress);
        }
    }

    /**
     * @dev Returns the money market income of the reserve from the last update
     * @param reserve The reserve object
     * @return The income from money market
     **/
    function getMoneyMarketDelta(DataTypes.ReserveData memory reserve) internal view returns (uint256) {
        uint256 timeDelta = block.timestamp - reserve.lastUpdateTimestamp;

        if (timeDelta == 0) return 0;

        if (reserve.lastMoneyMarketBalance == 0) return 0;

        // get MoneyMarketBalance
        uint256 currentMoneyMarketBalance = getMoneyMarketBalance(reserve);
        if (currentMoneyMarketBalance < reserve.lastMoneyMarketBalance) return 0;

        return currentMoneyMarketBalance - reserve.lastMoneyMarketBalance;
    }

    /**
     * @dev Returns the borrow interest income of the reserve from the last update
     * @param reserve The reserve object
     * @return The income from the NFT loan
     **/
    function getBorrowingInterestDelta(DataTypes.ReserveData memory reserve) internal view returns (uint256) {
        uint256 timeDelta = uint256(block.timestamp) - reserve.lastUpdateTimestamp;
        if (timeDelta == 0) return 0;
        return reserve.borrowingInterestPerSecond * timeDelta;
    }

    /**
     * @dev Returns the total borrow balance of the reserve
     * @param reserve The reserve object
     * @return The total borrow balance
     **/
    function getTotalBorrowBalance(DataTypes.ReserveData memory reserve) public view returns (uint256) {
        return reserve.totalBorrows + getBorrowingInterestDelta(reserve) / WadRayMath.ray();
    }

    /**
     * @dev Returns the total value locked (TVL) of the reserve
     * @param reserve The reserve object
     * @return The total value locked (TVL)
     **/
    function getTVL(DataTypes.ReserveData memory reserve) external view returns (uint256) {
        (, , uint256 treasuryIncome, , ) = calculateIncome(reserve, 0);
        return treasuryIncome / WadRayMath.RAY + IOpenSkyOToken(reserve.oTokenAddress).totalSupply();
    }

    /**
     * @dev Returns the borrow rate of the reserve
     * @param reserve The reserve object
     * @param liquidityAmountToAdd The liquidity amount will be added
     * @param liquidityAmountToRemove The liquidity amount will be removed
     * @param borrowAmountToAdd The borrow amount will be added
     * @param borrowAmountToRemove The borrow amount will be removed
     * @return The borrow rate
     **/
    function getBorrowRate(
        DataTypes.ReserveData memory reserve,
        uint256 liquidityAmountToAdd,
        uint256 liquidityAmountToRemove,
        uint256 borrowAmountToAdd,
        uint256 borrowAmountToRemove
    ) external view returns (uint256) {
        uint256 liquidity = getMoneyMarketBalance(reserve);
        uint256 totalBorrowBalance = getTotalBorrowBalance(reserve);
        return
            IOpenSkyInterestRateStrategy(reserve.interestModelAddress).getBorrowRate(
                reserve.reserveId,
                liquidity + totalBorrowBalance + liquidityAmountToAdd - liquidityAmountToRemove,
                totalBorrowBalance + borrowAmountToAdd - borrowAmountToRemove
            );
    }
}