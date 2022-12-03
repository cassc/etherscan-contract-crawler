/* SPDX-License-Identifier: UNLICENSED */
pragma solidity ^0.6.12;

/**
 * @dev RuleMinTx limits the minimum amount of input tokens a transaction must have
 * @notice RuleMinTx limita o quantidade minima de tokens de input que uma transação pode ter
 */
contract RuleMinTx {
    function _ruleMinTx(uint256 _minTx, uint256 _amount) public pure virtual {
        require(_amount >= _minTx, "Rule: min tx amount");
    }
}