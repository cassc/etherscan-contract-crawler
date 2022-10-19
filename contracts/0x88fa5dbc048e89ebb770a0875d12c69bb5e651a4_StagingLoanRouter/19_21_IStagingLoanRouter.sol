// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "../interfaces/IStagingBox.sol";

interface IStagingLoanRouter {
    error SlippageExceeded(uint256 expectedAmount, uint256 minAmount);

    /**
     * @dev Wraps and tranches raw token and then deposits into staging box for a simple underlying bond (A/Z)
     * @param _stagingBox The staging box tied to the Convertible Bond
     * @param _amountRaw The amount of SafeTranche tokens to borrow against
     * @param _minBorrowSlips The minimum expected borrowSlips for slippage protection
     * Requirements:
     *  - `msg.sender` must have `approved` `_amountRaw` collateral tokens to this contract
     */

    function simpleWrapTrancheBorrow(
        IStagingBox _stagingBox,
        uint256 _amountRaw,
        uint256 _minBorrowSlips
    ) external;

    /**
     * @dev Wraps and tranches raw token and then deposits into staging box for any underlying bond
     * @param _stagingBox The staging box tied to the Convertible Bond
     * @param _amountRaw The amount of SafeTranche tokens to borrow against
     * @param _minBorrowSlips The minimum expected borrowSlips for slippage protection
     * Requirements:
     *  - `msg.sender` must have `approved` `_amountRaw` collateral tokens to this contract
     */

    function multiWrapTrancheBorrow(
        IStagingBox _stagingBox,
        uint256 _amountRaw,
        uint256 _minBorrowSlips
    ) external;

    /**
     * @dev withdraws borrowSlip and redeems w/ simple underlying bond (A/Z)
     * @param _stagingBox The staging box tied to the Convertible Bond
     * @param _borrowSlipAmount The amount of borrowSlips to be withdrawn
     * Requirements:
     *  - `msg.sender` must have `approved` `_borrowSlipAmount` BorrowSlip tokens to this contract
     */

    function simpleWithdrawBorrowUnwrap(
        IStagingBox _stagingBox,
        uint256 _borrowSlipAmount
    ) external;

    /**
     * @dev redeems lendSlips for safeSlips and safeSlips for stables
     * @param _stagingBox The staging box tied to the Convertible Bond
     * @param _lendSlipAmount The amount of lendSlips to be redeemed
     * Requirements:
     *  - can only be called when there are stables in the CBB to be repaid
     */

    function redeemLendSlipsForStables(
        IStagingBox _stagingBox,
        uint256 _lendSlipAmount
    ) external;

    /**
     * @dev redeems safeSlips for tranches, redeems tranches for rebasing collateral, unwraps rebasing collateral, and then swaps for stableToken
     * @param _stagingBox The staging box tied to the Convertible Bond
     * @param _safeSlipAmount The amount of lendSlips to be redeemed
     * Requirements:
     *  - can only be called after maturity
     */

    function redeemSafeSlipsForTranchesAndUnwrap(
        IStagingBox _stagingBox,
        uint256 _safeSlipAmount
    ) external;

    /**
     * @dev redeems lendSlips for safeSlips and safeSlips for tranches, redeems tranches for rebasing collateral, unwraps rebasing collateral, and then swaps for stableToken
     * @param _stagingBox The staging box tied to the Convertible Bond
     * @param _lendSlipAmount The amount of lendSlips to be redeemed
     * Requirements:
     *  - can only be called after maturity
     */

    function redeemLendSlipsForTranchesAndUnwrap(
        IStagingBox _stagingBox,
        uint256 _lendSlipAmount
    ) external;

    /**
     * @dev redeems riskSlips for riskTranches, redeems tranches for rebasing collateral, unwraps rebasing collateral
     * @param _stagingBox The staging box tied to the Convertible Bond
     * @param _riskSlipAmount The amount of riskSlips to be redeemed
     * Requirements:
     *  - can only be called after maturity
     */

    function redeemRiskSlipsForTranchesAndUnwrap(
        IStagingBox _stagingBox,
        uint256 _riskSlipAmount
    ) external;

    /**
     * @dev repays stable tokens to CBB and unwraps collateral into underlying
     * @param _stagingBox The staging box tied to the Convertible Bond
     * @param _stableAmount The amount of stableTokens to be repaid
     * @param _stableFees The amount of stableToken fees
     * @param _riskSlipAmount The amount of riskSlips to be repaid with
     * Requirements:
     *  - can only be called prior to maturity
     *  - only to be called with bonds that have A/Z tranche setup
     */

    function repayAndUnwrapSimple(
        IStagingBox _stagingBox,
        uint256 _stableAmount,
        uint256 _stableFees,
        uint256 _riskSlipAmount
    ) external;

    /**
     * @dev repays of users riskSlips w/ stable tokens to CBB and unwraps collateral into underlying
     * @param _stagingBox The staging box tied to the Convertible Bond
     * @param _stableAmount The amount of stableTokens to be repaid
     * @param _stableFees The amount of stableToken fees
     * @param _riskSlipAmount The amount of risk slips being repaid for
     * Requirements:
     *  - can only be called prior to maturity
     *  - only to be called with bonds that have A/Z tranche setup
     */

    function repayMaxAndUnwrapSimple(
        IStagingBox _stagingBox,
        uint256 _stableAmount,
        uint256 _stableFees,
        uint256 _riskSlipAmount
    ) external;

    /**
     * @dev repays stable tokens to CBB and unwraps collateral into underlying
     * @param _stagingBox The staging box tied to the Convertible Bond
     * @param _stableAmount The amount of stableTokens to be repaid
     * @param _stableFees The amount of stableToken fees
     * @param _riskSlipAmount The amount of riskSlips to be repaid with
     * Requirements:
     *  - can only be called after maturity
     */

    function repayAndUnwrapMature(
        IStagingBox _stagingBox,
        uint256 _stableAmount,
        uint256 _stableFees,
        uint256 _riskSlipAmount
    ) external;
}