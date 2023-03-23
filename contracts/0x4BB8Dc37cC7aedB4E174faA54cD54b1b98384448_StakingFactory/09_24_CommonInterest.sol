//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
    @title CommonInterest
    @author iMe Lab

    @notice Base contract for interest accrual contracts
 */
abstract contract CommonInterest {
    constructor(uint64 interestRate, uint32 accrualPeriod) {
        _interestRate = interestRate;
        _accrualPeriod = accrualPeriod;
    }

    /**
        @notice Error, typically fired on attempt to withdraw over balance
     */
    error WithdrawalOverDebt();

    uint64 internal immutable _interestRate;
    uint32 internal immutable _accrualPeriod;

    /**
        @notice Make a logical deposit

        @param depositor Account who makes a deposit
        @param amount Amount of deposited tokens (integer)
        @param at Timestamp of deposit
     */
    function _deposit(
        address depositor,
        uint256 amount,
        uint64 at
    ) internal virtual;

    /**
        @notice Make a logical withdrawal

        @dev Should revert with WithdrawalOverDebt on balance exceed

        @param depositor Account who makes a withdrawal
        @param amount Amount of withdrawn tokens (integer)
        @param at Timestamp of withdrawal
     */
    function _withdrawal(
        address depositor,
        uint256 amount,
        uint64 at
    ) internal virtual;

    /**
        @notice Make full withdrawal (logical)

        @dev It' a gase-efficient equivalent of
        `_withdrawal(address, uint256, uint65)`, as it shouldn't care
        about previous depositor balance
     */
    function _withdrawal(address depositor) internal virtual;

    /**
        @notice Predicts debt for an investor

        @param depositor The depositor
        @param at Timestamp for debt calculation
     */
    function _debt(
        address depositor,
        uint64 at
    ) internal view virtual returns (uint256);

    /**
        @notice Predict total debt accross all investors

        @param at Timestamp to make a prediction for. Shouldn't be in the past.
     */
    function _totalDebt(uint64 at) internal view virtual returns (uint256);
}