// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.15;

interface IDepository {
    function transferNative(address wallet, uint256 amount) external payable;

    function transferNative(address[] calldata wallets, uint256[] calldata amounts) external payable;

    function transferERC20(
        address token,
        address wallet,
        uint256 amount
    ) external payable;

    function transferERC20(
        address[] calldata tokens,
        address[] calldata wallets,
        uint256[] calldata amounts
    ) external payable;
}