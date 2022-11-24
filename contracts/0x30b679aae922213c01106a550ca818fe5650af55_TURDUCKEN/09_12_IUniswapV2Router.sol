pragma solidity 0.8.4;

// SPDX-License-Identifier: MIT

interface IUniswapV2Router {
    
    function factory() external pure returns (address);
    
    function WETH() external pure returns (address);

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}