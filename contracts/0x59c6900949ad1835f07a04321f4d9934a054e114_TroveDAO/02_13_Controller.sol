// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.14;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Controller is Ownable {
    mapping(address => bool) operator;
    event operatorCreated(address _operator, bool _whiteList);

    modifier onlyOperator() {
        require(operator[msg.sender], "Only-operator");
        _;
    }

    constructor() public {
        operator[msg.sender] = true;
    }

    function setOperator(address _operator, bool _whiteList) public onlyOwner {
        operator[_operator] = _whiteList;
        emit operatorCreated(_operator, _whiteList);
    }
}