// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

// solhint-disable var-name-mixedcase

interface IStakingProxyConvex {
  function stakingAddress() external view returns (address);

  //create a new locked state of _secs timelength with a Curve LP token
  function stakeLockedCurveLp(uint256 _liquidity, uint256 _secs) external returns (bytes32 kek_id);

  //create a new locked state of _secs timelength with a Convex deposit token
  function stakeLockedConvexToken(uint256 _liquidity, uint256 _secs) external returns (bytes32 kek_id);

  //create a new locked state of _secs timelength
  function stakeLocked(uint256 _liquidity, uint256 _secs) external returns (bytes32 kek_id);

  //add to a current lock
  function lockAdditional(bytes32 _kek_id, uint256 _addl_liq) external;

  //add to a current lock
  function lockAdditionalCurveLp(bytes32 _kek_id, uint256 _addl_liq) external;

  //add to a current lock
  function lockAdditionalConvexToken(bytes32 _kek_id, uint256 _addl_liq) external;

  // Extends the lock of an existing stake
  function lockLonger(bytes32 _kek_id, uint256 new_ending_ts) external;

  //withdraw a staked position
  //frax farm transfers first before updating farm state so will checkpoint during transfer
  function withdrawLocked(bytes32 _kek_id) external;

  //withdraw a staked position
  //frax farm transfers first before updating farm state so will checkpoint during transfer
  function withdrawLockedAndUnwrap(bytes32 _kek_id) external;

  //helper function to combine earned tokens on staking contract and any tokens that are on this vault
  function earned() external view returns (address[] memory token_addresses, uint256[] memory total_earned);

  /*
    claim flow:
        claim rewards directly to the vault
        calculate fees to send to fee deposit
        send fxs to a holder contract for fees
        get reward list of tokens that were received
        send all remaining tokens to owner

    A slightly less gas intensive approach could be to send rewards directly to a holder contract and have it sort everything out.
    However that makes the logic a bit more complex as well as runs a few future proofing risks
    */
  function getReward() external;

  //get reward with claim option.
  //_claim bool is for the off chance that rewardCollectionPause is true so getReward() fails but
  //there are tokens on this vault for cases such as withdraw() also calling claim.
  //can also be used to rescue tokens on the vault
  function getReward(bool _claim) external;

  //auxiliary function to supply token list(save a bit of gas + dont have to claim everything)
  //_claim bool is for the off chance that rewardCollectionPause is true so getReward() fails but
  //there are tokens on this vault for cases such as withdraw() also calling claim.
  //can also be used to rescue tokens on the vault
  function getReward(bool _claim, address[] calldata _rewardTokenList) external;
}