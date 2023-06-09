// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

// common
error AlreadyInitialised();
error OnlyOwner();
error NotEnougthNativeBalance(uint256 balance, uint256 requiredBalance);
error NotEnougthBalance(
    uint256 balance,
    uint256 requiredBalance,
    address token
);
error UnsupportedToken();

// bridges
error CannotBridgeToSameNetwork();
error UnsupportedDestinationChain(uint64 chainId);