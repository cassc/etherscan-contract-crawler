// contracts/CawName.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./RewardStaked.sol";

contract RewardStakedLp is RewardStaked {

  RewardStaked public rewardTokenDelegate;

  constructor(address _stakeable, uint256 _lockTime, address[] memory _rewardTokens, address _rewardTokenDelegateAddress)
  RewardStaked(_stakeable, _lockTime, _rewardTokens) {
    rewardTokenDelegate = RewardStaked(_rewardTokenDelegateAddress);

    // The only thing that an owner can do in this
    // contract is change the reward tokens, but
    // since we are delgating that functionality
    // away, there is no need for ownership
    renounceOwnership();
  }

  function getRewardTokens() public view override returns (address[] memory) {
    return rewardTokenDelegate.getRewardTokens();
  }

}