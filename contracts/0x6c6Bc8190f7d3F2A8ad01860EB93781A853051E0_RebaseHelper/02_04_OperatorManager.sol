// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.4;

import "./_external/Ownable.sol";

contract OperatorManager is Ownable {
    mapping(address => bool) private operators;

    modifier onlyOperator() {
        require(operators[msg.sender], "Only operators can execute this function.");
        _;
    }

    constructor() {
        initialize(msg.sender);
    }

    function setOperators(address[] calldata _operators, bool _isOperator) external onlyOwner {
        for (uint256 index = 0; index < _operators.length; index++) {
            operators[_operators[index]] = _isOperator;
        }
    }

    function addOperator(address _operator) external onlyOwner {
        operators[_operator] = true;
    }

    function removeOperator(address _operator) external onlyOwner {
        operators[_operator] = false;
    }

    function isOperator(address _operator) external view returns (bool) {
        return operators[_operator];
    }
}