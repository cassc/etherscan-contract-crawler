// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.6;

import "./LootEngine.sol";

/// @title EngineA
/// @author LFG Gaming LLC
/// @notice Concrete implementation of LootEngine
contract EngineA is LootEngine {
  constructor(address furballs, address tradeProxy, address companyProxy)
    LootEngine(furballs, tradeProxy, companyProxy) { }
}