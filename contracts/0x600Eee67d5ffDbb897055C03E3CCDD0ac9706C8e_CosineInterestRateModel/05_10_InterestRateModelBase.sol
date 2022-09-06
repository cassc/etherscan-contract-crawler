// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@prb/math/contracts/PRBMathUD60x18.sol";
import "../interfaces/IInterestRateModel.sol";

/// @notice This abstract contract represent common part for interest rate models
abstract contract InterestRateModelBase is IInterestRateModel {
    using PRBMathUD60x18 for uint256;

    /// @notice Number of seconds per year
    uint256 public constant SECONDS_PER_YEAR = 31536000;

    /// @notice Maximal possible rate (100% annually)
    uint256 public constant MAX_RATE = 10**18 / SECONDS_PER_YEAR;

    /// @notice Function that calculates utilization rate for pool
    /// @param balance Total pool balance
    /// @param borrows Total pool borrows
    /// @param reserves Sum of pool reserves and insurance
    /// @return Utilization rate
    function utilizationRate(
        uint256 balance,
        uint256 borrows,
        uint256 reserves
    ) public pure override returns (uint256) {
        if (borrows == 0) {
            return 0;
        }
        return borrows.div(balance + borrows - reserves);
    }

    /// @notice Function that calculates borrow interest rate for pool
    /// @param balance Total pool balance
    /// @param borrows Total pool borrows
    /// @param reserves Sum of pool reserves and insurance
    /// @return Borrow rate per second
    function getBorrowRate(
        uint256 balance,
        uint256 borrows,
        uint256 reserves
    ) public view virtual override returns (uint256);

    /// @notice Function that calculates supply interest rate for pool
    /// @param balance Total pool balance
    /// @param borrows Total pool borrows
    /// @param reserves Sum of pool reserves and insurance
    /// @param reserveFactor Pool reserve factor
    /// @return Supply rate per second
    function getSupplyRate(
        uint256 balance,
        uint256 borrows,
        uint256 reserves,
        uint256 reserveFactor
    ) external view override returns (uint256) {
        uint256 util = utilizationRate(balance, borrows, reserves);
        return
            util.mul(getBorrowRate(balance, borrows, reserves)).mul(
                PRBMathUD60x18.SCALE - reserveFactor
            );
    }

    // INTERNAL FUNCTIONS

    /// @notice Function to convert annual rate to per second rate
    /// @param annualRate Annual rate to convert
    /// @return Converted rate per second
    function _perSecond(uint256 annualRate) internal pure returns (uint256) {
        return annualRate / SECONDS_PER_YEAR;
    }
}