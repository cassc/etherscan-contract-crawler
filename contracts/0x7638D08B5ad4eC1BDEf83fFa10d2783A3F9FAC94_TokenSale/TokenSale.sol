/**
 *Submitted for verification at Etherscan.io on 2023-05-20
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
}

contract TokenSale {
    address public tokenAddress;
    address public owner;
    uint256 public tokenPrice = 0.00000065 ether;
    bool private reentrancyLock; 
    event TokensPurchased(address buyer, uint256 amount);
    event TokenPriceChanged(uint256 newPrice);

    constructor(address _tokenAddress) {
        tokenAddress = _tokenAddress;
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the contract owner can perform this action");
        _;
    }

    modifier nonReentrant() {
        require(!reentrancyLock, "Reentrant call");
        reentrancyLock = true;
        _;
        reentrancyLock = false;
    }

    function buyTokens(uint256 _amount) external payable nonReentrant {
        require(msg.value == (_amount * tokenPrice), "Incorrect amount of Ether sent");

        IERC20 token = IERC20(tokenAddress);
        require(token.transfer(msg.sender, _amount), "Token transfer failed");

        emit TokensPurchased(msg.sender, _amount);
    }

    function setTokenPrice(uint256 _newPrice) external onlyOwner nonReentrant {
        require(_newPrice > 0, "Price must be greater than zero");
        tokenPrice = _newPrice;

        emit TokenPriceChanged(_newPrice);
    }

    function withdrawEther() external onlyOwner nonReentrant {
        uint256 contractBalance = address(this).balance;
        require(contractBalance > 0, "No Ether to withdraw");

        (bool success, ) = owner.call{value: contractBalance}("");
        require(success, "Failed to withdraw Ether");
    }

    function withdrawTokens(address _token, uint256 _amount) external onlyOwner nonReentrant {
        IERC20 token = IERC20(_token);
        require(token.transfer(owner, _amount), "Token transfer failed");
    }
}