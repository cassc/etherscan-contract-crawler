// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

interface IInfinityNFTPeriphery {
  event InfinityStake(address indexed sender, uint amount, uint share, uint id);
  event InfinityBoost(address indexed sender, uint amount, uint share, uint id);

  function permanentStaking(
    address _to,
    address _token0,
    uint _amount0In,
    uint _shareMin,
    uint _deadline
  ) external returns (uint share);

  function permanentStakingEth(
    address _to,
    uint _shareMin,
    uint _deadline
  ) external payable returns (uint share);

  function permanentBoosting(
    address _token0,
    uint _amount0In,
    uint _shareMin,
    uint _id,
    uint _deadline
  ) external returns (uint share);

  function permanentBoostingEth(
    uint _shareMin,
    uint _id,
    uint _deadline
  ) external payable returns (uint share);
}