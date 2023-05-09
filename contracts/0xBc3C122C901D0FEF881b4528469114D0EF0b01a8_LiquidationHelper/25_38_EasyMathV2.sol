// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.13;

/// @dev EasyMathV2 is optimised version of EasyMath, many places was `unchecked` for lower gas cost.
/// There is also fixed version of `calculateUtilization()` method.
library EasyMathV2 {
    error ZeroAssets();
    error ZeroShares();

    function toShare(uint256 amount, uint256 totalAmount, uint256 totalShares)
        internal
        pure
        returns (uint256 result)
    {
        if (totalShares == 0 || totalAmount == 0) {
            return amount;
        }

        result = amount * totalShares;
        // totalAmount is never 0 based on above check, so we can uncheck
        unchecked { result /= totalAmount; }

        // Prevent rounding error
        if (result == 0 && amount != 0) {
            revert ZeroShares();
        }
    }

    function toShareRoundUp(uint256 amount, uint256 totalAmount, uint256 totalShares)
        internal
        pure
        returns (uint256 result)
    {
        if (totalShares == 0 || totalAmount == 0) {
            return amount;
        }

        uint256 numerator = amount * totalShares;
        // totalAmount is not 0, so it is safe to uncheck
        unchecked { result = numerator / totalAmount; }
        
        // Round up
        if (numerator % totalAmount != 0) {
            unchecked { result += 1; }
        }
    }

    function toAmount(uint256 share, uint256 totalAmount, uint256 totalShares)
        internal
        pure
        returns (uint256 result)
    {
        if (totalShares == 0 || totalAmount == 0) {
            return 0;
        }

        result = share * totalAmount;
        // totalShares are not 0, so we can uncheck
        unchecked { result /= totalShares; }

        // Prevent rounding error
        if (result == 0 && share != 0) {
            revert ZeroAssets();
        }
    }

    function toAmountRoundUp(uint256 share, uint256 totalAmount, uint256 totalShares)
        internal
        pure
        returns (uint256 result)
    {
        if (totalShares == 0 || totalAmount == 0) {
            return 0;
        }

        uint256 numerator = share * totalAmount;
        // totalShares are not 0, based on above check, so we can uncheck
        unchecked { result = numerator / totalShares; }
        
        // Round up
        if (numerator % totalShares != 0) {
            unchecked { result += 1; }
        }
    }

    function toValue(uint256 _assetAmount, uint256 _assetPrice, uint256 _assetDecimals)
        internal
        pure
        returns (uint256 value)
    {
        value = _assetAmount * _assetPrice;
        // power of 10 can not be 0, so we can uncheck
        unchecked { value /= 10 ** _assetDecimals; }
    }

    function sum(uint256[] memory _numbers) internal pure returns (uint256 s) {
        for(uint256 i; i < _numbers.length;) {
            s += _numbers[i];
            unchecked { i++; }
        }
    }

    /// @notice Calculates fraction between borrowed and deposited amount of tokens denominated in percentage
    /// @dev It assumes `_dp` = 100%.
    /// @param _dp decimal points used by model
    /// @param _totalDeposits current total deposits for assets
    /// @param _totalBorrowAmount current total borrows for assets
    /// @return utilization value, capped to 100%
    /// Limiting utilisation ratio by 100% max will allows us to perform better interest rate computations
    /// and should not affect any other part of protocol.
    function calculateUtilization(uint256 _dp, uint256 _totalDeposits, uint256 _totalBorrowAmount)
        internal
        pure
        returns (uint256 utilization)
    {
        if (_totalDeposits == 0 || _totalBorrowAmount == 0) return 0;

        utilization = _totalBorrowAmount * _dp;
        // _totalDeposits is not 0 based on above check, so it is safe to uncheck this division
        unchecked { utilization /= _totalDeposits; }

        // cap at 100%
        if (utilization > _dp) utilization = _dp;
    }
}