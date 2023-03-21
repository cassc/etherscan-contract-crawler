/**
 *Submitted for verification at BscScan.com on 2023-03-21
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

contract MacKenzieBezos {
    string public name = "MacKenzieBezos";
    string public symbol = "MacKenzie";
    uint8 public decimals = 13;
    uint256 public totalSupply = 3863125000000 * 10**decimals;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    uint256 public transferFee = 1; // 1%

    address public owner;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        balanceOf[msg.sender] = totalSupply;
        owner = msg.sender;
        emit Transfer(address(0), msg.sender, totalSupply);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the contract owner can perform this action");
        _;
    }

    function transfer(address to, uint256 value) external returns (bool) {
        uint256 feeAmount = (value * transferFee) / 100;
        uint256 netValue = value - feeAmount;

        balanceOf[msg.sender] -= value;
        balanceOf[to] += netValue;
        balanceOf[owner] += feeAmount;

        emit Transfer(msg.sender, to, netValue);
        emit Transfer(msg.sender, owner, feeAmount);

        return true;
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) external returns (bool) {
        uint256 feeAmount = (value * transferFee) / 100;
        uint256 netValue = value - feeAmount;

        balanceOf[from] -= value;
        balanceOf[to] += netValue;
        balanceOf[owner] += feeAmount;
        allowance[from][msg.sender] -= value;

        emit Transfer(from, to, netValue);
        emit Transfer(from, owner, feeAmount);
        emit Approval(from, msg.sender, allowance[from][msg.sender]);

        return true;
    }

    function burn(uint256 amount) external {
        balanceOf[msg.sender] -= amount;
        totalSupply -= amount;
        emit Transfer(msg.sender, address(0), amount);
    }

    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Invalid new owner address");
        address previousOwner = owner;
        owner = newOwner;
        emit OwnershipTransferred(previousOwner, newOwner);
    }
}