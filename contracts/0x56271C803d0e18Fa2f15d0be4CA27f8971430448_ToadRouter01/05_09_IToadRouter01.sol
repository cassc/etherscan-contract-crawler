//SPDX-License-Identifier: GPL-3.0


pragma solidity ^0.8.15;

/**
 * IToadRouter01
 * 
 * Interface for a trusted toad router
 * 
 * 
 */
abstract contract IToadRouter01  {
    string public versionRecipient = "3.0.0";
    address public immutable factory;
    address public immutable WETH;

    constructor(address fac, address weth) {
        factory = fac;
        WETH = weth;
    }

    function swapExactTokensForWETHSupportingFeeOnTransferTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline, uint256 gasReturn) external virtual returns(uint256 outputAmount);
    function swapExactTokensForWETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline, uint256 gasReturn) external virtual returns (uint[] memory amounts);

    function swapExactWETHforTokensSupportingFeeOnTransferTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline, uint256 gasReturn) external virtual returns(uint256 outputAmount);
    function swapExactWETHforTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline, uint256 gasReturn) external virtual returns (uint[] memory amounts);
    
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline, uint256 gasReturn, address[] calldata gasPath) external virtual returns(uint256 outputAmount);
    function swapExactTokensForTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline, uint256 gasReturn, address[] calldata gasPath) external virtual returns (uint[] memory amounts);

    function unwrapWETH(address to, uint256 amount, uint256 gasReturn) external virtual;

    function quote(uint amountA, uint reserveA, uint reserveB) external pure virtual returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure virtual returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure virtual returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view virtual returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view virtual returns (uint[] memory amounts);
}