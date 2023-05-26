// SPDX-License-Identifier: None

pragma solidity ^0.7.4;

/**
 * @title Interface of COVER shield mining contract Blacksmith
 * @author [email protected]
 */
interface IBlacksmith {
  struct Miner {
    uint256 amount;
    uint256 rewardWriteoff; // the amount of COVER tokens to write off when calculate rewards from last update
    uint256 bonusWriteoff; // the amount of bonus tokens to write off when calculate rewards from last update
  }

  struct Pool {
    uint256 weight; // the allocation weight for pool
    uint256 accRewardsPerToken; // accumulated COVER to the lastUpdated Time
    uint256 lastUpdatedAt; // last accumulated rewards update timestamp
  }

  struct BonusToken {
    address addr; // the external bonus token, like CRV
    uint256 startTime;
    uint256 endTime;
    uint256 totalBonus; // total amount to be distributed from start to end
    uint256 accBonusPerToken; // accumulated bonus to the lastUpdated Time
    uint256 lastUpdatedAt; // last accumulated bonus update timestamp
  }

  event Deposit(address indexed miner, address indexed lpToken, uint256 amount);
  event Withdraw(address indexed miner, address indexed lpToken, uint256 amount);

  // View functions
  function getPoolList() external view returns (address[] memory);
  function viewMined(address _lpToken, address _miner) external view returns (uint256 _minedCOVER, uint256 _minedBonus);
  // function minedRewards(address _lpToken, address _miner) external view returns (uint256);
  // function minedBonus(address _lpToken, address _miner) external view returns (uint256 _minedBonus, address _bonusToken);

  // User action functions
  function claimRewardsForPools(address[] calldata _lpTokens) external;
  function claimRewards(address _lpToken) external;
  function deposit(address _lpToken, uint256 _amount) external;
  function withdraw(address _lpToken, uint256 _amount) external;
  function emergencyWithdraw(address _lpToken) external;

  // Partner action functions
  function addBonusToken(address _lpToken, address _bonusToken, uint256 _startTime, uint256 _endTime, uint256 _totalBonus) external;

  // COVER mining actions
  function updatePool(address _lpToken) external;
  function updatePools(uint256 _start, uint256 _end) external;
  /// @notice dust will be collected to COVER treasury
  function collectDust(address _token) external;
  function collectBonusDust(address _lpToken) external;

  /// @notice only dev
  function addPool(address _lpToken, uint256 _weight) external;
  function addPools(address[] calldata _lpTokens, uint256[] calldata _weights) external;
  function updateBonusTokenStatus(address _bonusToken, uint8 _status) external;

  /// @notice only governance
  function updatePoolWeights(address[] calldata _lpTokens, uint256[] calldata _weights) external;
  function updateWeeklyTotal(uint256 _weeklyTotal) external;
  function transferMintingRights(address _newAddress) external;
}