// SPDX-License-Identifier: No License
/**
 * @title Vendor Generic Lending Pool Implementation
 * @author 0xTaiga
 * The legend says that you'r pipi shrinks and boobs get saggy if you fork this contract.
 */

pragma solidity ^0.8.11;

import "../../interfaces/IPoolFactory.sol";
import "../../interfaces/IFeesManager.sol";
import "../../interfaces/IGenericPool.sol";
import "../../utils/Types.sol";
import "./ILendingPool.sol";

library LendingPoolUtils {
    
    /* ========== ERRORS ========== */ 
    error NotAPool();
    error DifferentLendToken();
    error DifferentColToken();
    error DifferentPoolOwner();
    error InvalidExpiry();
    error PoolTypesDiffer();
    error UnableToChargeFullFee();

    /* ========== CONSTANTS ========== */
    uint256 private constant HUNDRED_PERCENT = 100_0000;

    /* ========== FUNCTIONS ========== */

    /// @notice                     Performs validation checks to ensure that both origin and destination pools are valid for the rollover transaction.
    /// @param originSettings       The pool settings of the origin pool.
    /// @param settings             The pool settings of the pool that is being rolled into. Also known as the destination pool. 
    /// @param _originPool          The address of the origin pool.
    /// @param _factory             The address of the pool factory.
    function validatePoolForRollover(
        GeneralPoolSettings memory originSettings,
        GeneralPoolSettings memory settings,
        address _originPool,
        IPoolFactory _factory
    ) external view {
        if (!_factory.pools(_originPool)) revert NotAPool();
        
        if (originSettings.lendToken != settings.lendToken)
            revert DifferentLendToken();

        if (originSettings.colToken != settings.colToken)
            revert DifferentColToken();

        if (originSettings.owner != settings.owner) revert DifferentPoolOwner();

        if (settings.expiry <= originSettings.expiry) revert InvalidExpiry(); // This also prevents pools to rollover into itself

        if (settings.poolType != originSettings.poolType ) revert PoolTypesDiffer();
    }

    /// @notice                      Computes lend token and collateral token amount differences in origin pool and destination pools.
    /// @param _originSettings       The pool settings of the origin pool.
    /// @param _settings             The pool settings of the pool that is being rolled into. Also known as the destination pool. 
    /// @param _colReturned          The amount of collateral moved xfered from origin pool to destination pool.
    /// @return colToReimburse       The amount of collateral to refund borrower in cases where the destination pool's lend ratio is greater than origin pool's lend ratio.
    /// @return lendToRepay          The amount of lend tokens that the borrower must repay in cases where the destination pool's lend ratio less than the origin pool's lend ratio.
    function computeRolloverDifferences(
        GeneralPoolSettings memory _originSettings,
        GeneralPoolSettings memory _settings,
        uint256 _colReturned
    ) external view returns (uint256 colToReimburse, uint256 lendToRepay){
        if (_settings.lendRatio <= _originSettings.lendRatio) { // Borrower needs to repay
            lendToRepay = _computePayoutAmount(
                _colReturned,
                _originSettings.lendRatio - _settings.lendRatio,
                _settings.colToken,
                _settings.lendToken
            );
        }else{ // We need to send collateral
            colToReimburse = _computeReimbursement(
                _colReturned,
                _originSettings.lendRatio,
                _settings.lendRatio
            );
            _colReturned -= colToReimburse;
        }
    }

    /// @notice                        Computes the amount of lend tokens that the borrower will receive. Also computes lender fee amount.
    /// @param _lendToken              Address of lend token.
    /// @param _colToken               Address of collateral token.
    /// @param _mintRatio              Amount of lend tokens to lend for every one unit of deposited collateral.
    /// @param _colDepositAmount       Actual amount of collateral tokens deposited by borrower.
    /// @param _effectiveRate          Borrow rate of pool.
    /// @return additionalFees         Fee amount owed to the lender.
    /// @return rawPayoutAmount        Lend token amount borrower will receive before lender fees and protocol fees are subtracted.
    function computeDebt(
        IERC20 _lendToken,
        IERC20 _colToken,
        uint256 _mintRatio,
        uint256 _colDepositAmount,
        uint48 _effectiveRate
    ) external view returns (uint256 additionalFees, uint256 rawPayoutAmount){
        
        rawPayoutAmount = _computePayoutAmount(
            _colDepositAmount,
            _mintRatio,
            _colToken,
            _lendToken
        );
        additionalFees = (rawPayoutAmount * _effectiveRate) / HUNDRED_PERCENT;
    }
    
    /// @notice                     Compute the amount of lend tokens to send given collateral deposited
    /// @param _colDepositAmount    Amount of collateral deposited in collateral token decimals
    /// @param _lendRatio           LendRatio to use when computing the payout. Useful on rollover payout calculation
    /// @param _colToken            Collateral token being accepted into the pool
    /// @param _lendToken           lend token that is being paid out for collateral
    /// @return                     Lend token amount in lend decimals
    ///
    /// In this function we will need to compute the amount of lend token to send
    /// based on collateral and mint ratio.
    /// Mint Ratio dictates how many lend tokens we send per unit of collateral.
    /// LendRatio must always be passed as 18 decimals.
    /// So:
    ///    lentAmount = lendRatio * colAmount
    /// Given the above information, there are only 2 cases to consider when adjusting decimals:
    ///    lendDecimals > colDecimals + 18 OR lendDecimals <= colDecimals + 18
    /// Based on the situation we will either multiply or divide by 10**x where x is difference between desired decimals
    /// and the decimals we actually have. This way we minimize the number of divisions to at most one and
    /// impact of such division is minimal as it is a division by 10**x and only acts as a mean of reducing decimals count.
    function _computePayoutAmount(
        uint256 _colDepositAmount,
        uint256 _lendRatio,
        IERC20 _colToken,
        IERC20 _lendToken
    ) private view returns (uint256) {
        uint8 lendDecimals = _lendToken.decimals();
        uint8 colDecimals = _colToken.decimals();
        uint8 mintDecimals = 18;

        if (colDecimals + mintDecimals >= lendDecimals) {
            return
                (_colDepositAmount * _lendRatio) /
                (10**(colDecimals + mintDecimals - lendDecimals));
        } else {
            return
                (_colDepositAmount * _lendRatio) *
                (10**(lendDecimals - colDecimals - mintDecimals));
        }
    }

    
    /// @notice                     Compute the amount of collateral to return for lend tokens
    /// @param _repayAmount         Amount of lend token that is being repaid
    /// @param _lendRatio           LendRatio to use when computing the payout
    /// @param _colToken            Collateral token being accepted into the pool
    /// @param _lendToken           Lend token that is being paid out for collateral
    /// @return                     Collateral amount returned for the lend token
    /// Amount of collateral to return is always computed as:
    ///                                 lendTokenAmount
    /// amountOfCollateralReturned  =   ---------------
    ///                                    lendRatio
    /// 
    /// We also need to ensure that the correct amount of decimals are used. Output should always be in
    /// collateral token decimals.
    function computeCollateralReturn(
        uint256 _repayAmount,
        uint256 _lendRatio,
        IERC20 _colToken,
        IERC20 _lendToken
    ) external view returns (uint256) {
        uint8 lendDecimals = _lendToken.decimals();
        uint8 colDecimals = _colToken.decimals();
        uint8 mintDecimals = 18;

        if (colDecimals + mintDecimals <= lendDecimals) { // If lend decimals are larger than sum of 18(for mint ratio) and col decimals, we need to divide result by 10**(difference)
            return
                _repayAmount /
                (_lendRatio * 10**(lendDecimals - mintDecimals - colDecimals));
        } else { // Else we multiply
            return
                (_repayAmount *
                    10**(colDecimals + mintDecimals - lendDecimals)) /
                _lendRatio;
        }
    }

    /// @notice                  Compute the amount of collateral that needs to be sent to user when rolling into a pool with higher mint ratio
    /// @param _colAmount        Collateral amount deposited into the original pool
    /// @param _lendRatio        LendRatio of the original pool
    /// @param _newLendRatio     LendRatio of the new pool
    /// @return                  Collateral reimbursement amount.
    function _computeReimbursement(
        uint256 _colAmount,
        uint256 _lendRatio,
        uint256 _newLendRatio
    ) private pure returns (uint256) {
        return (_colAmount * (_newLendRatio - _lendRatio)) / _newLendRatio;
    }
}