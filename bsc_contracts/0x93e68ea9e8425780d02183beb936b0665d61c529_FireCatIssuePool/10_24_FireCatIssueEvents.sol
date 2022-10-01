// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract FireCatIssueEvents {
    /**
    * @dev lockTime update event
    * @param newLockTime_ rewardRate_ 
    */
    event SetLockTime(uint256 newLockTime_);

    /**
    * @dev rewardRate update event
    * @param rewardRate_ rewardRate_ 
    */
    event SetRewardRate(uint256 rewardRate_);

    /**
    * @dev User staked event
    * @param tokenId_ User address
    * @param amount_ User staked amount
    */
    event IssueStaked(uint256 tokenId_, uint256 amount_);

    /**
    * @dev User withdrawn event
    * @param user_ User address
    * @param tokenId_ User tokenid
    * @param amount_ User withdrawn amount
    */
    event Withdrawn(address user_, uint256 tokenId_, uint256 amount_);

    /**
    * @dev User receive reward event
    * @param user_ User address
    * @param actualClaimedAmount_ User receive amount
    * @param totalClaimedNew_ total claimed amount
    */
    event IssueClaimed(address indexed user_, uint256 actualClaimedAmount_, uint256 totalClaimedNew_);

    /**
    * @dev User harvest event
    * @param _user User address
    * @param tokenId_ Harvest tokenId
    * @param _rewardsToken Rewards token address
    * @param _reward User harvest amount
    */
    event UserHarvest(address indexed _user, uint256 indexed tokenId_, address _rewardsToken, uint256 _reward);

    event TopUp(address user_, uint256 amount_, uint256 totalSupplyNew_);
    event SetFireCatNFTStake(address fireCatNFTStake_);
}