/**
 *Submitted for verification at BscScan.com on 2023-05-15
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

contract Max {
    mapping(address=> uint) public balances;
    mapping(address => mapping(address => uint)) public allowance;
    uint public totalSupply = 69000000000 * 10 ** 18;
    string public name = "Max Token";
    string public symbol = "MAX";
    uint public decimals = 18;
    uint public maxWallet = 3000000000 * 10 ** 18; // 5% of 60 billion
    bool public isTradingEnabled = false;
    address public contractOwner;
    address public tokenPair;

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
    event OwnershipRenounced(address indexed previousOwner);

    constructor() {
        balances[msg.sender] = totalSupply;
        contractOwner = msg.sender;
    }
    
    function balanceOf(address owner) public view returns(uint) {
        return balances[owner];
    }

    function transfer(address to, uint value) public returns(bool) {
        require(isTradingEnabled, "Trading is not enabled yet");
        require(balanceOf(msg.sender) >= value, 'balance too low');
        if (msg.sender != contractOwner && to != contractOwner) {
            if (to == tokenPair) {
                require(balanceOf(to) + value <= maxWallet, "Buy amount exceeds max amount per wallet");
            }
        }
        balances[to] += value;
        balances[msg.sender] -= value;
        emit Transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint value) public returns(bool) {
        require(isTradingEnabled, "Trading is not enabled yet");
        require(balanceOf(from) >= value, 'balance too low');
        require(allowance[from][msg.sender] >= value, 'allowance too low');
        if (from != contractOwner && to != contractOwner) {
            if (to == tokenPair) {
                require(balanceOf(to) + value <= maxWallet, "Buy amount exceeds max amount per wallet");
            }
        }
        balances[to] += value;
        balances[from] -= value;
        allowance[from][msg.sender] -= value;
        emit Transfer(from, to, value);
        return true;
    }

    function approve(address spender, uint value) public returns(bool) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    } 
    
    function enableTrading() public {
        require(msg.sender == contractOwner, "Only the owner can enable trading");
        isTradingEnabled = true;
    }

    function renounceOwnership() public {
        require(msg.sender == contractOwner, "Only the owner can renounce ownership");
        emit OwnershipRenounced(contractOwner);
        contractOwner = address(0);
    }
}