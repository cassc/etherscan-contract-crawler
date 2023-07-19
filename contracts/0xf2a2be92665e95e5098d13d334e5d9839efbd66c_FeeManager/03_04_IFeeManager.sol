// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

interface IFeeManager {
    error WithdrawFailed();

    function setFees(uint256 _fee, uint256 _commissionBPS) external;

    function calculateFees(uint256 amountIn, address tokenIn) external view returns (uint256 fee, uint256 commission);

    function redeemFees() external;
}