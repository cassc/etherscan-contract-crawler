// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

interface ICheapSwapFactory {
    /* ================ TRANSACTION FUNCTIONS ================ */

    function createTokenOutAddress(address tokenOut) external;

    function createTargetAddress(
        address target,
        uint256 value,
        bytes calldata data
    ) external;

    function amountInETH_amountOutMin(address tokenOut, address recipient) external payable;

    /* ================ ADMIN FUNCTIONS ================ */

    function getFee(address to) external;

    function setFee(uint256 _fee) external;

    function setPath(address tokenOut, bytes calldata path) external;

    function setOneETHAmountOutMin(address tokenOut, uint256 oneETHAmountOutMin) external;
}