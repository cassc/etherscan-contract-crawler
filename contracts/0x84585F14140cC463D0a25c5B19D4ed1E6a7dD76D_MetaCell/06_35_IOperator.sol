// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.3;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

/**
 * @title Interface to add alowed operator in additiona to owner
 */
abstract contract IOperator {
    using EnumerableSet for EnumerableSet.AddressSet;
    EnumerableSet.AddressSet private operators;

    modifier isOperator() {
        require(operators.contains(msg.sender), "You do not have rights");
        _;
    }

    event OperatorAdded(address);
    event OperatorRemoved(address);

    function addOperator(address _operator) external virtual;

    function removeOperator(address _operator) external virtual;

    function _addOperator(address _operator) internal {
        require(_operator != address(0), "Address should not be empty");
        require(!operators.contains(_operator), "Already added");
        if (!operators.contains(_operator)) {
            operators.add(_operator);
            emit OperatorAdded(_operator);
        }
    }

    function _removeOperator(address _operator) internal {
        require(operators.contains(_operator), "Not exist");
        if (operators.contains(_operator)) {
            operators.remove(_operator);
            emit OperatorRemoved(_operator);
        }
    }

    function getOperators() external view returns (address[] memory) {
        return operators.values();
    }
}