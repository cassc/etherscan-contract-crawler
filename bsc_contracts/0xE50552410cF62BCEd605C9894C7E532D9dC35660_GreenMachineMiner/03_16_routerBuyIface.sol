// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface routerBuyIface {
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
}