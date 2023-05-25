//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import '@openzeppelin/contracts/access/Ownable.sol';

import './Operators.sol';

/// @title OwnableOperators
/// @author Simon Fremaux (@dievardump)
contract OwnableOperators is Ownable, Operators {
    ////////////////////////////////////////////
    // Only Owner                             //
    ////////////////////////////////////////////

    /// @notice add new operators
    /// @param ops the list of operators to add
    function addOperators(address[] memory ops) external onlyOwner {
        _editOperators(ops, true);
    }

    /// @notice add a new operator
    /// @param operator the operator to add
    function addOperator(address operator) external onlyOwner {
        address[] memory ops = new address[](1);
        ops[0] = operator;
        _editOperators(ops, true);
    }

    /// @notice remove operators
    /// @param ops the list of operators to remove
    function removeOperators(address[] memory ops) external onlyOwner {
        _editOperators(ops, false);
    }

    /// @notice remove an operator
    /// @param operator the operator to remove
    function removeOperator(address operator) external onlyOwner {
        address[] memory ops = new address[](1);
        ops[0] = operator;
        _editOperators(ops, false);
    }
}