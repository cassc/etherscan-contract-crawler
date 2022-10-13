// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "./Village.sol";
import "./CharacterStaking.sol";
import "./NftStaking.sol";
import "./KingVault.sol";

contract WeaponStaking is NftStaking {

  CharacterStaking public characterStaking;
  KingVault public kingVault;

  mapping(uint => uint) public kingRewards;

  function initialize(Village _village, address nftAddress, CharacterStaking _characterStaking, KingVault _kingVault) public initializer {
    super.initialize(_village, nftAddress);

    characterStaking = _characterStaking;
    kingVault = _kingVault;
  }

  function stake(uint[] memory ids) public override returns (uint finishTimestamp)  {
    uint256 stakedCharacters = characterStaking.getStakedAmount(msg.sender);
    require(stakedCharacters >= getNextRequirement(), 'You need to stake more characters');
    uint beforeStakeUnlocked = unlockedTiers[msg.sender];
    finishTimestamp = super.stake(ids);
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