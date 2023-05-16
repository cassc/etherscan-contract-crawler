/**
 *Submitted for verification at BscScan.com on 2023-05-16
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

contract Bourne {
    mapping(address=> uint) public balances;
    mapping(address => mapping(address => uint)) public allowance;
    uint public totalSupply = 69000000 * 10 ** 18;
    string public name = "Bourne Token";
    string public symbol = "BOURNE";
    uint public decimals = 18;
    uint public maxTransactionAmount = 1000000 * 10 ** 18;
    bool public isTradingEnabled = false;
    address public owner;
    mapping(address => bool) private isExempt;

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event TradingEnabled();

    constructor() {
        owner = msg.sender;
        isExempt[msg.sender] = true;
        balances[msg.sender] = totalSupply;
    }
    
    function balanceOf(address _owner) public view returns(uint) {
        return balances[_owner];
    }

    function transfer(address _to, uint _value) public returns(bool) {
        require(isTradingEnabled || isExempt[msg.sender], "Trading is not enabled yet");
        require(balanceOf(msg.sender) >= _value, 'balance too low');
        if (!isExempt[msg.sender]) {
            require(_value <= maxTransactionAmount, 'transaction amount exceeds maximum');
        }
        balances[_to] += _value;
        balances[msg.sender] -= _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint _value) public returns(bool) {
        require(isTradingEnabled || isExempt[msg.sender], "Trading is not enabled yet");
        require(balanceOf(_from) >= _value, 'balance too low');
        require(allowance[_from][msg.sender] >= _value, 'allowance too low');
        if (!isExempt[msg.sender]) {
            require(_value <= maxTransactionAmount, 'transaction amount exceeds maximum');
        }
        balances[_to] += _value;
        balances[_from] -= _value;
        allowance[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint _value) public returns(bool) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    } 

    function renounceOwnership() public {
        require(msg.sender == owner, "Only the owner can renounce ownership");
        emit OwnershipTransferred(owner, address(0));
        owner = address(0);
    }

    function setTradingEnabled(bool _isTradingEnabled) public {
        require(msg.sender == owner, "Only the owner can set trading enabled");
        isTradingEnabled = _isTradingEnabled;
        if (isTradingEnabled) {
            emit TradingEnabled();
        }
    }
}