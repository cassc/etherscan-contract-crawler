// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

struct RouterStorage {
    mapping(address => bool) whitelistedSwapProviders;
    mapping(address => bool) whitelistedMultichainRouter;
    mapping(address => bool) whitelistedConnectorTokens;
    // chainId => connectorTokenHolder
    mapping(uint256 => address) connectorTokenHolder;
    // real token => anyToken (USDC => anyUSDC)
    // todo: check if it's required to have this mapping
    mapping(address => address) connectorTokenToMultichainAnyToken;
}