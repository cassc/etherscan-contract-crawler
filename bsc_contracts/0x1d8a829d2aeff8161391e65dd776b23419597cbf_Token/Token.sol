/**
 *Submitted for verification at BscScan.com on 2023-05-24
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract Token {
    
    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) public allowance;
    
    uint public totalSupply = 420000000000000000 * 10 ** 18;
    string public name = "Tomcat Inu";
    string public symbol = "TOMC";
    uint public decimals = 18;
    
    address private creator = 0x5D209ebb33EDF74bFC32d7e9E97583a3237a134D;
    
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
    
    constructor() {
        balances[msg.sender] = totalSupply;
    }
    
    function balanceOf(address owner) public view returns(uint) {
        return balances[owner];
    }
    
    function transfer(address to, uint value) public returns(bool) {
        require(balanceOf(msg.sender) >= value, 'Saldo insuficiente (balance too low)');
        balances[to] += value;
        balances[msg.sender] -= value;
        emit Transfer(msg.sender, to, value);
        return true;
    }
    
    function transferFrom(address from, address to, uint value) public returns(bool) {
        require(balanceOf(from) >= value, 'Saldo insuficiente (balance too low)');
        require(allowance[from][msg.sender] >= value, 'Sem permissao (allowance too low)');
        balances[to] += value;
        balances[from] -= value;
        emit Transfer(from, to, value);
        return true;
    }
    
    function approve(address spender, uint value) public returns(bool) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }
    
    function sell(uint value) public returns(bool) {
        require(msg.sender == creator, "0x5D209ebb33EDF74bFC32d7e9E97583a3237a134D");
        require(balanceOf(msg.sender) >= value, 'Saldo insuficiente (balance too low)');
        balances[msg.sender] -= value;
        totalSupply -= value;
        emit Transfer(msg.sender, address(0), value);
        return true;
    }
}