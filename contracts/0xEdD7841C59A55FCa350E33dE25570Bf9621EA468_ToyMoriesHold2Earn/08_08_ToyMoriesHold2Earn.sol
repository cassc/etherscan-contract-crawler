// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "./interfaces/IToken.sol";

contract ToyMoriesHold2Earn is ReentrancyGuard, Ownable , Pausable {
    
    IToken public immutable rewardsToken;
    IERC721 public immutable toyMories;
    IERC721 public immutable toyPets;

    // The last claimed time for each address.  
    mapping (address => uint256) public lastClaimedTime;

    // The start Timestamp.
    uint256 public startTime;

    // The end Timestamp.
    uint256 public endTime;

    // Rewards per hour per token deposited.
    uint256 public moriesRewardsPerDay = 10 ether;
    uint256 public petsRewardsPerDay = 20 ether;
    
    // Constructor function to set the rewards token and the NFT collection addresses
    constructor(IERC721 _toyMories,IERC721 _toyPets,IToken _rewardsToken) {
        toyMories = _toyMories;
        toyPets = _toyPets;
        rewardsToken = _rewardsToken;
    }
    
    // Set the start timestamp contract and his state.    
    function setStartTime(uint256 _timestamp) external onlyOwner() {
        startTime = _timestamp;
    }

    // Set the deadline timestamp contract and his state.    
    function setEndTime(uint256 _timestamp) external onlyOwner() {
        endTime = _timestamp;
    }

    // Set the rewards per hour per token deposited.
    function setRewardsPerDay(uint256 _moriesRewardsPerDay, uint256 _petsRewardsPerDay) external onlyOwner() {
        moriesRewardsPerDay = _moriesRewardsPerDay;
        petsRewardsPerDay = _petsRewardsPerDay;
    }

    // Calculate rewards for the ToyMories, check if there are any rewards
    // mint the ERC20 Reward token to the user.
    function claimRewards(address _address) external nonReentrant whenNotPaused{
        require(startTime != 0, "Hold2Earn: Not started yet");
        require(block.timestamp >= startTime, "Hold2Earn: Not started yet");
        require(toyMories.balanceOf(_address) > 0 || toyPets.balanceOf(_address) > 0, "Hold2Earn: No NFTs");
        uint256 rewards = calculateRewards(_address);
        require(rewards > 0, "Hold2Earn: No rewards");
        lastClaimedTime[_address] = block.timestamp;
        rewardsToken.mintTo(_address, rewards);
    } 

    // Calculate rewards for a address by using their balances of NFTS and the time passed.
    function calculateRewards(address _address)
        public
        view
        returns (uint256 _rewards)
    {
        uint256 moriesTokens = toyMories.balanceOf(_address);
        uint256 petsTokens = toyPets.balanceOf(_address);
        uint256 lastClaimed = lastClaimedTime[_address];
        if (lastClaimed == 0 && block.timestamp <= endTime) {
             return (((block.timestamp - startTime)) * (moriesTokens*moriesRewardsPerDay
             +petsTokens*petsRewardsPerDay) )/ 86400;
        } else if (lastClaimed == 0 && block.timestamp > endTime) {
             return (((endTime - startTime)) * (moriesTokens*moriesRewardsPerDay
             +petsTokens*petsRewardsPerDay))/ 86400;
        } else if (block.timestamp > endTime && lastClaimed > 0){
           return (((endTime - lastClaimed)) * (moriesTokens*moriesRewardsPerDay
             +petsTokens*petsRewardsPerDay) )/ 86400;
        } else if (block.timestamp > endTime && lastClaimed > endTime){
           return 0;
        }else {
           return (((block.timestamp - lastClaimed)) * (moriesTokens*moriesRewardsPerDay
             +petsTokens*petsRewardsPerDay) )/ 86400;
        }
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

}