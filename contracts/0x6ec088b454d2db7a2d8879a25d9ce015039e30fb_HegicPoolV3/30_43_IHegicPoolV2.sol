// SPDX-License-Identifier: MIT
pragma solidity >=0.6.8;

import '../IGovernable.sol';
import '../IManageable.sol';
import '../ICollectableDust.sol';

import './IHegicPoolMetadata.sol';
import './IHegicPoolProtocolParameters.sol';

interface IHegicPoolV2 is
  IGovernable,
  IManageable,
  ICollectableDust,
  IHegicPoolMetadata,
  IHegicPoolProtocolParameters {

  // Governance events
  event LotManagerSet(address lotManager);
  event PoolMigrated(address pool, uint256 balance);

  // Protocol events
  event RewardsClaimed(uint256 rewards);
  event LotsBought(uint256 eth, uint256 wbtc);

  // User events
  event Deposited(address depositor, uint256 tokenAmount, uint256 mintedShares);
  event Withdrew(address withdrawer, uint256 burntShares, uint256 withdrawedTokens, uint256 withdrawFee);

  function getToken() external view returns (address);
  function getZToken() external view returns (address);
  function getLotManager() external view returns (address);
  function migrate(address newPool) external;

  // User interactions
  function deposit(uint256 amount) external returns (uint256 shares);
  function depositAll() external returns (uint256 shares);
  function withdraw(uint256 shares) external returns (uint256 underlyingToWithdraw);
  function withdrawAll() external returns (uint256 underlyingToWithdraw);

  // State queries
  function unusedUnderlyingBalance() external view returns (uint256);
  function totalUnderlying() external view returns (uint256);
  function getPricePerFullShare() external view returns (uint256);

  // Lot Managment
  function setLotManager(address lotManager) external;
  function claimRewards() external returns (uint rewards);
  function buyLots(uint256 eth, uint256 wbtc) external returns (bool);
}