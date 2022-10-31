//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {PRBMathUD60x18Typed as Math, PRBMath} from "prb-math/contracts/PRBMathUD60x18Typed.sol";

/**
    @title CommonInterest
    @author iMe Group
    @notice Base contract for interest accrual
 */
abstract contract CommonInterest {
    /**
        @dev Accrual period. As ex,. 1 days or 1 week
     */
    function _accrualPeriod() internal view virtual returns (uint256);

    /**
        @dev Accrual percent per one period, as decimal.
        As example, for 3% there should be 0.03
     */
    function _accrualPercent()
        internal
        view
        virtual
        returns (PRBMath.UD60x18 memory);

    /**
        @dev Take a deposit
     */
    function _deposit(
        address investor,
        uint256 amount,
        uint256 at
    ) internal virtual;

    /**
        @dev Take a withdrawal
        Should revert with WithdrawalOverDebt on withdrawal over debt
     */
    function _withdrawal(
        address investor,
        uint256 amount,
        uint256 at
    ) internal virtual;

    /**
        @dev Yields debt for an investor
     */
    function _debtOf(address investor, uint256 at)
        internal
        view
        virtual
        returns (uint256);

    /**
        @dev Yields debt across all investors
     */
    function _totalDebt(uint256 at) internal view virtual returns (uint256);
}