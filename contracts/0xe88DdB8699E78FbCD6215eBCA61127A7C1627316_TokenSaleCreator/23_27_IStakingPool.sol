pragma solidity ^0.8.0;

interface IStakingPool {
  struct Stake {
    uint256 amountStaked;
    address tokenStaked;
    uint256 since;
    address staker;
    bytes32 stakeId;
    uint256 nextWithdrawalTime;
  }

  event Staked(uint256 amount, address token, uint256 since, address staker, bytes32 stakeId);
  event Unstaked(uint256 amount, bytes32 stakeId);
  event Withdrawn(uint256 amount, bytes32 stakeId);

  function stakes(bytes32)
    external
    view
    returns (
      uint256,
      address,
      uint256,
      address,
      bytes32,
      uint256
    );

  // function poolsByAddresses(address) external view returns (bytes32[] memory);

  function blockedAddresses(address) external view returns (bool);

  function stakeIDs(uint256) external view returns (bytes32);

  function stakingPoolTax() external view returns (uint8);

  function tokenA() external view returns (address);

  function tokenB() external view returns (address);

  function stakeAsset(address, uint256) external;

  function withdrawRewards(bytes32) external;

  function tokenAAPY() external view returns (uint16);

  function tokenBAPY() external view returns (uint16);

  function withdrawalIntervals() external view returns (uint256);

  function unstakeAmount(bytes32, uint256) external;

  function unstakeAll(bytes32) external;
}