// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IACLManager, IPoolConfigurator, IPoolDataProvider} from 'aave-address-book/AaveV3.sol';
import {Address} from 'solidity-utils/contracts/oz-common/Address.sol';
import {EngineFlags} from '../v3-config-engine/EngineFlags.sol';
import {IAaveV3ConfigEngine} from '../v3-config-engine/IAaveV3ConfigEngine.sol';

/**
 * @title ICapsPlusRiskSteward
 * @author BGD labs
 * @notice Contract managing caps increasing on an aave v3 pool
 */
interface ICapsPlusRiskSteward {
  /**
   * @notice Stuct storing the last update of a specific cap
   */
  struct Debounce {
    uint40 supplyCapLastUpdated;
    uint40 borrowCapLastUpdated;
  }

  /**
   * @notice The minimum delay that must be respected between updating a specific cap twice
   */
  function MINIMUM_DELAY() external pure returns (uint256);

  /**
   * @notice The config engine used to perform the cap update via delegatecall
   */
  function CONFIG_ENGINE() external view returns (IAaveV3ConfigEngine);

  /**
   * @notice The pool data provider of the POOL the steward controls
   */
  function POOL_DATA_PROVIDER() external view returns (IPoolDataProvider);

  /**
   * @notice The safe controlling the steward
   */
  function RISK_COUNCIL() external view returns (address);

  /**
   * @notice Allows increasing borrow and supply caps accross multiple assets
   * @dev A cap increase is only possible ever 5 days per asset
   * @dev A cap increase is only allowed to increase the cap by 50%
   * @param capUpdates caps to be updated
   */
  function updateCaps(IAaveV3ConfigEngine.CapsUpdate[] calldata capUpdates) external;

  /**
   * @notice Returns the timelock for a specific asset
   * @param asset for which to fetch the timelock
   */
  function getTimelock(address asset) external view returns (Debounce memory);
}