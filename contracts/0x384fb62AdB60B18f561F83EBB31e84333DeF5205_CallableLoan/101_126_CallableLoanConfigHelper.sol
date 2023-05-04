// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import {ConfigOptions} from "../ConfigOptions.sol";
import {IGoldfinchConfig} from "../../../interfaces/IGoldfinchConfig.sol";
import {IERC20UpgradeableWithDec} from "../../../interfaces/IERC20UpgradeableWithDec.sol";
import {IPoolTokens} from "../../../interfaces/IPoolTokens.sol";
import {IGoldfinchFactory} from "../../../interfaces/IGoldfinchFactory.sol";
import {IGo} from "../../../interfaces/IGo.sol";
import {ICurveLP} from "../../../interfaces/ICurveLP.sol";

/**
 * @title ConfigHelper
 * @notice A convenience library for getting easy access to other contracts and constants within the
 *  protocol, through the use of the IGoldfinchConfig contract
 * @author Goldfinch
 */

library CallableLoanConfigHelper {
  function getUSDC(IGoldfinchConfig config) internal view returns (IERC20UpgradeableWithDec) {
    return IERC20UpgradeableWithDec(usdcAddress(config));
  }

  function getPoolTokens(IGoldfinchConfig config) internal view returns (IPoolTokens) {
    return IPoolTokens(poolTokensAddress(config));
  }

  function getGo(IGoldfinchConfig config) internal view returns (IGo) {
    return IGo(goAddress(config));
  }

  function poolTokensAddress(IGoldfinchConfig config) internal view returns (address) {
    return config.getAddress(uint256(ConfigOptions.Addresses.PoolTokens));
  }

  function usdcAddress(IGoldfinchConfig config) internal view returns (address) {
    return config.getAddress(uint256(ConfigOptions.Addresses.USDC));
  }

  function reserveAddress(IGoldfinchConfig config) internal view returns (address) {
    return config.getAddress(uint256(ConfigOptions.Addresses.TreasuryReserve));
  }

  function protocolAdminAddress(IGoldfinchConfig config) internal view returns (address) {
    return config.getAddress(uint256(ConfigOptions.Addresses.ProtocolAdmin));
  }

  function goAddress(IGoldfinchConfig config) internal view returns (address) {
    return config.getAddress(uint256(ConfigOptions.Addresses.Go));
  }

  function getDrawdownPeriodInSeconds(IGoldfinchConfig config) internal view returns (uint256) {
    return config.getNumber(uint256(ConfigOptions.Numbers.DrawdownPeriodInSeconds));
  }

  function getLatenessGracePeriodInDays(IGoldfinchConfig config) internal view returns (uint256) {
    return config.getNumber(uint256(ConfigOptions.Numbers.LatenessGracePeriodInDays));
  }

  function getReserveDenominator(IGoldfinchConfig config) internal view returns (uint256) {
    return config.getNumber(uint256(ConfigOptions.Numbers.ReserveDenominator));
  }

  function getWithdrawFeeDenominator(IGoldfinchConfig config) internal view returns (uint256) {
    return config.getNumber(uint256(ConfigOptions.Numbers.WithdrawFeeDenominator));
  }
}