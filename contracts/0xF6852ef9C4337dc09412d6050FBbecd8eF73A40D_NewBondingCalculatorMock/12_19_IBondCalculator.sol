// SPDX-License-Identifier: AGPL-1.0

pragma solidity >=0.7.5 <=0.8.10;

interface IBondCalculator {
    function valuation(address tokenIn, uint256 amount_) external view returns (uint256 amountOut);
}