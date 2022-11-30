// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.6;

interface IFeesCalculator {

    function calculateFees(address lpToken, uint256 amount, uint256 unlockTime,
        uint8 paymentMode) external view returns(uint256 ethFee, uint256 tokenFee, uint256 lpTokenFee);

    function calculateIncreaseAmountFees(address lpToken, uint256 amount, uint256 unlockTime,
        uint8 paymentMode) external view returns(uint256 ethFee, uint256 tokenFee, uint256 lpTokenFee);

}
