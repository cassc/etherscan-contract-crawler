// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './../structs/JBTiered721SetTierDelegatesData.sol';
import './IJBTiered721Delegate.sol';

interface IJB721TieredGovernance is IJBTiered721Delegate {
  event TierDelegateChanged(
    address indexed delegator,
    address indexed fromDelegate,
    address indexed toDelegate,
    uint256 tierId,
    address caller
  );

  event TierDelegateVotesChanged(
    address indexed delegate,
    uint256 indexed tierId,
    uint256 previousBalance,
    uint256 newBalance,
    address caller
  );

  event DelegateChanged(
    address indexed delegator,
    address indexed fromDelegate,
    address indexed toDelegate
  );

  function getTierDelegate(address _account, uint256 _tier) external view returns (address);

  function getTierVotes(address _account, uint256 _tier) external view returns (uint256);

  function getPastTierVotes(
    address _account,
    uint256 _tier,
    uint256 _blockNumber
  ) external view returns (uint256);

  function getTierTotalVotes(uint256 _tier) external view returns (uint256);

  function getPastTierTotalVotes(uint256 _tier, uint256 _blockNumber)
    external
    view
    returns (uint256);

  function setTierDelegate(address _delegatee, uint256 _tierId) external;

  function setTierDelegates(JBTiered721SetTierDelegatesData[] memory _setTierDelegatesData)
    external;
}