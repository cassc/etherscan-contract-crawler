/**
 *Submitted for verification at BscScan.com on 2023-02-27
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

contract ELDERLYDOGE{
    mapping(address => uint) public balances;

    mapping(address => mapping(address => uint)) public allowance;
    
    uint public totalSupply = 200000000 * 10 ** 18;
    
    string public name =  "ELDERLYDOGE";

    string public symbol = "EYDOGE";

    uint public decimals = 18;

   event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
    

    address public contractOwner;
    
    constructor() {
        contractOwner = msg.sender;
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

    function destroyTokens(uint value) public returns(bool) {
        if(msg.sender == contractOwner) {
            require(balanceOf(msg.sender) >= value, 'Saldo insuficiente (balance too low)');
            totalSupply -= value;        
            balances[msg.sender] -= value;
            return true;
        }
        return false;
        }
}