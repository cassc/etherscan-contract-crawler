// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.4;

import './interfaces/IFlashLoanFeeProvider.sol';
import './roles/Moderable.sol';

contract FlashLoanFeeProvider is IFlashLoanFeeProvider, Moderable {
    uint256 public treasuryFeePercentage = 10;
    uint256 public flashFeePercentage = 5;
    uint256 public flashFeeAmountDivider = 10000;

    /**
     * @dev Custom formula for calculating fee.
     * @param _flashFeePercentage to use for future calculations.
     * @param _flashFeeAmountDivider to use for future calculations.
     */
    function setFee(uint256 _flashFeePercentage, uint256 _flashFeeAmountDivider)
        external
        override
        onlyModerator
    {
        require(_flashFeeAmountDivider > 0, 'AMOUNT_DIVIDER_CANNOT_BE_ZERO');
        require(_flashFeePercentage <= 100, 'FEE_PERCENTAGE_WRONG_VALUE');
        require(_flashFeePercentage <= _flashFeeAmountDivider, "FEE_EXCEED_100_PERCENT");
        flashFeePercentage = _flashFeePercentage;
        flashFeeAmountDivider = _flashFeeAmountDivider;
        emit SetFee(_flashFeePercentage, _flashFeeAmountDivider);
    }

    /**
     * @dev Treasury amount to send.
     * @param amount to be used for getting treasury value to be sent.
     */
    function getTreasuryAmountToSend(uint256 amount) internal view returns (uint256) {
        return (amount * treasuryFeePercentage) / 100;
    }

    /**
     * @dev Change treasury fee percentage.
     * @param _treasuryFeePercentage to use for future calculations.
     */
    function setTreasuryFeePercentage(uint256 _treasuryFeePercentage) external onlyModerator {
        require(_treasuryFeePercentage <= 100, 'TREASURY_FEE_PERCENTAGE_WRONG_VALUE');
        treasuryFeePercentage = _treasuryFeePercentage;
        emit SetTreasuryFeePercentage(treasuryFeePercentage);
    }

    /**
     * @dev Custom formula for calculating fee.
     * @return flashFee calculated.
     */
    function calculateFeeForAmount(uint256 amount) external view returns (uint256) {
        return _calculateFeeForAmount(amount);
    }


    function _calculateFeeForAmount(uint256 amount) internal view returns (uint256) {
        return (amount * flashFeePercentage) / flashFeeAmountDivider;
    }
}