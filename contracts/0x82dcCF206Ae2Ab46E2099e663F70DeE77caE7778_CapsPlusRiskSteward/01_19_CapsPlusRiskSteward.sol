// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IACLManager, IPoolConfigurator, IPoolDataProvider} from 'aave-address-book/AaveV3.sol';
import {Address} from 'solidity-utils/contracts/oz-common/Address.sol';
import {EngineFlags} from '../v3-config-engine/EngineFlags.sol';
import {IAaveV3ConfigEngine} from '../v3-config-engine/IAaveV3ConfigEngine.sol';
import {ICapsPlusRiskSteward} from './ICapsPlusRiskSteward.sol';

/**
 * @title CapsPlusRiskStewardErrors
 * @author BGD labs
 * @notice Library with all the potential errors to be thrown by the steward
 */
library CapsPlusRiskStewardErrors {
  /**
   * @notice Only the permissioned council is allowed to call methods on the steward.
   */
  string public constant INVALID_CALLER = 'INVALID_CALLER';
  /**
   * @notice The steward only allows cap increases.
   */
  string public constant NOT_STRICTLY_HIGHER = 'NOT_STRICTLY_HIGHER';
  /**
   * @notice A single cap can only be increased once every 5 days
   */
  string public constant DEBOUNCE_NOT_RESPECTED = 'DEBOUNCE_NOT_RESPECTED';
  /**
   * @notice A single cap increase must not increase the cap by more than 100%
   */
  string public constant UPDATE_ABOVE_MAX = 'UPDATE_ABOVE_MAX';
  /**
   * @notice There must be at least one cap update per execution
   */
  string public constant NO_ZERO_UPDATES = 'NO_ZERO_UPDATES';
  /**
   * @notice The steward does allow updates of caps, but not the initialization of non existing caps.
   */
  string public constant NO_CAP_INITIALIZE = 'NO_CAP_INITIALIZE';
}

/**
 * @title CapsPlusRiskSteward
 * @author BGD labs
 * @notice Contract managing caps increasing on an aave v3 pool
 */
contract CapsPlusRiskSteward is ICapsPlusRiskSteward {
  using Address for address;

  /// @inheritdoc ICapsPlusRiskSteward
  uint256 public constant MINIMUM_DELAY = 5 days;

  /// @inheritdoc ICapsPlusRiskSteward
  IAaveV3ConfigEngine public immutable CONFIG_ENGINE;

  /// @inheritdoc ICapsPlusRiskSteward
  IPoolDataProvider public immutable POOL_DATA_PROVIDER;

  /// @inheritdoc ICapsPlusRiskSteward
  address public immutable RISK_COUNCIL;

  mapping(address => Debounce) internal _timelocks;

  /**
   * @dev Modifier preventing anyone, but the council to update caps.
   */
  modifier onlyRiskCouncil() {
    require(RISK_COUNCIL == msg.sender, CapsPlusRiskStewardErrors.INVALID_CALLER);
    _;
  }

  /**
   * @param poolDataProvider The pool data provider of the pool to be controlled by the steward
   * @param engine the config engine to be used by the steward
   * @param riskCouncil the safe address of the council being able to interact with the steward
   */
  constructor(IPoolDataProvider poolDataProvider, IAaveV3ConfigEngine engine, address riskCouncil) {
    POOL_DATA_PROVIDER = poolDataProvider;
    RISK_COUNCIL = riskCouncil;
    CONFIG_ENGINE = engine;
  }

  /// @inheritdoc ICapsPlusRiskSteward
  function updateCaps(
    IAaveV3ConfigEngine.CapsUpdate[] calldata capUpdates
  ) external onlyRiskCouncil {
    require(capUpdates.length > 0, CapsPlusRiskStewardErrors.NO_ZERO_UPDATES);
    for (uint256 i = 0; i < capUpdates.length; i++) {
      (uint256 currentBorrowCap, uint256 currentSupplyCap) = POOL_DATA_PROVIDER.getReserveCaps(
        capUpdates[i].asset
      );
      Debounce storage debounce = _timelocks[capUpdates[i].asset];
      if (capUpdates[i].supplyCap != EngineFlags.KEEP_CURRENT) {
        _validateCapIncrease(
          currentSupplyCap,
          capUpdates[i].supplyCap,
          debounce.supplyCapLastUpdated
        );
        debounce.supplyCapLastUpdated = uint40(block.timestamp);
      }
      if (capUpdates[i].borrowCap != EngineFlags.KEEP_CURRENT) {
        _validateCapIncrease(
          currentBorrowCap,
          capUpdates[i].borrowCap,
          debounce.borrowCapLastUpdated
        );
        debounce.borrowCapLastUpdated = uint40(block.timestamp);
      }
    }
    address(CONFIG_ENGINE).functionDelegateCall(
      abi.encodeWithSelector(CONFIG_ENGINE.updateCaps.selector, capUpdates)
    );
  }

  /// @inheritdoc ICapsPlusRiskSteward
  function getTimelock(address asset) external view returns (Debounce memory) {
    return _timelocks[asset];
  }

  /**
   * @notice A cap increase is valid, when it:
   * - respects the debounce duration (5 day pause between updates must be respected)
   * - the asset already had a cap (the steward can increase caps, but not initialize them)
   * - the increase increases by a maximum of 100% of the current cap
   * @param currentCap the current cap
   * @param newCap the new cap
   * @param lastUpdated the timestamp of the last update
   */
  function _validateCapIncrease(
    uint256 currentCap,
    uint256 newCap,
    uint40 lastUpdated
  ) internal view {
    require(currentCap != 0, CapsPlusRiskStewardErrors.NO_CAP_INITIALIZE);
    require(newCap > currentCap, CapsPlusRiskStewardErrors.NOT_STRICTLY_HIGHER);
    require(
      block.timestamp - lastUpdated > MINIMUM_DELAY,
      CapsPlusRiskStewardErrors.DEBOUNCE_NOT_RESPECTED
    );
    require(
      _capsIncreaseWithinAllowedRange(currentCap, newCap),
      CapsPlusRiskStewardErrors.UPDATE_ABOVE_MAX
    );
  }

  /**
   * @notice Ensures the cap increase is within the allowed range.
   * @param from current cap
   * @param to new cap
   * @return bool true, if difference is within the max 100% increase window
   */
  function _capsIncreaseWithinAllowedRange(uint256 from, uint256 to) internal pure returns (bool) {
    return to - from <= from;
  }
}