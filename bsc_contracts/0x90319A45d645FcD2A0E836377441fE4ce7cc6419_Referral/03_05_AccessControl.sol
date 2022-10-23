// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract AccessControl is Ownable{
  
    mapping(address => bool) private _operators;

    event SetOperator(address indexed add, bool value);

    function setOperator(address _operator, bool _v) external onlyOwner {
        _operators[_operator] = _v;
        emit SetOperator(_operator, _v);
    }

    function isOperator(address _address) external view returns(bool){
        return  _operators[_address];
    }

    modifier onlyOperator() {
        require(_operators[msg.sender]);
        _;
    }
}