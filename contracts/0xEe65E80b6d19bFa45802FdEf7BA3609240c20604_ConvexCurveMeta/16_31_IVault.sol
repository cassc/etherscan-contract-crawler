// SPDX-License-Identifier: MIT
pragma solidity =0.8.9;

import "@openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";

struct StrategyInfo {
  uint256 activation;
  uint256 lastReport;
  uint256 totalDebt;
  uint256 totalGain;
  uint256 totalLoss;
}

interface IVault is IERC20, IERC20Permit {
  function name() external view returns (string memory);

  function symbol() external view returns (string memory);

  function decimals() external view returns (uint256);

  function activation() external view returns (uint256);

  function rewards() external view returns (address);

  function managementFee() external view returns (uint256);

  function gatekeeper() external view returns (address);

  function governance() external view returns (address);

  function creator() external view returns (address);

  function strategyDataStore() external view returns (address);

  function healthCheck() external view returns (address);

  function emergencyShutdown() external view returns (bool);

  function lockedProfitDegradation() external view returns (uint256);

  function depositLimit() external view returns (uint256);

  function lastReport() external view returns (uint256);

  function lockedProfit() external view returns (uint256);

  function totalDebt() external view returns (uint256);

  function token() external view returns (address);

  function totalAsset() external view returns (uint256);

  function availableDepositLimit() external view returns (uint256);

  function maxAvailableShares() external view returns (uint256);

  function pricePerShare() external view returns (uint256);

  function debtOutstanding(address _strategy) external view returns (uint256);

  function creditAvailable(address _strategy) external view returns (uint256);

  function expectedReturn(address _strategy) external view returns (uint256);

  function strategy(address _strategy) external view returns (StrategyInfo memory);

  function strategyDebtRatio(address _strategy) external view returns (uint256);

  function setRewards(address _rewards) external;

  function setManagementFee(uint256 _managementFee) external;

  function setGatekeeper(address _gatekeeper) external;

  function setStrategyDataStore(address _strategyDataStoreContract) external;

  function setHealthCheck(address _healthCheck) external;

  function setVaultEmergencyShutdown(bool _active) external;

  function setLockedProfileDegradation(uint256 _degradation) external;

  function setDepositLimit(uint256 _limit) external;

  function sweep(address _token, uint256 _amount) external;

  function addStrategy(address _strategy) external returns (bool);

  function migrateStrategy(address _oldVersion, address _newVersion) external returns (bool);

  function revokeStrategy() external;

  /// @notice deposit the given amount into the vault, and return the number of shares
  function deposit(uint256 _amount, address _recipient) external returns (uint256);

  /// @notice burn the given amount of shares from the vault, and return the number of underlying tokens recovered
  function withdraw(
    uint256 _shares,
    address _recipient,
    uint256 _maxLoss
  ) external returns (uint256);

  function report(
    uint256 _gain,
    uint256 _loss,
    uint256 _debtPayment
  ) external returns (uint256);
}

interface IBoostedVault {
  function totalBoostedSupply() external view returns (uint256);

  function boostedBalanceOf(address _user) external view returns (uint256);

  function updateBoostedBalancesForUsers(address[] calldata _users) external;
}