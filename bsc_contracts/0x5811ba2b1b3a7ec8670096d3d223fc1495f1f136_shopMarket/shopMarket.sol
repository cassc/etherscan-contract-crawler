/**
 *Submitted for verification at BscScan.com on 2023-05-03
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

contract shopMarket {
    address payable public owner;
    bool public paused;
    event ShopPurchased(address buyer, address tokenAddress, uint256 amount, uint256 itemId);
    event Withdraw(address recipient, uint256 amount);

    constructor() {
        owner = payable(msg.sender);
        paused = false;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can perform this action");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "The contract is paused");
        _;
    }

    function buyItem(uint256 itemId, address tokenAddress, uint256 amount) external whenNotPaused {
        require(amount > 0, "Sent value must be greater than 0");
        IERC20 token = IERC20(tokenAddress);
        require(token.balanceOf(msg.sender) >= amount, "Insufficient balance");
        require(token.allowance(msg.sender, address(this)) >= amount, "Must approve the contract first");

        token.transferFrom(msg.sender, address(this), amount);
        emit ShopPurchased(msg.sender, tokenAddress, amount, itemId);
    }

    function withdraw(address tokenAddress, uint256 amount) external onlyOwner {
        require(amount > 0, "Invalid amount");
        IERC20 token = IERC20(tokenAddress);
        require(token.balanceOf(address(this)) >= amount, "Insufficient balance");

        token.transfer(owner, amount);
        emit Withdraw(owner, amount);
    }

    function pause() public onlyOwner {
        paused = true;
    }

    function unpause() public onlyOwner {
        paused = false;
    }
}