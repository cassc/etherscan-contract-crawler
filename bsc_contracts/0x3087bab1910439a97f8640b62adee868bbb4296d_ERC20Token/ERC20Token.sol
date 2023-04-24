/**
 *Submitted for verification at BscScan.com on 2023-04-20
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.7;

contract ERC20Token {
    string public constant name = "AiMEME";
    string public constant symbol = "MEME";
    uint8 public constant decimals = 18;

    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    event Transfer(address indexed from, address indexed to, uint tokens);

    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;
    uint256 totalSupply_;

    using SafeMath for uint256;

    address public constant taxRevenueAddress = 0x4Bf8C13826D5bB902a4b3dC1aE6fF856E803c937;
    uint256 public constant buyTax = 7;
    uint256 public constant sellTax = 9;

    constructor(uint256 total) {
        totalSupply_ = total;
        balances[msg.sender] = totalSupply_;
    }

    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }

    function balanceOf(address tokenOwner) public view returns (uint256) {
        return balances[tokenOwner];
    }

    function transfer(address receiver, uint256 numTokens) public returns (bool) {
        uint256 taxAmount = calculateTax(msg.sender, numTokens);
        require(numTokens + taxAmount <= balances[msg.sender], "Insufficient balance.");
        balances[msg.sender] -= numTokens + taxAmount;
        balances[receiver] += numTokens;
        balances[taxRevenueAddress] += taxAmount;
        emit Transfer(msg.sender, receiver, numTokens);
        return true;
    }

    function approve(address delegate, uint256 numTokens) public returns (bool) {
        allowed[msg.sender][delegate] = numTokens;
        emit Approval(msg.sender, delegate, numTokens);
        return true;
    }

    function allowance(address owner, address delegate) public view returns (uint256) {
        return allowed[owner][delegate];
    }

    function transferFrom(address owner, address buyer, uint256 numTokens) public returns (bool) {
        uint256 taxAmount = calculateTax(owner, numTokens);
        require(numTokens + taxAmount <= balances[owner], "Insufficient balance.");
        require(numTokens <= allowed[owner][msg.sender], "Insufficient allowance.");
        balances[owner] -= numTokens + taxAmount;
        allowed[owner][msg.sender] -= numTokens;
        balances[buyer] += numTokens;
        balances[taxRevenueAddress] += taxAmount;
        emit Transfer(owner, buyer, numTokens);
        return true;
    }

    function calculateTax(address account, uint256 amount) private view returns (uint256) {
        uint256 taxAmount = 0;
        if (account != msg.sender) {
            if (tx.origin == msg.sender) {
                // Buy Transaction
                taxAmount = (amount * buyTax) / 100;
            } else {
                // Sell Transaction
                taxAmount = (amount * sellTax) / 100;
            }
        }
        return taxAmount;
    }
}

library SafeMath {
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}