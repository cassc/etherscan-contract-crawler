// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "./Village.sol";
import "./CurrencyStaking.sol";

contract KingStaking is CurrencyStaking {

  function initialize(Village _village, address currencyAddress) override public initializer {
    super.initialize(_village, currencyAddress);
  }

  function stake(uint amount, Village.Building building) public {
    uint256 stakedLandId = village.stakedLand(msg.sender);
    uint256 finishTimestamp = stake(amount);
    village.setCurrentlyUpgrading(stakedLandId, building, finishTimestamp);
  }

  function unstake() public override returns (bool stakeCompleted) {
    uint256 stakedLandId = village.stakedLand(tx.origin);
    stakeCompleted = super.unstake();
    village.setCurrentlyUpgrading(stakedLandId, Village.Building.NONE, 0);
  }

  function completeStake() public override {
    super.completeStake();
    village.finishBuildingUpgrade(village.stakedLand(msg.sender));
  }
}