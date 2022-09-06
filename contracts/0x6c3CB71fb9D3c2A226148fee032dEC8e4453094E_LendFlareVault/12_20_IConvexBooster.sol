// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;
pragma abicoder v2;

interface IConvexBooster {
  struct PoolInfo {
    uint256 originConvexPid;
    address curveSwapAddress; /* like 3pool https://github.com/curvefi/curve-js/blob/master/src/constants/abis/abis-ethereum.ts */
    address lpToken;
    address originCrvRewards;
    address originStash;
    address virtualBalance;
    address rewardCrvPool;
    address rewardCvxPool;
    bool shutdown;
  }

  function poolInfo(uint256 _pid) external view returns (PoolInfo memory);

  function depositAll(uint256 _pid, bool _stake) external returns (bool);

  function deposit(
    uint256 _pid,
    uint256 _amount,
    bool _stake
  ) external returns (bool);

  function getRewards(uint256 _pid) external;
}