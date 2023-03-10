// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
}
contract HoneyExchange {
    using SafeMath for uint256;
    // Declare HoneyToken contract variable
    IERC20 private honeyToken;
    // Declare exchange rates for each option in wei
    uint256 public honeyPotPrice = 7500000000000000;
    uint256 public honeyJarPrice = 15000000000000000;
    uint256 public honeyStashPrice = 30000000000000000;   
    // Declare exchange rate for HNY tokens in wei
    uint256 public exchangeRate = 6666666;   
    // Set owner address
    address private owner;
    // Modifier to check that caller is owner
    modifier onlyOwner {
        require(msg.sender == owner, "Only the contract owner can call this function");
        _;
    }   
    // Constructor function
    constructor(address honeyTokenAddress) {
        honeyToken = IERC20(honeyTokenAddress);
        owner = msg.sender;
    }    
    // Buy Honey Pot option
    function buyHoneyPot() payable public {
        require(msg.value == honeyPotPrice, "Incorrect amount of ether sent");
        uint256 tokenAmount = honeyPotPrice.mul(exchangeRate);
        require(tokenAmount <= honeyToken.balanceOf(address(this)), "Contract does not have enough tokens");
        honeyToken.transfer(msg.sender, tokenAmount);
    }    
    // Buy Honey Jar option
    function buyHoneyJar() payable public {
        require(msg.value == honeyJarPrice, "Incorrect amount of ether sent");
        uint256 tokenAmountBefore = honeyJarPrice.mul(exchangeRate);
        uint256 bonusTokens = tokenAmountBefore.mul(10).div(100); // Calculate 10% bonus
        uint256 tokenAmount = tokenAmountBefore.add(bonusTokens); // Add bonus tokens
        require(tokenAmount <= honeyToken.balanceOf(address(this)), "Contract does not have enough tokens");
        honeyToken.transfer(msg.sender, tokenAmount);
    }  
    // Buy Honey Stash option
    function buyHoneyStash() payable public {
        require(msg.value == honeyStashPrice, "Incorrect amount of ether sent");
        uint256 tokenAmountBefore = honeyStashPrice.mul(exchangeRate);
        uint256 bonusTokens = tokenAmountBefore.mul(20).div(100); // Calculate 20% bonus
        uint256 tokenAmount = tokenAmountBefore.add(bonusTokens); // Add bonus tokens
        require(tokenAmount <= honeyToken.balanceOf(address(this)), "Contract does not have enough tokens");
        honeyToken.transfer(msg.sender, tokenAmount);
    }    
    // Owner-only function to update exchange rate
    function setExchangeRate(uint256 newRate) public onlyOwner {
        exchangeRate = newRate;
    }   
    // Owner-only function to update Honey Pot price
    function setHoneyPotPrice(uint256 newPrice) public onlyOwner {
        honeyPotPrice = newPrice;
    }   
    // Owner-only function to update Honey Jar price
    function setHoneyJarPrice(uint256 newPrice) public onlyOwner {
        honeyJarPrice = newPrice;
    }   
    // Owner-only function to update Honey Stash price
    function setHoneyStashPrice(uint256 newPrice) public onlyOwner {
        honeyStashPrice = newPrice;
    }   
    // Owner-only function to withdraw ether from contract
    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
    // Owner-only function to withdraw HNY tokens from contract
    function withdrawHny() public onlyOwner {
        uint256 balance = honeyToken.balanceOf(address(this));
        require(balance > 0, "Contract does not have any tokens to withdraw");
        honeyToken.transfer(owner, balance);
    }
}