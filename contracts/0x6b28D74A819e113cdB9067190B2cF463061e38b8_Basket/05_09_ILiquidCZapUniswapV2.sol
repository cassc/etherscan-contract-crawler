// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9 <0.9.0;

interface ILiquidCZapUniswapV2 {
    function LiquidCIn (address beefyVault, uint256 tokenAmountOutMin, address tokenIn, uint256 tokenInAmount) external;
    function LiquidCInETH (address beefyVault, uint256 tokenAmountOutMin) external payable;
    function LiquidCOut (address beefyVault, uint256 withdrawAmount) external;
}