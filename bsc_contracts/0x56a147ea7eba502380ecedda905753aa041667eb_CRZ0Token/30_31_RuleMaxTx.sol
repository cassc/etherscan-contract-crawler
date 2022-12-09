// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.12;

contract RuleMaxTx {
    function _ruleMaxTx(uint256 _maxTx, uint256 _amount) public pure virtual {
        require(_amount <= _maxTx, "Rule: max tx amount");
    }
}