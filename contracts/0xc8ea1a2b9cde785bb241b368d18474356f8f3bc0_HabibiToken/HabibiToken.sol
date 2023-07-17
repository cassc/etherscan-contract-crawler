/**
 *Submitted for verification at Etherscan.io on 2023-06-27
*/

/*
      ___           ___           ___                       ___                                ___           ___           ___           ___           ___     
     /\__\         /\  \         /\  \          ___        /\  \          ___                 /\  \         /\  \         /\__\         /\  \         /\__\    
    /:/  /        /::\  \       /::\  \        /\  \      /::\  \        /\  \                \:\  \       /::\  \       /:/  /        /::\  \       /::|  |   
   /:/__/        /:/\:\  \     /:/\:\  \       \:\  \    /:/\:\  \       \:\  \                \:\  \     /:/\:\  \     /:/__/        /:/\:\  \     /:|:|  |   
  /::\  \ ___   /::\~\:\  \   /::\~\:\__\      /::\__\  /::\~\:\__\      /::\__\               /::\  \   /:/  \:\  \   /::\__\____   /::\~\:\  \   /:/|:|  |__ 
 /:/\:\  /\__\ /:/\:\ \:\__\ /:/\:\ \:|__|  __/:/\/__/ /:/\:\ \:|__|  __/:/\/__/              /:/\:\__\ /:/__/ \:\__\ /:/\:::::\__\ /:/\:\ \:\__\ /:/ |:| /\__\
 \/__\:\/:/  / \/__\:\/:/  / \:\~\:\/:/  / /\/:/  /    \:\~\:\/:/  / /\/:/  /                /:/  \/__/ \:\  \ /:/  / \/_|:|~~|~    \:\~\:\ \/__/ \/__|:|/:/  /
      \::/  /       \::/  /   \:\ \::/  /  \::/__/      \:\ \::/  /  \::/__/                /:/  /       \:\  /:/  /     |:|  |      \:\ \:\__\       |:/:/  / 
      /:/  /        /:/  /     \:\/:/  /    \:\__\       \:\/:/  /    \:\__\                \/__/         \:\/:/  /      |:|  |       \:\ \/__/       |::/  /  
     /:/  /        /:/  /       \::/__/      \/__/        \::/__/      \/__/                               \::/  /       |:|  |        \:\__\         /:/  /   
     \/__/         \/__/         ~~                        ~~                                               \/__/         \|__|         \/__/         \/__/    
*/

// SPDX-License-Identifier: MIT LICENSE
    pragma solidity ^0.8.13;

contract HabibiToken {

    mapping (address => uint) public balances;

    mapping (address => mapping (address => uint)) public allowance;
    string public name = "Habibi ";

    string public symbol = "HABIBI";

    uint public decimals = 18;

    uint public tokensIActuallyWant = 1000000000;
    uint public totalTokenSupply = tokensIActuallyWant * 10 ** decimals;


    constructor(){
        balances[msg.sender] = totalTokenSupply;
    }

    function balanceOf(address owner) public view returns (uint){
        return balances[owner];
    }

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);


    function transfer(address to, uint value) public returns(bool){

        require (balanceOf(msg.sender) >= value, 'Your balance is too low');

        balances[to] = balances[to] + value;
        balances[msg.sender] =  balances[msg.sender] - value;

        emit Transfer(msg.sender, to, value);
        return true;
    }


    function transferFrom(address from, address to, uint value) public returns(bool){

        require(balanceOf(from) >= value, 'Your balance is too low');

        require(allowance[from][msg.sender] >= value, 'You can not spend up to this amount');

        balances[to] += value;

        balances[from] -= value;

        emit Transfer(from, to, value);

        return true;
    }


    function approve(address spender, uint value) public returns(bool){
        allowance[msg.sender][spender] = value; 

        emit Approval(msg.sender, spender, value);

        return true;
    }   
}