// SPDX-License-Identifier: No License
/**
 * @title Vendor Utility Functions
 * @author 0xTaiga
 * The legend says that you'r pipi shrinks and boobs get saggy if you fork this contract.
 */
pragma solidity ^0.8.11;

import "../interfaces/ILendingPool.sol";
import "../interfaces/IPoolFactory.sol";
import "../interfaces/IVendorOracle.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

library VendorUtils {
    using SafeERC20Upgradeable for IERC20;

    error NotAPool();

    error DifferentPoolOwner();

    error InvalidExpiry();

    error DifferentLendToken();

    error OracleNotSet();

    ///@notice                  Make sure new pool can be rolled into
    ///@param _pool             Address of the pool you are about rollover into
    ///@param _factory          Address of the factory that deployed the new pool
    ///@param _lendToken        A lend toke that we will make sure the same as in the original pool
    ///@param _owner            Owner of the original pool to ensure new pool has the same owner
    ///@param _expiry           Expiry of the original pool, to ensure it is shorter than the new once
    function _validateNewPool(
        address _pool,
        address _factory,
        address _lendToken,
        address _owner,
        uint48 _expiry
    ) external view {
        if (!IPoolFactory(_factory).pools(_pool)) revert NotAPool();
        ILendingPool pool = ILendingPool(_pool);
        if (address(pool.lendToken()) != _lendToken)
            revert DifferentLendToken();

        if (pool.owner() != _owner) revert DifferentPoolOwner();

        if (pool.expiry() <= _expiry) revert InvalidExpiry();
    }

    /// @notice                     Compute the amount of lend tokens to send given collateral deposited
    /// @param _colDepositAmount    Amount of collateral deposited in collateral token decimals
    /// @param _mintRatio           MintRatio to use when computing the payout. Useful on rollover payout calculation
    /// @param _colToken            Collateral token being accepted into the pool
    /// @param _lendToken           lend token that is being paid out for collateral
    /// @return                     Lend token amount in lend decimals
    ///
    /// In this function we will need to compute the amount of lend token to send
    /// based on collateral and mint ratio.
    /// Mint Ratio dictates how many lend tokens we send per unit of collateral.
    /// MintRatio must always be passed as 18 decimals.
    /// So:
    ///    lentAmount = mintRatio * colAmount
    /// Given the above information, there are only 2 cases to consider when adjusting decimals:
    ///    lendDecimals > colDecimals + 18 OR lendDecimals <= colDecimals + 18
    /// Based on the situation we will either multiply or divide by 10**x where x is difference between desired decimals
    /// and the decimals we actually have. This way we minimize the number of divisions to at most one and
    /// impact of such division is minimal as it is a division by 10**x and only acts as a mean of reducing decimals count.
    function _computePayoutAmount(
        uint256 _colDepositAmount,
        uint256 _mintRatio,
        address _colToken,
        address _lendToken
    ) public view returns (uint256) {
        IERC20 lendToken = IERC20(_lendToken);
        IERC20 colToken = IERC20(_colToken);
        uint8 lendDecimals = lendToken.decimals();
        uint8 colDecimals = colToken.decimals();
        uint8 mintDecimals = 18;

        if (colDecimals + mintDecimals >= lendDecimals) {
            return
                (_colDepositAmount * _mintRatio) /
                (10**(colDecimals + mintDecimals - lendDecimals));
        } else {
            return
                (_colDepositAmount * _mintRatio) *
                (10**(lendDecimals - colDecimals - mintDecimals));
        }
    }

    /// @notice                     Compute the amount of debt to assign to the user during the borrow or rollover
    /// @dev                        Uses the estimate sent from previous pool if it is within 1% of computed payout value
    /// @param _colDepositAmount    Amount of collateral deposited in collateral token decimals
    /// @param _mintRatio           MintRatio to use when computing the payout. Useful on rollover payout calculation
    /// @param _colToken            Collateral token being accepted into the pool
    /// @param _lendToken           Lend token that is being paid out for collateral
    /// @param _estimate            Amount of lend token that is suggested by the previous pool to avoid additional division
    /// @return                     Lend token amount in lend decimals
    ///
    /// This function is used exclusively on rollover.
    /// Rollover process entails that we pay off all our fees and send all of our
    /// available or required (in case where MintRatio is higher in the second pool)
    /// collateral to a borrow function of the new pool.
    /// Basically our goal is to make borrow amount (without fees) in the second pool the same as in the first pool.
    /// Since we are performing a regular borrow in the second pool we will end up computing the amount of debt again.
    /// This will potentially result in truncation errors and potentially bad debt.
    /// For this reason we should be able to pass the amount owed from the first pool directly to the second pool.
    /// In order to prevent pools sending arbitrary debt amounts, we still perform the computation and check that the passed
    /// debt amount is within the allowed threshold from the computed amount.
    function _computePayoutAmountWithEstimate(
        uint256 _colDepositAmount,
        uint256 _mintRatio,
        address _colToken,
        address _lendToken,
        uint256 _estimate
    ) external view returns (uint256) {
        uint256 compute = _computePayoutAmount(
            _colDepositAmount,
            _mintRatio,
            _colToken,
            _lendToken
        );
        uint256 threshold = (compute * 1_0000) / 100_0000; // Suggested debt should be within 1% of the computed debt
        if (
            compute + threshold <= _estimate || compute - threshold >= _estimate
        ) {
            return _estimate;
        } else {
            return compute;
        }
    }


    /// @notice                     Compute the amount of collateral to return for lend tokens
    /// @param _repayAmount         Amount of lend token that is being repaid
    /// @param _mintRatio           MintRatio to use when computing the payout
    /// @param _colToken            Collateral token being accepted into the pool
    /// @param _lendToken           Lend token that is being paid out for collateral
    /// @return                     Collateral amount returned for the lend token
    // Amount of collateral to return is always computed as:
    //                                 lendTokenAmount
    // amountOfCollateralReturned  =   ---------------
    //                                    mintRatio
    // 
    // We also need to ensure that the correct amount of decimals are used. Output should always be in
    // collateral token decimals.
    function _computeCollateralReturn(
        uint256 _repayAmount,
        uint256 _mintRatio,
        address _colToken,
        address _lendToken
    ) external view returns (uint256) {
        IERC20 lendToken = IERC20(_lendToken);
        IERC20 colToken = IERC20(_colToken);
        uint8 lendDecimals = lendToken.decimals();
        uint8 colDecimals = colToken.decimals();
        uint8 mintDecimals = 18;

        if (colDecimals + mintDecimals <= lendDecimals) { // If lend decimals are larger than sum of 18(for mint ratio) and col decimals, we need to divide result by 10**(difference)
            return
                _repayAmount /
                (_mintRatio * 10**(lendDecimals - mintDecimals - colDecimals));
        } else { // Else we multiply
            return
                (_repayAmount *
                    10**(colDecimals + mintDecimals - lendDecimals)) /
                _mintRatio;
        }
    }

    ///@notice                  Compute the amount fo collateral that needs to be sent to user when rolling into a pool with higher mint ratio
    ///@param _colAmount        Collateral amount deposited into the original pool
    ///@param _mintRatio        MintRatio of the original pool
    ///@param _newMintRatio     MintRatio of the new pool
    function _computeReimbursement(
        uint256 _colAmount,
        uint256 _mintRatio,
        uint256 _newMintRatio
    ) external pure returns (uint256) {
        return (_colAmount * (_newMintRatio - _mintRatio)) / _newMintRatio;
    }

    ///@notice                  Check if col price is below mint ratio
    ///@dev                     We need to ensure that 1 unit of collateral is worth more than what 1 unit of collateral allows to borrow
    ///@param _priceFeed        Address of the oracle to use
    ///@param _colToken         Address of the collateral token
    ///@param _lendToken        Address of the lend token
    ///@param _mintRatio        Mint ratio of the pool
    function _isValidPrice(
        address _priceFeed,
        address _colToken,
        address _lendToken,
        uint256 _mintRatio
    ) external view returns (bool) {
        IVendorOracle priceFeed  = IVendorOracle(_priceFeed);
        if (_priceFeed == address(0)) revert OracleNotSet();
        int256 priceLend = priceFeed.getPriceUSD(_lendToken);
        int256 priceCol = priceFeed.getPriceUSD(_colToken);
        if (priceLend != -1 && priceCol != -1) {
            return (priceCol > ((int256(_mintRatio) * priceLend) / 1e18));
        }
        return false;
    }
}