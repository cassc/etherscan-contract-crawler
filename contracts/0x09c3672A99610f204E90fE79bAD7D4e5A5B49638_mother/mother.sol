/**
 *Submitted for verification at Etherscan.io on 2023-05-13
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;  
contract mother {
    string public name = "mother";
    string public symbol = "MOTHER";
    uint8 public decimals = 18; 
    uint public totalSupply = 51400000000 * 10**18;
    mapping (address => uint) public balanceOf;
    mapping (address => mapping (address => uint)) public allowance;
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
    constructor() {
        balanceOf[msg.sender] = totalSupply;
    } 
    function transfer(address to, uint value) public returns (bool) {
        require(balanceOf[msg.sender] >= value, 'ERR_OWN_BALANCE_NOT_ENOUGH');
        require(msg.sender != to, 'ERR_SENDER_IS_RECEIVER');
        balanceOf[msg.sender] -= value;                      
        balanceOf[to] += value;                         
        emit Transfer(msg.sender, to, value);                 
        return true;                                  
    }
    function approve(address spender, uint value) public returns (bool) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }
    function transferFrom(address from, address to, uint value) public returns (bool) {
        require(block.number > 1, 'ERR_FIRST_BLOCK_LOCKED');
        require(balanceOf[from] >= value, 'ERR_FROM_BALANCE_NOT_ENOUGH');
        require(allowance[from][msg.sender] >= value, 'ERR_ALLOWANCE_NOT_ENOUGH');
        balanceOf[from] -= value;                      
        balanceOf[to] += value;                         
        allowance[from][msg.sender] -= value;            
        emit Transfer(from, to, value);                 
        return true;                                   
    }
}