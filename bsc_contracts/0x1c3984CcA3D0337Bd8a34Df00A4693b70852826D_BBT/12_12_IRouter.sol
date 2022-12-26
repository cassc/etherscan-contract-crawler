// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

interface IRouter {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) 
        external;
    function WETH() external pure returns (address);
    function factory() external pure returns (address);
}