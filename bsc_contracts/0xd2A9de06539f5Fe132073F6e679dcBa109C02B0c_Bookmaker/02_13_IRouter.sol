// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.15;

interface IRouter {
    function WETH() external pure returns (address);
    function swapExactTokensForETH(
        uint256 amountIn, 
        uint256 amountOutMin, 
        address[] calldata path, 
        address to, 
        uint256 deadline
    )
        external
        returns (uint256[] memory amounts);
    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) 
        external 
        payable 
        returns (uint amountToken, uint amountETH, uint liquidity);
}