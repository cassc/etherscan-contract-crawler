// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.4;

interface IFlashLoanFeeProvider {
    /**
     * @dev Set new fee on FlashProvider.
     * @param feePercentage at which the fee was changed.
     * @param feeAmountDivider at which the fee was changed.
     **/
    event SetFee(uint256 feePercentage, uint256 feeAmountDivider);

    /**
     * @dev Set treasury percentage.
     * @param treasuryFeePercentage is the percentage of the fee that is going to a treasury.
     **/
    event SetTreasuryFeePercentage(uint256 treasuryFeePercentage);

    /**
     * @dev Set fee percentage and divider.
     * @param _flashFeePercentage to use for future calculations.
     * @param _flashFeeAmountDivider use for calculating percentages under 1%.
     **/
    function setFee(uint256 _flashFeePercentage, uint256 _flashFeeAmountDivider) external;
}