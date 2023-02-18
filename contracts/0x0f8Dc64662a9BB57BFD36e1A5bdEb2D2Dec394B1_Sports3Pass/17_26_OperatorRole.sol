// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

contract OperatorRole {
    address private _operator;

    event OperatorTransferred(
        address indexed previousOperator,
        address indexed newOperator
    );

    constructor() {
        _transferOperator(msg.sender);
    }

    modifier onlyOperator() {
        require(operator() == msg.sender, "caller is not the operator");
        _;
    }

    function operator() public view virtual returns (address) {
        return _operator;
    }

    function _transferOperator(address newOperator) internal virtual {
        require(newOperator != address(0), "invalid address");
        require(newOperator != _operator, "not change operator");
        address oldOperator = _operator;
        _operator = newOperator;
        emit OperatorTransferred(oldOperator, _operator);
    }
}