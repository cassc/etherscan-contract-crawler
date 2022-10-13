// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "./Village.sol";
import "./NftStaking.sol";

contract CharacterStaking is NftStaking {

  function initialize(Village _village, address nftAddress) override public initializer {
    super.initialize(_village, nftAddress);
  }

  function stake(uint[] memory ids) public override returns (uint finishTimestamp) {
    uint256 stakedLandId = village.stakedLand(msg.sender);
    uint256 barracksLevel = village.getBuildingLevel(stakedLandId, Village.Building(BARRACKS));
    require(barracksLevel >= getNextRequirement(), 'You need to upgrade barracks');
    finishTimestamp = super.stake(ids);
  }
}