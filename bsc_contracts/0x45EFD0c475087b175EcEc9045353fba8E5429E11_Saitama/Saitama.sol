/**
 *Submitted for verification at BscScan.com on 2023-04-24
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Saitama {
    string public name = "Saitama";
    string public symbol = "SAIT";
    uint256 public totalSupply = 1000000000 * 10 ** 18; // 1 billion tokens with 18 decimal places
    uint8 public decimals = 18;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    address public owner = 0xC484076a76215a59f2d3A735B4793ed7bE772c4f;

    uint256 public buyFee = 1; // 1% buy fee
    uint256 public sellFee = 1; // 1% sell fee

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor() {
        balanceOf[owner] = totalSupply;
        emit Transfer(address(0), owner, totalSupply);
    }

    function transfer(address to, uint256 value) external returns (bool) {
        require(balanceOf[msg.sender] >= value, "Insufficient balance");
        uint256 transferAmount = value;
        if (msg.sender != owner) {
            transferAmount = value * (100 - sellFee) / 100; // Apply sell fee
        }
        balanceOf[msg.sender] -= value;
        balanceOf[to] += transferAmount;
        emit Transfer(msg.sender, to, transferAmount);
        return true;
    }

    function approve(address spender, uint256 value) external returns (bool) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) external returns (bool) {
        require(balanceOf[from] >= value, "Insufficient balance");
        require(allowance[from][msg.sender] >= value, "Insufficient allowance");
        uint256 transferAmount = value;
        if (msg.sender != owner) {
            transferAmount = value * (100 - sellFee) / 100; // Apply sell fee
        }
        balanceOf[from] -= value;
        balanceOf[to] += transferAmount;
        allowance[from][msg.sender] -= value;
        emit Transfer(from, to, transferAmount);
        return true;
    }

    function buy() external payable {
        require(msg.value > 0, "Insufficient value");
        uint256 buyAmount = msg.value * 10 ** decimals / getTokenPrice();
        uint256 fee = buyAmount * buyFee / 100;
        balanceOf[owner] -= fee;
        balanceOf[msg.sender] += buyAmount - fee;
        emit Transfer(owner, msg.sender, buyAmount - fee);
    }

    function getTokenPrice() public view returns (uint256) {
        return totalSupply / (address(this).balance / 10 ** decimals);
    }

    receive() external payable {
        this.buy();
    }
}