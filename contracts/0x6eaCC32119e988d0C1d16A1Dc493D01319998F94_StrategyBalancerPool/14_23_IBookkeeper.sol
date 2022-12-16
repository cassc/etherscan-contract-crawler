// SPDX-License-Identifier: ISC
/**
* By using this software, you understand, acknowledge and accept that Tetu
* and/or the underlying software are provided “as is” and “as available”
* basis and without warranties or representations of any kind either expressed
* or implied. Any use of this open source software released under the ISC
* Internet Systems Consortium license is done at your own risk to the fullest
* extent permissible pursuant to applicable law any and all liability as well
* as all warranties, including any fitness for a particular purpose with respect
* to Tetu and/or the underlying software and the use thereof are disclaimed.
*/

pragma solidity 0.8.4;

interface IBookkeeper {

  struct PpfsChange {
    address vault;
    uint256 block;
    uint256 time;
    uint256 value;
    uint256 oldBlock;
    uint256 oldTime;
    uint256 oldValue;
  }

  struct HardWork {
    address strategy;
    uint256 block;
    uint256 time;
    uint256 targetTokenAmount;
  }

  function addVault(address _vault) external;

  function addStrategy(address _strategy) external;

  function registerStrategyEarned(uint256 _targetTokenAmount) external;

  function registerFundKeeperEarned(address _token, uint256 _fundTokenAmount) external;

  function registerUserAction(address _user, uint256 _amount, bool _deposit) external;

  function registerVaultTransfer(address from, address to, uint256 amount) external;

  function registerUserEarned(address _user, address _vault, address _rt, uint256 _amount) external;

  function registerPpfsChange(address vault, uint256 value) external;

  function registerRewardDistribution(address vault, address token, uint256 amount) external;

  function vaults() external view returns (address[] memory);

  function vaultsLength() external view returns (uint256);

  function strategies() external view returns (address[] memory);

  function strategiesLength() external view returns (uint256);

  function lastPpfsChange(address vault) external view returns (PpfsChange memory);

  /// @notice Return total earned TETU tokens for strategy
  /// @dev Should be incremented after strategy rewards distribution
  /// @param strategy Strategy address
  /// @return Earned TETU tokens
  function targetTokenEarned(address strategy) external view returns (uint256);

  /// @notice Return share(xToken) balance of given user
  /// @dev Should be calculated for each xToken transfer
  /// @param vault Vault address
  /// @param user User address
  /// @return User share (xToken) balance
  function vaultUsersBalances(address vault, address user) external view returns (uint256);

  /// @notice Return earned token amount for given token and user
  /// @dev Fills when user claim rewards
  /// @param user User address
  /// @param vault Vault address
  /// @param token Token address
  /// @return User's earned tokens amount
  function userEarned(address user, address vault, address token) external view returns (uint256);

  function lastHardWork(address vault) external view returns (HardWork memory);

  /// @notice Return users quantity for given Vault
  /// @dev Calculation based in Bookkeeper user balances
  /// @param vault Vault address
  /// @return Users quantity
  function vaultUsersQuantity(address vault) external view returns (uint256);

  function fundKeeperEarned(address vault) external view returns (uint256);

  function vaultRewards(address vault, address token, uint256 idx) external view returns (uint256);

  function vaultRewardsLength(address vault, address token) external view returns (uint256);

  function strategyEarnedSnapshots(address strategy, uint256 idx) external view returns (uint256);

  function strategyEarnedSnapshotsTime(address strategy, uint256 idx) external view returns (uint256);

  function strategyEarnedSnapshotsLength(address strategy) external view returns (uint256);
}