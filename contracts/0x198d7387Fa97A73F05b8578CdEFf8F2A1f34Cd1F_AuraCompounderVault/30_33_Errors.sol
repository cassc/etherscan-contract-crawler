// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface Errors {
    // Vault
    error ZeroAddress();
    error ZeroAmount();
    error DepositCooldown();
    error WithdrawCooldown();
    error InsufficientShares();
    error InsufficientAssets();
    error InsufficientRequest();
    error notOwner();

    // Strategy
    error OnlyFromHiddenHand();
    error Unauthorized();
    error InsufficientWithdraw();
    error NoReward();
    error NoSwapper();

    // Swapper
    error Slippage(uint256 amountOut, uint256 minAmountOut);
    error InvalidToken();

    // Misc.
    error InvalidTokenIn(address have, address want);
    error InvalidTokenOut(address have, address want);
    error InvalidAmountIn(uint256 have, uint256 want);
    error InvalidMinAmountOut(uint256 have, uint256 want);
    error InvalidReceiver(address have, address want);
    error InvalidPathSegment(address from, address to);
    error EmptyPath();
    error EmptyTokenIn();
    error EmptyTokenOut();
    error EmptyRouter();
}