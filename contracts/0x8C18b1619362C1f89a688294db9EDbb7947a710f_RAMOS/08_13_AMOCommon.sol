pragma solidity ^0.8.4;
// SPDX-License-Identifier: AGPL-3.0-or-later


library AMOCommon {
    error NotOperator();
    error NotOperatorOrOwner();
    error ZeroSwapLimit();
    error OnlyAMO();
    error AboveCappedAmount(uint256 amountIn);
    error InsufficientBPTAmount(uint256 amount);
    error InvalidBPSValue(uint256 value);
    error InsufficientAmountOutPostcall(uint256 expectedAmount, uint256 actualAmount);
    error InvalidMaxAmounts(uint256 bptMaxAmount, uint256 stableMaxAmount, uint256 templeMaxAmount);
    error InvalidBalancerVaultRequest();
    error NotEnoughCooldown();
    error NoRebalanceUp();
    error NoRebalanceDown();
    error HighSlippage();
    error Paused();
}