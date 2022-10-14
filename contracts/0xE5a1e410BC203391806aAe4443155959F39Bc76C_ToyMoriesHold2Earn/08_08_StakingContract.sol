// SPDX-License-Identifier: MIT LICENSE

/*
ToyMories ERC20 HOLD2EARN Smart Contract.

Follow/Twitter!
@pinpin_eth
 _____ _             _             _   _     
|  __ (_)           (_)           | | | |    
| |__) | _ __  _ __  _ _ __    ___| |_| |__  
|  ___/ | '_ \| '_ \| | '_ \  / _ \ __| '_ \ 
| |   | | | | | |_) | | | | ||  __/ |_| | | |
|_|   |_|_| |_| .__/|_|_| |_(_)___|\__|_| |_|
              | |                            
              |_|                            
*/
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract ToyMoriesHold2Earn is ReentrancyGuard {
    using SafeERC20 for IERC20;

    // Interfaces for ERC20 and ERC721
    IERC20 public immutable rewardsToken;
    IERC721 public immutable nftCollection;

    // Constructor function to set the rewards token and the NFT collection addresses
    constructor(IERC721 _nftCollection, IERC20 _rewardsToken) {
        nftCollection = _nftCollection;
        rewardsToken = _rewardsToken;
        owner = msg.sender;
    }
    
    // Staker info
    struct TokenNFT {
        // Last time of the rewards were calculated for this ToyMories
        uint256 timeOfLastUpdate;
    }

    // Contract address owner.
    address private owner;

    // The start contract Timestamp.
    uint256 public InitTime;

    // The deadline contract Timestamp, the contract will last 10 years.
    uint256 public Deadline;

    // Rewards per hour per token deposited.
    uint256 private rewardsPerDay = 10 ether;

    // Mapping of User Address to Staker info
    mapping(uint256 => TokenNFT) private tokens;

     /**
     * Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner, "Not the owner");
        _;
    }

    // Set new owner for the contract.    
    function setNewOwner(address _newOwner) public onlyOwner() {
        owner = _newOwner;
    }

    // Set the start timestamp contract and his state.    
    function setInitTime(uint256 _initTimestamp) public onlyOwner() {
        InitTime = _initTimestamp;
    }

    // Set the deadline timestamp contract and his state.    
    function setDeadline(uint256 _Deadline) public onlyOwner() {
        Deadline = _Deadline;
    }

    // Calculate rewards for the ToyMories, check if there are any rewards
    // transfer the ERC20 Reward token to the user.
    function claimRewards(uint256 _tokenId) external {
        require(nftCollection.ownerOf(_tokenId) == msg.sender,
                "You don't own this token!");
        uint256 rewards = calculateRewards(_tokenId);
        require(rewards > 0, "You have no rewards to claim");
        tokens[_tokenId].timeOfLastUpdate = block.timestamp;
        rewardsToken.safeTransfer(msg.sender, rewards);
    } 
        
    // Calculate rewards for the ToyMories, check if there are any rewards
    // transfer the ERC20 Reward token to the user.
    function batchClaimRewards(uint256[] calldata _tokenIds) external {
        // Wallet must own the ToyMories
        uint256 tokenId;
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            tokenId = _tokenIds[i];
        require(nftCollection.ownerOf(tokenId) == msg.sender,
                "You don't own this token!");
            uint256 rewards = calculateRewards(tokenId);
            require(rewards > 0, "You have no rewards to claim");
            tokens[tokenId].timeOfLastUpdate = block.timestamp;
            rewardsToken.safeTransfer(msg.sender, rewards);
        }
    } 

    //////////
    // View //
    //////////

    function availableRewards(uint256 _tokenId) public view returns (uint256) {
        uint256 rewards = calculateRewards(_tokenId);
        return rewards / 1 ether;
    }

    /////////////
    // Internal//
    /////////////

    // Calculate rewards for param _staker by calculating the time passed
    // since last update in days and mulitplying it to ERC721 Tokens Staked
    // and rewardsPerDay.
    function calculateRewards(uint256 _tokenId)
        internal
        view
        returns (uint256 _rewards)
    {
        if (tokens[_tokenId].timeOfLastUpdate == 0 && block.timestamp <= Deadline) {
             return (((block.timestamp - InitTime) * rewardsPerDay) / 86400);
        } else if (tokens[_tokenId].timeOfLastUpdate == 0 && block.timestamp > Deadline){
           return (((Deadline - InitTime) * rewardsPerDay) / 86400);
        } else if (block.timestamp > Deadline && tokens[_tokenId].timeOfLastUpdate > 0){
           return (((Deadline - tokens[_tokenId].timeOfLastUpdate) * rewardsPerDay) / 86400);
        } else if (block.timestamp > Deadline && tokens[_tokenId].timeOfLastUpdate > Deadline){
           return 0;
        }else {
           return (((block.timestamp - tokens[_tokenId].timeOfLastUpdate) * rewardsPerDay) / 86400);
        }
    }
}