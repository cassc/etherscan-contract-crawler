// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import './IIdoStorageState.sol';


interface IIdoStorageEvents {
  event IdoStateUpdated(IIdoStorageState.State state);

  event RoundOpened(uint256 indexed index);
  event RoundClosed(uint256 indexed index);
  event RoundAdded(uint256 priceVestingShort, uint256 priceVestingLong, uint256 totalSupply);
  event RoundPriceUpdated(uint256 indexed index, uint256 priceVestingShort, uint256 priceVestingLong);
  event RoundSupplyUpdated(uint256 indexed index, uint256 totalSupply);

  event KycCapUpdated(uint256 cap);
  event KycPassUpdated(address indexed beneficiary, bool value);
  event MaxInvestmentUpdated(uint256 investment);
  event MinInvestmentUpdated(uint256 investment);

  event DefaultReferralSetup(uint256 mainReferralReward, uint256 secondaryReferralReward);
  event ReferralSetup(address indexed referral, uint256 mainReward, uint256 secondaryReward);
  event ReferralEnabled(address indexed referral);
  event ReferralDisabled(address indexed referral);
  event ClaimedRewards(address indexed referral, address indexed collateral, uint256 amount);

  event ERC20Recovered(address token, uint256 amount);
  event NativeRecovered(uint256 amount);
}