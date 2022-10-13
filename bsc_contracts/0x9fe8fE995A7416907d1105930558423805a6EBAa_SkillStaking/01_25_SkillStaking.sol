// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "./Village.sol";
import "./CurrencyStaking.sol";
import "./KingStaking.sol";
import "./KingVault.sol";

contract SkillStaking is CurrencyStaking {

  KingStaking public kingStaking;
  KingVault public kingVault;

  mapping(uint => uint) public kingRewards;

  function initialize(Village _village, KingStaking _kingStaking, address currencyAddress, KingVault _kingVault) public initializer {
    super.initialize(_village, currencyAddress);

    kingStaking = _kingStaking;
    kingVault = _kingVault;
  }

  function stake(uint amount) public override returns (uint finishTimestamp) {
    require(kingStaking.getUnlockedTiers() >= getNextRequirement(), "You must unlock at least 4 tiers of king before staking skill");
    uint beforeStakeUnlocked = unlockedTiers[msg.sender];
    finishTimestamp = super.stake(amount);
    uint afterStakeUnlocked = unlockedTiers[msg.sender];
    if (beforeStakeUnlocked < afterStakeUnlocked) {
      kingVault.addToVault(msg.sender, kingRewards[afterStakeUnlocked]);
    }
  }

  function unstake() public override returns (bool stakeCompleted) {
    stakeCompleted = super.unstake();
    if (stakeCompleted) {
      kingVault.addToVault(msg.sender, kingRewards[unlockedTiers[tx.origin]]);
    }
  }

  function completeStake() public override {
    super.completeStake();
    kingVault.addToVault(msg.sender, kingRewards[unlockedTiers[msg.sender]]);
  }

  // ADMIN

  function addStake(uint id, uint duration, uint requirement, uint amount, uint kingReward) restricted external {
    stakes[id] = Stake({duration : duration, requirement : requirement, amount : amount});
    kingRewards[id] = kingReward;
  }
}