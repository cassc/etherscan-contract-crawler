/**
 *Submitted for verification at Etherscan.io on 2023-09-24
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function totalSupply() external view returns (uint256);
}

contract EtherDistributionContract {
    address public owner;
    mapping(address => uint256) private claimTimestamps;
    uint256 public claimDuration = 1 hours; // 24 hours in seconds
    uint256 private minEthContract;
    uint256 public minTokenHolding;
    uint256 public minEthWithdraw;  
    address public tokenAddress; // Address of the ERC-20 token contract
    IERC20 public token; // ERC-20 token instance

    constructor(address _tokenAddress) {
        owner = msg.sender;
        tokenAddress = _tokenAddress;
        token = IERC20(_tokenAddress);
        minEthContract = 100000000000000000;
        minTokenHolding = 1000;
        minEthWithdraw = 1;
        
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function");
        _;
    }

    function getTokenAddress() public view returns (address) {
        return tokenAddress;
    }

    function setTokenAddress(address _newTokenAddress) external onlyOwner {
        tokenAddress = _newTokenAddress;
        token = IERC20(_newTokenAddress); // Update the ERC-20 token instance
    }

    function getMinTokenHolding() public view returns (uint256) {
        return minTokenHolding;
    }

    function setMinTokenHolding(uint256 _newMinTokenHolding) external onlyOwner {
        minTokenHolding = _newMinTokenHolding;
    }

    function getMinEth() public view returns (uint256) {
        return minEthContract;
    }

    function setMinEth(uint256 _newMinEth) external onlyOwner {
        minEthContract = _newMinEth;
    }
    
    function getMinEthWithdraw() public view returns (uint256) {
        return minEthWithdraw;
    }

    function setMinEthWithdraw(uint256 _newMinEthWithdraw) external onlyOwner {
        minEthWithdraw = _newMinEthWithdraw;
    }

    function getToken() public view returns (IERC20) {
        return token;
    }

    function getClaimDuration() public view returns (uint256) {
        return claimDuration;
    }

    function setClaimDuration(uint256 _newDuration) external onlyOwner {
        claimDuration = _newDuration;  
    }

    function claim() external {
        uint256 contractBalance = address(this).balance;
        require(contractBalance > minEthContract, "You can't claim yet");
        require(canClaim(msg.sender), "You can't claim yet");

        uint256 userBalance = token.balanceOf(msg.sender);
        require(userBalance > minTokenHolding, "You're holding less than 4000 coins");

        uint256 totalSupply = token.totalSupply();
        uint256 percentage = (userBalance * 10000) / totalSupply;
        uint256 amountToTransfer = (contractBalance * percentage) / 10000;
        
        require(contractBalance >= minEthWithdraw , "Amount is less than the withdrawal limit");        
        require(amountToTransfer <= contractBalance, "Insufficient contract balance");

        // Mark the user as claimed
        claimTimestamps[msg.sender] = block.timestamp;

        // Transfer ether to the user
        payable(msg.sender).transfer(amountToTransfer);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "New owner cannot be zero address");
        owner = newOwner;
    }

    function canClaim(address user) public view returns (bool) {
        return claimTimestamps[user] + claimDuration <= block.timestamp;
    }

    function withdrawBalance() external onlyOwner {
        uint256 contractBalance = address(this).balance;
        require(contractBalance > 0, "No balance to withdraw");
        payable(owner).transfer(contractBalance);
    }

    receive() external payable {
    // Ether sent to the contract's address will be stored in the contract's balance
    }
}