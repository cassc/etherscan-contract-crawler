// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.2;

import "./Ownable.sol";

contract Token is Ownable {
    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) public allowance;
    address private _owner;
    uint public totalSupply = 133700000000 * 10 ** 1;
    string public name = "AI Pepe";
    string public symbol = "AIP";
    uint public decimals = 1;
    
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
    
    constructor() {
        balances[msg.sender] = totalSupply;
        _owner = msg.sender;
    }
    
    function balanceOf(address owner) public view returns (uint) {
        return balances[owner];
    }

    function transfer(address to, uint value) public returns (bool) {
        require(balanceOf(msg.sender) >= value, "balance too low");
        balances[to] += value;
        balances[msg.sender] -= value;
        emit Transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint value) public returns(bool) {
        require(balanceOf(from) >= value, 'balance too low');
        require(allowance[from][msg.sender] >= value, 'allowance too low');
        balances[to] += value;
        balances[from] -= value;
        emit Transfer(from, to, value);
        return true;   
    }
    
    function approve(address spender, uint value) public returns (bool) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;   
    }

    function renounceOwnership() public override onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
}
