// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "Ownable.sol";

contract Operator is Ownable {

    mapping(address => bool) public mOperators;


    constructor () {
        setOperator(owner(), true);
    }

    modifier onlyOperator() {
        require(mOperators[msg.sender] == true, "Caller is not the operator");
        _;
    }

    function setOperator(address _operator, bool _status) public onlyOwner {
        mOperators[_operator] = _status;
    }

    function getOperator(address _operator) external view returns (bool) {
        return mOperators[_operator];
    }
}