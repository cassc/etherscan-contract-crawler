// SPDX-License-Identifier: MIT
// https://github.com/daomaker/stakevr/blob/master/contracts/MetaShooterClaimer.sol
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./MetaShooterStaker.sol";

import "hardhat/console.sol";

contract MetaShooterClaimer is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    uint48 internal constant SECS_PER_MONTH = 2592000;

    struct Reward {
        uint128 amount;
        uint48 claimId;
        uint16 claimedMonthsCount;
        uint48 timestamp;
    }

    struct Claim {
        uint48 stakeId;
        uint128 amount;
        uint128 totalAmount;
        uint16 claimedMonthsCount;
        bool saved;
    }

    mapping(address => Reward[]) public rewards;
    mapping(address => Claim[]) public claims;

    IERC20 immutable public rewardToken;
    MetaShooterStaker immutable public stake;

    event ClaimReward(
        address staker,
        uint256 reward
    );

    constructor(
        MetaShooterStaker _staker,
        IERC20 _rewardToken
    ) {
        stake = _staker;
        rewardToken = _rewardToken;
    }

    function claim(address staker) external nonReentrant returns (uint256 reward) {
        for (uint i = 0; i < stake.stakerStakeCount(staker); i++) {
            Claim memory claim = getStakerRewardForStake(staker, uint48(i));
            if (!claim.saved){
                claim.saved = true;
                claims[staker].push(claim);
            } else {
                claims[staker][i] = claim;
            }
            if (claim.amount > 0){
                rewards[staker].push(Reward(
                    claim.amount,
                    claim.stakeId,
                    claim.claimedMonthsCount,
                    uint48(block.timestamp)
                ));
            }
            reward += claim.amount;
        }

        require(reward > 0, "MetaShooterClaimer: no reward to claim");
        rewardToken.safeTransfer(staker, reward);

        emit ClaimReward(staker, reward);
    }

    function fundRewards(uint128 amount) external nonReentrant {
        rewardToken.safeTransferFrom(msg.sender, address(this), amount);
    }

    function withdrawRewards(uint128 amount) external onlyOwner {
        rewardToken.safeTransfer(msg.sender, amount);
    }

    function getStakerReward(address staker) public view returns (uint256 reward){
        for (uint i = 0; i < stake.stakerStakeCount(staker); i++) {
            Claim memory claim = getStakerRewardForStake(staker, uint48(i));
            reward += claim.amount;
        }
    }

    function getStakerRewardForStake(address staker, uint48 stakeId) public view returns (Claim memory){
        uint stakesCount = stake.stakerStakeCount(staker);

        (bool unstaked, uint128 amount, uint48 lockTimestamp, uint16 lockDays, uint16 shareBonus, uint16 shareLongBonus) = stake.stakers(staker, stakeId);
        Claim memory claim = Claim(uint48(stakeId), 0, 0, 0, false);
        if (stakeId < claims[staker].length) {
            claim = claims[staker][stakeId];
        }

        uint16 claimedMonthsCount = claim.claimedMonthsCount;
        uint48 passedMonthCount = (uint48(block.timestamp) - lockTimestamp) / SECS_PER_MONTH;
        uint16 maxClaimMonthCount = lockDays/30;
        if (passedMonthCount < maxClaimMonthCount){
            maxClaimMonthCount = uint16(passedMonthCount);
        }
        (uint192 shares, ,) = stake.calculateStakeShares(amount, lockDays, shareBonus, shareLongBonus);
        claim.totalAmount = uint128(shares) - amount;
        claim.amount = claim.totalAmount * (maxClaimMonthCount - claimedMonthsCount) * 30 / lockDays;
        claim.claimedMonthsCount = maxClaimMonthCount;
        return claim;
    }

    function getTotalRewards(uint48 stakerCount) public view returns (uint256 totalReward, uint256 paidReward, int256 balance) {
        for (uint x = 0; x < stakerCount; x++) {
            address staker = stake.stakerList(x);

            for (uint i = 0; i < stake.stakerStakeCount(staker); i++) {
                (bool unstaked, uint128 amount, uint48 lockTimestamp, uint16 lockDays, uint16 shareBonus, uint16 shareLongBonus) = stake.stakers(staker, i);
                (uint192 shares, ,) = stake.calculateStakeShares(amount, lockDays, shareBonus, shareLongBonus);
                totalReward += (shares - amount);
            }

            for (uint k = 0; k < rewards[staker].length; k++) {
                paidReward += rewards[staker][k].amount;
            }
        }

        balance = int256(int256(rewardToken.balanceOf(address(this))) - int256(totalReward) + int256(paidReward));
    }

    function stakerClaimCount(address stakerAddress) public view returns (uint) {
        return claims[stakerAddress].length;
    }

    function stakerRewardsCount(address stakerAddress) public view returns (uint) {
        return rewards[stakerAddress].length;
    }
}