/**
 *Submitted for verification at BscScan.com on 2023-05-21
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract Presale {
    address public owner;
    address public tokenAddress;
    uint public rate;
    uint public sold;
    uint public minPurchase = 100000000000000000; // 0.1 BNB
    uint public maxPurchase = 10000000000000000000; // 10 BNB
    
    event Bought(uint amount);

    constructor(address _tokenAddress, uint _rate) {
        owner = msg.sender;
        tokenAddress = _tokenAddress;
        rate = _rate;
    }

    function buy() payable external {
        require(msg.value >= minPurchase, "Minimum purchase is 0.1 BNB");
        require(msg.value <= maxPurchase, "Maximum purchase is 10 BNB");
        uint tokenAmount = msg.value * rate;
        IERC20(tokenAddress).transfer(msg.sender, tokenAmount);
        sold += msg.value;
        emit Bought(tokenAmount);
    }

    function setRate(uint _rate) external onlyOwner {
        rate = _rate;
    }

    function withdrawBNB() external onlyOwner {
        payable(owner).transfer(address(this).balance);
    }

    function withdrawTokens() external onlyOwner {
        IERC20 token = IERC20(tokenAddress);
        uint balance = token.balanceOf(address(this));
        token.transfer(owner, balance);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the contract owner can call this function");
        _;
    }
}