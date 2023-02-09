// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol"; // interface for ERC20 token
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol"; // safe ERC20 token, safe transfer function
import "@openzeppelin/contracts/token/ERC721/IERC721.sol"; // interface for ERC21, NFT collection
import "@openzeppelin/contracts/security/ReentrancyGuard.sol"; // security contract

contract Freshboyz is ReentrancyGuard {
    using SafeERC20 for IERC20;

    // Interfaces for ERC20 and ERC721
    // Meaning: X is a type of Y
    IERC20 public immutable rewardsToken;
    IERC721 public immutable nftCollection;

    // Contructure that set address of rewardToken and nftCollection
    constructor(IERC721 _nftCollection, IERC20 _rewardToken) {
        rewardsToken = _rewardToken;
        nftCollection = _nftCollection;
    }

    struct StakedToken {
        address staker;
        uint256 tokenId;
    }

    // Staker Info
    struct Staker {
        uint256 amountStaked;
        StakedToken[] stakedTokens;
        uint256 timeOflastUpdate;
        /* Calculated, but unclaimed rewards for the user. 
      Rewards are calculated each time the user writes to the smart contract. */
        uint256 unclaimedRewards;
    }

    // Reward per hour in SHIFU
    uint256 private rewardsPerHour = 100000;

    /* Mapping of User address to Staker info 
    (for the smart contract to memorize who to send the token) */
    mapping(address => Staker) public stakers;
    mapping(uint256 => address) public stakerAddress;

    // Calculate the reward before adding new token (if the wallet has tokens staked)
    function stake(uint256 _tokenId) external nonReentrant {
        if (stakers[msg.sender].amountStaked > 0) {
            uint256 rewards = calculateRewards(msg.sender);
            stakers[msg.sender].unclaimedRewards += rewards;
        }

        // Wallet must own token in order to stake
        require(
            nftCollection.ownerOf(_tokenId) == msg.sender,
            "You don't own this token!"
        );

        // Transfer the token from the wallet to the smart contract
        nftCollection.transferFrom(msg.sender, address(this), _tokenId);

        StakedToken memory stakedToken = StakedToken(msg.sender, _tokenId);

        stakers[msg.sender].stakedTokens.push(stakedToken);
        stakers[msg.sender].amountStaked++;
        stakerAddress[_tokenId] = msg.sender;
        stakers[msg.sender].timeOflastUpdate = block.timestamp;
    }

    function withdraw(uint256 _tokenId) external nonReentrant {
        // Wallet must has token
        require(
            stakers[msg.sender].amountStaked > 0,
            "You have no tokens staked."
        );

        // Wallet must own the token
        require(
            stakerAddress[_tokenId] == msg.sender,
            "You don't own this token!"
        );

        // Find the index of this token id in stakedTokens array
        uint256 index = 0;
        for (uint256 i = 0; i < stakers[msg.sender].stakedTokens.length; i++) {
            if (stakers[msg.sender].stakedTokens[i].tokenId == _tokenId) {
                index = i;
                break;
            }
        }

        // Remove this token from the stakedTokenarray
        stakers[msg.sender].stakedTokens[index].staker = address(0);

        stakers[msg.sender].amountStaked--;
        stakerAddress[_tokenId] = address(0); // token is no longer staking
        nftCollection.transferFrom(address(this), msg.sender, _tokenId);
    }

    function claimRewards() external {
        uint256 rewards = calculateRewards(msg.sender) +
            stakers[msg.sender].unclaimedRewards;

        require(rewards > 0, "You have no reward to claim.");

        stakers[msg.sender].timeOflastUpdate = block.timestamp;
        stakers[msg.sender].unclaimedRewards = 0;

        rewardsToken.safeTransfer(msg.sender, rewards);
    }

    function calculateRewards(address _staker)
        internal
        view
        returns (uint256 _rewards)
    {
        return (((
            ((block.timestamp - stakers[_staker].timeOflastUpdate) +
                stakers[_staker].amountStaked)
        ) * rewardsPerHour) / 3600);
    }

    function availableRewards(address _staker) public view returns (uint256) {
        uint256 rewards = calculateRewards((_staker)) +
            stakers[_staker].unclaimedRewards;
        return rewards;
    }

    function getStakedTokens(address _user)
        public
        view
        returns (StakedToken[] memory)
    {
        if (stakers[_user].amountStaked > 0) {
            StakedToken[] memory _stakedTokens = new StakedToken[](
                stakers[_user].amountStaked
            );
            uint256 _index = 0;

            for (uint256 j = 0; j < stakers[_user].stakedTokens.length; j++) {
                if (stakers[_user].stakedTokens[j].staker != (address(0))) {
                    _stakedTokens[_index] = stakers[_user].stakedTokens[j];
                    _index++;
                }
            }

            return _stakedTokens;
        } else {
            return new StakedToken[](0);
        }
    }
}