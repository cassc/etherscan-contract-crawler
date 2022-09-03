// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "./Interfaces/INFTStaking.sol";
import "hardhat/console.sol";

contract LandReservePool is Ownable {

    using Address for address;

    // Staking Contracts
    address public landStaking;
    address public bonusPackStaking;

    // Reward parameters
    uint256 public constant REWARD_INTERVAL = 30 days;
    uint256 public currentRewardIndex;

    struct MonthlyReward {
        uint256 snapshot;
        uint256 totalWeight;
        uint256 reward;
        uint256 validUntil;
    }

    struct Reward {
        bool claimed;
        uint256 claimedAt;
        uint256 amount;
    }
    // Monthly rewards
    mapping(uint256 => MonthlyReward) public monthlyRewards;

    // Rewards collected by users
    mapping(address => mapping(uint256 => Reward)) public rewardsCollected;


    constructor(address landStakingAddress, address bonusPackStakingAddress)    
    {
        landStaking = landStakingAddress;
        bonusPackStaking = bonusPackStakingAddress;
    }


    /**
     * ===============================================================
     * ***************************************************************
     * Take snapshot of current state of the pool
     * ***************************************************************
     * ===============================================================
     */
    function takeSnapshot(
        uint256 weight,
        uint256 snapshot
    ) payable external onlyOwner {
        // require(msg.value > 0, "ZERO_AMOUNT");
        // require(weight > 0, "ZERO_WEIGHT");
        // require(snapshot > monthlyRewards[currentRewardIndex].snapshot, "OLDER_SNAPSHOT");

        currentRewardIndex = currentRewardIndex + 1;
        monthlyRewards[currentRewardIndex] = MonthlyReward(
            snapshot,
            weight,
            address(this).balance,
            snapshot + REWARD_INTERVAL
        );
    }

    /**
     * ===============================================================
     * ***************************************************************
     * Claim monthly reward by User
     * ***************************************************************
     * ===============================================================
     */
    function claimReward(address user) public {
        require(monthlyRewards[currentRewardIndex].reward > 0, "NO_REWARDS");
        require(block.timestamp < monthlyRewards[currentRewardIndex].validUntil, "REWARD_EXPIRED");
        require(!rewardsCollected[user][currentRewardIndex].claimed, "REWARD_ALREADY_CLAIMED");

        // Get reward amount
        uint256 totalLandWeightOfUser = getTotalLandWeightByUser(user);
        uint256 rewardAmount = (monthlyRewards[currentRewardIndex].reward *
            totalLandWeightOfUser) /
            (monthlyRewards[currentRewardIndex].totalWeight);
        // Claim reward
        require(rewardAmount > 0, "ZERO_REWARD");
        Address.sendValue(payable(msg.sender), rewardAmount);
        // Update reward status
        rewardsCollected[user][currentRewardIndex] = Reward(true, block.timestamp, rewardAmount);
    }


    function getClaimableReward(address user) public view returns (uint256) {
        // Get reward amount
        uint256 totalLandWeightOfUser = getTotalLandWeightByUser(user);
        uint256 rewardAmount = (monthlyRewards[currentRewardIndex].reward *
            totalLandWeightOfUser) /
            (monthlyRewards[currentRewardIndex].totalWeight);
        return rewardAmount;
    }

    /**
     * ===============================================================
     * ***************************************************************
     * Withdraw unclaimed rewards by owner
     * ***************************************************************
     * ===============================================================
     */
    function withdrawLeftOverRewards() external virtual onlyOwner {
        require(address(this).balance > 0, "ZERO_BALANCE");
        uint256 balance = address(this).balance;
        Address.sendValue(payable(msg.sender), balance);
        // Terminate current monthly reward
        monthlyRewards[currentRewardIndex].reward = 0;
        monthlyRewards[currentRewardIndex].validUntil = block.timestamp;
    }

    /**
     * ===============================================================
     * ***************************************************************
     * Reward helper functions
     * ***************************************************************
     * ===============================================================
     */
    // Get Long Term Holding multiplier
    function getLTHM(uint256 stakedDuration) public pure returns (uint256) {
        uint256 mult = 2000;
        if (stakedDuration < REWARD_INTERVAL) {
            mult = 0;
        } else if (
            stakedDuration >= REWARD_INTERVAL &&
            stakedDuration < 3 * REWARD_INTERVAL
        ) {
            mult = 1000;
        } else if (
            stakedDuration >= 3 * REWARD_INTERVAL &&
            stakedDuration < 6 * REWARD_INTERVAL
        ) {
            mult = 1100;
        } else if (
            stakedDuration >= 6 * REWARD_INTERVAL &&
            stakedDuration < 12 * REWARD_INTERVAL
        ) {
            mult = 1200;
        } else if (
            stakedDuration >= 12 * REWARD_INTERVAL &&
            stakedDuration < 18 * REWARD_INTERVAL
        ) {
            mult = 1300;
        } else if (
            stakedDuration >= 18 * REWARD_INTERVAL &&
            stakedDuration < 24 * REWARD_INTERVAL
        ) {
            mult = 1400;
        } else if (
            stakedDuration >= 24 * REWARD_INTERVAL &&
            stakedDuration < 30 * REWARD_INTERVAL
        ) {
            mult = 1500;
        } else if (
            stakedDuration >= 30 * REWARD_INTERVAL &&
            stakedDuration < 36 * REWARD_INTERVAL
        ) {
            mult = 1600;
        } else if (
            stakedDuration >= 36 * REWARD_INTERVAL &&
            stakedDuration < 42 * REWARD_INTERVAL
        ) {
            mult = 1700;
        } else if (
            stakedDuration >= 42 * REWARD_INTERVAL &&
            stakedDuration < 48 * REWARD_INTERVAL
        ) {
            mult = 1800;
        }
        return mult;
    }

    // Get Land Weight by land token ID
    function getLandWeight(uint256 tokenId) public pure returns (uint256) {
        uint256 weight = 0;
        if (tokenId <= 375) {
            weight = 33000;
        } else if (tokenId <= 835) {
            weight = 11000;
        } else if (tokenId <= 2205) {
            weight = 5500;
        } else if (tokenId <= 7200) {
            weight = 2750;
        } else if (tokenId <= 15000) {
            weight = 1000;
        }
        return weight;
    }

    // Get bonus multiplier by eligible number of bonuses
    function getBonusMultiplier(uint256 bonusPacks)
        public
        pure
        returns (uint256)
    {
        uint256 mult = 2650;
        if (bonusPacks == 0) {
            mult = 1;
        } else if (bonusPacks == 1) {
            mult = 1100;
        } else if (bonusPacks > 1 && bonusPacks <= 5) {
            mult = 1100 + (bonusPacks - 1) * 50;
        } else if (bonusPacks > 5 && bonusPacks <= 50) {
            mult = 1300 + (bonusPacks - 5) * 30;
        }
        return mult;
    }

    // Get total land weight by user
    function getTotalLandWeightByUser(address user)
        public
        view
        returns (uint256)
    {
        uint256 balance = IERC721Enumerable(landStaking).balanceOf(user);
        uint256 totalWeight = 0;
        for (uint256 idx = 0; idx < balance; idx++) {
            uint256 token = IERC721Enumerable(landStaking).tokenOfOwnerByIndex(
                user,
                idx
            );
            uint256 stakedFrom = INFTStaking(landStaking)
                .getStakeInformation(token)
                .stakedFrom;
            if (monthlyRewards[currentRewardIndex].snapshot > stakedFrom) {
                uint256 stakedDuration = monthlyRewards[currentRewardIndex]
                    .snapshot - stakedFrom;

                uint256 weight = getLandWeight(token);
                uint256 lthm = getLTHM(stakedDuration);
                totalWeight = totalWeight + weight * lthm;
            }
        }

        uint256 bpm = getBonusMultiplierByUser(user);
        totalWeight = totalWeight * bpm;

        return totalWeight;
    }
    // Get bonus multiplier by user
    function getBonusMultiplierByUser(address user)
        public
        view
        returns (uint256)
    {
        uint256 balance = IERC721Enumerable(bonusPackStaking).balanceOf(user);

        uint256 eligibleBonus = 0;
        for (uint256 idx = 0; idx < balance; idx++) {
            uint256 token = IERC721Enumerable(bonusPackStaking)
                .tokenOfOwnerByIndex(user, idx);
            uint256 stakedFrom = INFTStaking(bonusPackStaking)
                .getStakeInformation(token)
                .stakedFrom;
            if (monthlyRewards[currentRewardIndex].snapshot > stakedFrom) {
                uint256 stakedDuration = monthlyRewards[currentRewardIndex]
                    .snapshot - stakedFrom;
                if (stakedDuration > REWARD_INTERVAL) {
                    eligibleBonus = eligibleBonus + 1;
                }
            }
        }
        uint256 mult = getBonusMultiplier(eligibleBonus);

        return mult;
    }

    // Get the active status of the reward
    function isRewardActive() public view returns (bool) {
        return
            block.timestamp > monthlyRewards[currentRewardIndex].snapshot  &&
            block.timestamp < monthlyRewards[currentRewardIndex].validUntil;
    } 
}