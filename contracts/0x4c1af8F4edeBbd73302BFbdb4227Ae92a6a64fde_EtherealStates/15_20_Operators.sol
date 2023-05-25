//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/// @title Operators
/// @author Simon Fremaux (@dievardump)
contract Operators {
    error NotAuthorized();
    error InvalidAddress(address invalid);

    mapping(address => bool) public operators;

    modifier onlyOperator() virtual {
        if (!isOperator(msg.sender)) revert NotAuthorized();
        _;
    }

    /// @notice tells if an account is an operator or not
    /// @param account the address to check
    function isOperator(address account) public view virtual returns (bool) {
        return operators[account];
    }

    /// @dev set operator state to `isOperator` for ops[]
    function _editOperators(address[] memory ops, bool isOperatorRole)
        internal
    {
        for (uint256 i; i < ops.length; i++) {
            if (ops[i] == address(0)) revert InvalidAddress(ops[i]);
            operators[ops[i]] = isOperatorRole;
        }
    }
}