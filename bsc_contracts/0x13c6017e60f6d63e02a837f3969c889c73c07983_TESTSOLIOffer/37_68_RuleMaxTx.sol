/* SPDX-License-Identifier: UNLICENSED */
pragma solidity ^0.6.12;

/**
 * @dev RuleMaxTx limits the maximum amount of input tokens a transaction can have
 * @notice RuleMaxTx limita o quantidade máxima de tokens de input que uma transação pode ter
 */
contract RuleMaxTx {
    function _ruleMaxTx(uint256 _maxTx, uint256 _amount) public pure virtual {
        require(_amount <= _maxTx, "Rule: max tx amount");
    }
}