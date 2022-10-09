// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interface/IRule.sol";

abstract contract RuleBase is IRule {
    uint256 public constant override BASE = 1e18;
}