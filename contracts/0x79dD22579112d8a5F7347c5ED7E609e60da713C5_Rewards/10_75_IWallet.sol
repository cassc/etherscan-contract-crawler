// SPDX-License-Identifier: MIT

pragma solidity 0.6.11;

interface IWallet {
    function registerAllowedOrderSigner(address signer, bool allowed) external;

    function deposit(address[] calldata tokens, uint256[] calldata amounts) external;

    function withdraw(address[] calldata tokens, uint256[] calldata amounts) external;
}