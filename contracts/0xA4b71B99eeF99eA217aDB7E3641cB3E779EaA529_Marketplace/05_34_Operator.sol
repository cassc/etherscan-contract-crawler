// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Operator is Ownable {
    /**
     * @dev Emits an event when adding a new operator
     *
     * @param operator  address of new operator
     */
    event NewOperator(address indexed operator);

    /**
     * @dev Emits an event when an operator removed
     *
     * @param operator  address of removed operator
     */
    event OperatorRemoved(address indexed operator);

    mapping(address => bool) private operators;

    /**
     * @dev check that an address exists in the `operators` map
     */
    function isOperator(address operator) public view returns (bool) {
        return operators[operator];
    }

    /**
     * @dev adds a new operator
     *
     * @param operator  address of operator
     */
    function addOperator(address operator) public onlyOwner {
        require(!operators[operator], "OP: address already in list");
        operators[operator] = true;

        emit NewOperator(operator);
    }

    /**
     * @dev remove an operator
     *
     * @param operator  address of operator
     */
    function removeOperator(address operator) external onlyOwner {
        delete operators[operator];

        emit OperatorRemoved(operator);
    }
}