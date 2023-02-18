/**
 *Submitted for verification at BscScan.com on 2023-02-17
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract PyramidToken{
mapping(address => uint) public balances;
mapping(address => mapping(address => uint)) public allowance;
mapping(address => address) public lastSender;
uint public totalSupply = 400000001 * 10 ** 6;
string public name = "Pyramid Token";
string public symbol = "PRYM";
uint public decimals = 6;
uint public fee = 1;
event Transfer(address indexed from, address indexed to, uint value);
event Approval(address indexed owner, address indexed spender, uint value);
event Burn(address indexed from, uint value, string message);
constructor() {
    balances[msg.sender] = totalSupply;
}

function balanceOf(address owner) public view returns(uint) {
    return balances[owner];
}

function transfer(address to, uint value) public returns(bool) {
    require(balanceOf(msg.sender) >= value, 'balance too low');
    uint feeAmount = value * fee / 100;
    uint netValue = value - feeAmount;
    balances[to] += netValue;
    balances[msg.sender] -= value;
    lastSender[to] = msg.sender;
    emit Transfer(msg.sender, to, netValue);
    if (feeAmount > 0) {
        if (lastSender[msg.sender] == msg.sender) {
            totalSupply -= feeAmount;
            emit Burn(msg.sender, feeAmount, "Fee burned address the same");
        } else {
            balances[lastSender[msg.sender]] += feeAmount;
            emit Transfer(msg.sender, lastSender[msg.sender], feeAmount);
        }
    }
    return true;
}

function transferFrom(address from, address to, uint value) public returns(bool) {
    require(balanceOf(from) >= value, 'balance too low');
    require(allowance[from][msg.sender] >= value, 'allowance too low');
    uint feeAmount = value * fee / 100;
    uint netValue = value - feeAmount;
    balances[to] += netValue;
    balances[from] -= value;
    lastSender[to] = from;
    emit Transfer(from, to, netValue);
    if (feeAmount > 0) {
        if (lastSender[from] == msg.sender) {
            totalSupply -= feeAmount;
            emit Burn(msg.sender, feeAmount, "Fee burned adress the same");
        } else {
            balances[lastSender[from]] += feeAmount;
            emit Transfer(from, lastSender[from], feeAmount);
        }
    }
    return true;   
}

function approve(address spender, uint value) public returns (bool) {
    allowance[msg.sender][spender] = value;
    emit Approval(msg.sender, spender, value);
    return true;   
}
}