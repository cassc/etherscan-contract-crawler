// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract FireCatIssueStorages {
    /* ========== STATE VARIABLES ========== */
    struct UserPledge {
        uint256 pledgeTotal;
        uint256 startTime;
        uint256 enderTime;
        uint256 lastTime;
        uint256 generateQuantity;
        uint256 numberOfRewardsPerSecond;
    }

    address public fireCatNFT;
    address public fireCatNFTStake;

    uint256 public totalStaked;
    uint256 public totalClaimed;
    uint256 public totalSupply;
    
    uint256 public rewardRate;
    uint256 public lockTime;
    address public rewardsToken;
    uint256 public poolStartTime;
   
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;

    mapping(uint256 => uint256) public received;
    mapping(uint256 => uint256) public rewards;
    mapping(uint256 => uint256) public staked;
    mapping(address => uint256) public claimed;

    mapping(address => UserPledge) public userData;
    mapping(uint256 => uint256) public userRewardPerTokenPaid;

}