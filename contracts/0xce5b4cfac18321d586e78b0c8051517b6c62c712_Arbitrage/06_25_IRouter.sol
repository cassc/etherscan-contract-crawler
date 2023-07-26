// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


interface IRouter{
    function creatorAddLiquidityTokens(
        address tokenB,
        uint amountB
    ) external;

    function creatorAddLiquidityETH(
        address pool
    ) external payable;

    function userAddLiquidityETH(
        address pool
    ) external payable;

    function userRedeemLiquidity(
        address pool
    ) external;

    function swapETHForXSD(uint amountOut, address to) external payable;

    function swapXSDForETH(uint amountOut, uint amountInMax, address to) external;

    function swapETHForBankX(uint amountOut, address to) external payable;
    
    function swapBankXForETH(uint amountOut, uint amountInMax, address to) external;

    function swapBankXForXSD(uint bankx_amount, address sender, uint256 slippage) external;

    function swapXSDForBankX(uint XSD_amount, address sender, uint256 slippage) external;
}