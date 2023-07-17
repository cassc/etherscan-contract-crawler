// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface ERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract TokenExchange {
    address public tokenAddress;
    address public owner;

    modifier onlyOwner() {
        require(msg.sender == owner, "Only contract owner can call this function");
        _;
    }

    constructor(address _tokenAddress) {
        tokenAddress = _tokenAddress;
        owner = msg.sender;
    }

    function buyTokens(uint256 amount) external payable {
        ERC20 token = ERC20(tokenAddress);

        require(token.transferFrom(msg.sender, address(this), amount), "Token transfer failed");

        // Perform your logic for selling the tokens here
        // For simplicity, let's assume the token is being sold at a fixed rate of 1 Ether per token
        uint256 ethAmount = amount * 1 ether;
        require(msg.value >= ethAmount, "Insufficient Ether provided");

        // Transfer tokens to the buyer
        require(token.transfer(msg.sender, amount), "Token transfer to buyer failed");

        // Refund any excess Ether to the buyer
        if (msg.value > ethAmount) {
            payable(msg.sender).transfer(msg.value - ethAmount);
        }
    }

    function sellTokens(uint256 amount) external {
        ERC20 token = ERC20(tokenAddress);

        require(token.transferFrom(msg.sender, address(this), amount), "Token transfer failed");

        // Perform your logic for buying the tokens here
        // For simplicity, let's assume the token is being bought at a fixed rate of 1 Ether per token
        uint256 ethAmount = amount * 1 ether;

        // Transfer Ether to the seller
        payable(msg.sender).transfer(ethAmount);

        // Transfer remaining tokens back to the seller
        require(token.transfer(msg.sender, token.balanceOf(address(this))), "Token transfer to seller failed");
    }

    function withdrawTokens(uint256 amount) external onlyOwner {
        ERC20 token = ERC20(tokenAddress);
        require(token.transfer(msg.sender, amount), "Token transfer failed");
    }

    function withdrawEther() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
}