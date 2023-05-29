/**
 *Submitted for verification at Etherscan.io on 2023-05-26
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SugarBrazilCoin {
    mapping(address => uint) public balanceOf;
    mapping(address => mapping(address => uint)) public allowance;

    uint public totalSupply = 1000000000000 * 10 ** 18;
    string public name = "SugarBrazilCoin";
    string public symbol = "SBC";
    uint public decimals = 18;

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
    event Burn(address indexed from, uint value);

    constructor() {
        balanceOf[msg.sender] = totalSupply;
    }

    function transfer(address to, uint value) public returns(bool) {
        require(balanceOf[msg.sender] >= value, 'Insufficient balance');
        balanceOf[to] += value;
        balanceOf[msg.sender] -= value;
        emit Transfer(msg.sender, to, value);
        return true;
    }

    function approve(address spender, uint value) public returns(bool) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function transferFrom(address from, address to, uint value) public returns(bool) {
        require(balanceOf[from] >= value, 'Insufficient balance');
        require(allowance[from][msg.sender] >= value, 'Not allowed to transfer');
        balanceOf[to] += value;
        balanceOf[from] -= value;
        allowance[from][msg.sender] -= value;
        emit Transfer(from, to, value);
        return true;
    }

    function burn(uint value) public returns(bool) {
        require(balanceOf[msg.sender] >= value, 'Insufficient balance');
        balanceOf[msg.sender] -= value;
        totalSupply -= value;
        emit Burn(msg.sender, value);
        return true;
    }
}