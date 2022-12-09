// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.12;

contract RuleMinTx {
    function _ruleMinTx(uint256 _minTx, uint256 _amount) public pure virtual {
        require(_amount >= _minTx, "Rule: min tx amount");
    }
}