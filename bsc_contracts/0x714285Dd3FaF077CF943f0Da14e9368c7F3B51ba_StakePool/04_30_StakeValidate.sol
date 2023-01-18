//SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "../IStakePool.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

library StakeValidate {
    function validateRewardType(
        IStakePool.RewardType rewardType,
        uint256 rewardRatio,
        address rewardToken
    ) internal view {
        if(rewardType==IStakePool.RewardType.PercentRatio ||
            rewardType==IStakePool.RewardType.FixedRatio || rewardType==IStakePool.RewardType.NoRatio){
            require(rewardToken!=address(0), "invalide reward Token");
            uint8 decimals = IERC20Metadata(rewardToken).decimals();
            require(decimals>0, "invalide reward Token");
            if(rewardType==IStakePool.RewardType.NoRatio){
                require(rewardRatio==0, "invalide reward ratio");
            }
        }else{
            require(rewardRatio==0, "invalide reward ratio");
        }
    }
    function validateMinPeriod(
        uint256 minPeriod,
        bool transferrable
    ) internal pure {
        if(minPeriod>0){
            require(!transferrable, "Min period is not allowed for transferrable token");
        }
    }
    function validateClaimDate(        
        bool canClaimAnyTime,
        uint256 claimDateTime
    ) internal view {
        if(!canClaimAnyTime){
            require(claimDateTime>block.timestamp, "no claim time");
        }
    }
    function validatePeriod(
        uint256 _startDateTime,
        uint256 _endDateTime
    ) internal view {
        require(_startDateTime >= block.timestamp, "start date time >= now");
        require(_endDateTime == 0 || _endDateTime > _startDateTime, "end date time >= start date time");
    }

    function validateMinAmount(
        uint256 minAmountToStake,
        uint256 hardCap
    ) internal pure {
        require(hardCap >= minAmountToStake, "hardCap >= minAmountToStake");
    }

    function validateStake(
        uint256 balance, 
        IStakePool.StakeModel storage stakeModel,
        IStakePool.StakeStatus status
    ) internal view {
        require(balance>=stakeModel.minAmountToStake, "less than Min Amount");
        require(block.timestamp>=stakeModel.startDateTime, "not started");
        require(block.timestamp<stakeModel.endDateTime, "ended");
        require(status==IStakePool.StakeStatus.Alive, "cancelled stake");
    }

    function validateUnstake(
        uint256 stakeDateTime,
        IStakePool.StakeModel storage stakeModel
    ) internal view{
        if(!stakeModel.transferrable){
            require(stakeModel.minPeriodToStake+stakeDateTime<=block.timestamp, "still stake time");
        } 
    }

    function validateClaim(
        bool canClaimAnyTime,
        uint256 claimDateTime,
        IStakePool.RewardType rewardType,
        IStakePool.StakeStatus status
    ) internal view {
        if(!canClaimAnyTime)
            require(block.timestamp>=claimDateTime, "claimDateTime is not reached");
        require(rewardType!=IStakePool.RewardType.NoReward, "No reward stake pool.");
        require(status==IStakePool.StakeStatus.Alive, "cancelled stake");
    }
    function validateDeposit(
        IStakePool.RewardType rewardType,
        IStakePool.StakeStatus status
    ) internal pure {
        require(rewardType!=IStakePool.RewardType.NoReward, "No reward stake pool.");
        require(status==IStakePool.StakeStatus.Alive, "cancelled stake");
    }
    function validateDistribute(
        IStakePool.RewardType rewardType,
        IStakePool.StakeStatus status
    ) internal pure {
        require(status==IStakePool.StakeStatus.Alive, "cancelled stake");
        require(rewardType!=IStakePool.RewardType.NoReward && rewardType!=IStakePool.RewardType.NoRatio, "No ratio reward stake pool.");
    }
}