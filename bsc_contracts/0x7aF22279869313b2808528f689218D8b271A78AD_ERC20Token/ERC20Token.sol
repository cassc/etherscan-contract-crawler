/**
 *Submitted for verification at BscScan.com on 2023-04-20
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.7;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract ERC20Token is IERC20 {
    using SafeMath for uint256;

    string public constant name = "AiMEME";
    string public constant symbol = "MEME";
    uint8 public constant decimals = 18;

    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;
    uint256 totalSupply_;

    address public constant taxRevenueAddress = 0x4Bf8C13826D5bB902a4b3dC1aE6fF856E803c937;
    uint256 public constant buyTax = 7;
    uint256 public constant sellTax = 9;

    constructor() {
        totalSupply_ = 1000000000 * (10 ** uint256(decimals));
        balances[msg.sender] = totalSupply_;
    }

    function totalSupply() external view override returns (uint256) {
        return totalSupply_;
    }

    function balanceOf(address tokenOwner) external view override returns (uint256) {
        return balances[tokenOwner];
    }

    function transfer(address receiver, uint256 numTokens) external override returns (bool) {
        uint256 taxAmount = calculateTax(msg.sender, numTokens);
        require(numTokens.add(taxAmount) <= balances[msg.sender], "Insufficient balance.");
        balances[msg.sender] = balances[msg.sender].sub(numTokens.add(taxAmount));
        balances[receiver] = balances[receiver].add(numTokens);
        balances[taxRevenueAddress] = balances[taxRevenueAddress].add(taxAmount);
        emit Transfer(msg.sender, receiver, numTokens);
        return true;
    }

    function approve(address delegate, uint256 numTokens) external override returns (bool) {
        allowed[msg.sender][delegate] = numTokens;
        emit Approval(msg.sender, delegate, numTokens);
        return true;
    }

    function allowance(address owner, address delegate) external view override returns (uint256) {
        return allowed[owner][delegate];
    }

    function transferFrom(address owner, address buyer, uint256 numTokens) external override returns (bool) {
        uint256 taxAmount = calculateTax(owner, numTokens);
        require(numTokens.add(taxAmount) <= balances[owner], "Insufficient balance.");
        require(numTokens <= allowed[owner][msg.sender], "Insufficient allowance.");
        balances[owner] = balances[owner].sub(numTokens.add(taxAmount));
        allowed[owner][msg.sender] = allowed[owner][msg.sender].sub(numTokens);
        balances[buyer] = balances[buyer].add(numTokens);
        balances[taxRevenueAddress] = balances[taxRevenueAddress].add(taxAmount);
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