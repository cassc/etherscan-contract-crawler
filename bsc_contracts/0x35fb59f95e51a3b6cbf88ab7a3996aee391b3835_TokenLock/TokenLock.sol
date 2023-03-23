/**
 *Submitted for verification at BscScan.com on 2023-03-23
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ERC20 {
    function transfer(address to, uint256 value) external returns (bool);
    function balanceOf(address who) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
}

contract TokenLock {
    address public tokenAddress;
    address public owner;
    uint256 public releaseTime;
    
    constructor(address _tokenAddress, uint256 _releaseTime) {
        tokenAddress = _tokenAddress;
        owner = msg.sender;
        releaseTime = _releaseTime;
    }
    
    function lockTokens(uint256 amount) public {
        require(msg.sender == owner, "Only the owner can lock tokens");
        require(amount > 0, "Amount must be greater than zero");
        
        ERC20 token = ERC20(tokenAddress);
        
        require(token.transferFrom(msg.sender, address(this), amount), "Failed to transfer tokens to lock");
    }
    
    function releaseTokens() public {
        require(msg.sender == owner, "Only the owner can release tokens");
        require(block.timestamp >= releaseTime, "Lockup period has not ended yet");
        
        ERC20 token = ERC20(tokenAddress);
        
        uint256 lockedAmount = token.balanceOf(address(this));
        require(lockedAmount > 0, "No tokens are locked");
        
        require(token.transfer(owner, lockedAmount), "Failed to transfer locked tokens");
    }
    function setOwner(address _to) public {
        require(msg.sender == owner,"Only the owner can change owner");
        owner = _to;
    }

    function getContractBalance() public view returns(uint256) {
        ERC20 token = ERC20(tokenAddress);
        return token.balanceOf(address(this));
    }

    function getTimeStampLeft() public view returns(uint256) {
        uint256 timeLeft = releaseTime - block.timestamp;
        return timeLeft;
    }
}