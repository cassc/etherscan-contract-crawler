/**
 *Submitted for verification at Etherscan.io on 2023-05-29
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

interface ERC20 {
    function transfer(address to, uint256 value) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract LoveYou {
    address public tokenContractAddress;
    address public owner;
    uint256 public pricePerClaim; // Price per claim in wei
    
    event GetLove(address indexed sender, uint256 amount);
    event TokensRemoved(uint256 amount);
    
    constructor(address _tokenContractAddress) {
        tokenContractAddress = _tokenContractAddress;
        owner = msg.sender;
        pricePerClaim = 0.0069 ether; // Default price per claim
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only the contract owner can call this function.");
        _;
    }
    
    function setPricePerClaim(uint256 _price) external onlyOwner {
        pricePerClaim = _price;
    }
    
    function claimTokens() external payable {
        require(msg.value >= pricePerClaim, "Insufficient ETH sent to claim tokens.");
        
        ERC20 tokenContract = ERC20(tokenContractAddress);
        
        bool success = tokenContract.transfer(msg.sender, 1 * 10^18);
        require(success, "Token transfer failed.");
        
        emit GetLove(msg.sender, 1 * 10^18);
    }

    function removeTokens(uint256 amount) external onlyOwner {
        
        ERC20 tokenContract = ERC20(tokenContractAddress);
        
        bool success = tokenContract.transfer(owner, amount);
        require(success, "Token transfer failed.");
        
        emit TokensRemoved(amount);
    }
    
    function withdrawEth() external onlyOwner {
        
        (bool success, ) = owner.call{value: address(this).balance}("");
        require(success, "ETH withdrawal failed.");
    }
}