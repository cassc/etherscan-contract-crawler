// SPDX-License-Identifier: AGPL-3.0-only
// Using the same Copyleft License as in the original Repository
pragma solidity ^0.8.0;

import '@balancer-labs/v2-interfaces/contracts/vault/IVault.sol';
import './interfaces/IOracle.sol';
import './interfaces/IOracleValidate.sol';
import '../interfaces/IChainlinkAggregator.sol';
import '../interfaces/IBalancerStablePool.sol';
import {Errors} from '../protocol/libraries/helpers/Errors.sol';
import {Math} from '../dependencies/openzeppelin/contracts/Math.sol';

/**
 * @dev Oracle contract for BALWSTETHWETH LP Token
 */
contract BALWSTETHWETHOracle is IOracle, IOracleValidate {
  IBalancerStablePool private constant BALWSTETHWETH =
    IBalancerStablePool(0x32296969Ef14EB0c6d29669C550D4a0449130230);
  IChainlinkAggregator private constant STETH =
    IChainlinkAggregator(0x86392dC19c0b719886221c78AB11eb8Cf5c52812);
  address private constant BALANCER_VAULT = 0xBA12222222228d8Ba445958a75a0704d566BF2C8;

  /**
   * @dev Get LP Token Price
   */
  function _get() internal view returns (uint256) {
    (, int256 stETHPrice, , uint256 updatedAt, ) = STETH.latestRoundData();
    require(updatedAt > block.timestamp - 1 days, Errors.O_WRONG_PRICE);
    require(stETHPrice > 0, Errors.O_WRONG_PRICE);

    uint256 minValue = Math.min(uint256(stETHPrice), 1e18);

    return (BALWSTETHWETH.getRate() * minValue) / 1e18;
  }

  // Get the latest exchange rate, if no valid (recent) rate is available, return false
  /// @inheritdoc IOracle
  function get() external view override returns (bool, uint256) {
    return (true, _get());
  }

  // Check the last exchange rate without any state changes
  /// @inheritdoc IOracle
  function peek() external view override returns (bool, int256) {
    return (true, int256(_get()));
  }

  // Check the current spot exchange rate without any state changes
  /// @inheritdoc IOracle
  function latestAnswer() external view override returns (int256 rate) {
    return int256(_get());
  }

  // Check the oracle
  /// @inheritdoc IOracleValidate
  function check() external {
    IVault.UserBalanceOp[] memory ops = new IVault.UserBalanceOp[](1);
    ops[0].kind = IVault.UserBalanceOpKind.WITHDRAW_INTERNAL;
    ops[0].sender = address(this);

    IVault(BALANCER_VAULT).manageUserBalance(ops);
  }
}