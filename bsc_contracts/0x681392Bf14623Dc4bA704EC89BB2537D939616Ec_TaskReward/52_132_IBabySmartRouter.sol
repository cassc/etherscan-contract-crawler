// SPDX-License-Identifier: MIT

pragma solidity ^0.7.4;

interface IBabySmartRouter {

    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address[] calldata factories,
        uint[] calldata fees,
        address to,
        uint deadline
    ) external  returns (uint[] calldata amounts);

    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address[] calldata factories,
        uint[] calldata fees,
        address to,
        uint deadline
    ) external  returns (uint[] calldata amounts);

    function swapExactETHForTokens(
        uint amountOutMin, 
        address[] calldata path, 
        address[] calldata factories, 
        uint[] calldata fees, 
        address to, 
        uint deadline
    ) external  payable returns (uint[] calldata amounts);

    function swapTokensForExactETH(
        uint amountOut, 
        uint amountInMax, 
        address[] calldata path, 
        address[] calldata factories, 
        uint[] calldata fees, 
        address to, 
        uint deadline
    ) external  returns (uint[] calldata amounts);

    function swapExactTokensForETH(
        uint amountIn, 
        uint amountOutMin, 
        address[] calldata path, 
        address[] calldata factories, 
        uint[] calldata fees, 
        address to, 
        uint deadline
    ) external  returns (uint[] calldata amounts);

    function swapETHForExactTokens(
        uint amountOut, 
        address[] calldata path, 
        address[] calldata factories, 
        uint[] calldata fees, 
        address to, 
        uint deadline
    ) external  payable returns (uint[] calldata amounts);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address[] calldata factories,
        uint[] calldata fees,
        address to,
        uint deadline
    ) external ;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address[] calldata factories,
        uint[] calldata fees,
        address to,
        uint deadline
    ) external  payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address[] calldata factories,
        uint[] calldata fees,
        address to,
        uint deadline
    ) external ;

}