// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {IERC20WithPermit} from 'solidity-utils/contracts/oz-common/interfaces/IERC20WithPermit.sol';
import {SafeERC20} from 'solidity-utils/contracts/oz-common/SafeERC20.sol';

import {AaveV2Ethereum} from 'aave-address-book/AaveV2Ethereum.sol';
import {AaveV3Ethereum} from 'aave-address-book/AaveV3Ethereum.sol';

import {IWstETH} from '../interfaces/IWstETH.sol';
import {MigrationHelper} from './MigrationHelper.sol';

/**
 * @title MigrationHelperMainnet
 * @author BGD Labs
 * @dev Contract to migrate positions from Aave v2 to Aave v3 Ethereum Mainnet pools
 *   wraps stETH to wStETH to make it compatible
 */
contract MigrationHelperMainnet is MigrationHelper {
  using SafeERC20 for IERC20WithPermit;
  using SafeERC20 for IWstETH;

  IERC20WithPermit public constant STETH =
    IERC20WithPermit(0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84);
  IWstETH public constant WSTETH = IWstETH(0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0);

  constructor() MigrationHelper(AaveV3Ethereum.POOL, AaveV2Ethereum.POOL) {
    STETH.safeApprove(address(WSTETH), type(uint256).max);
    WSTETH.safeApprove(address(AaveV3Ethereum.POOL), type(uint256).max);
  }

  /// @inheritdoc MigrationHelper
  function getMigrationSupply(
    address asset,
    uint256 amount
  ) external view override returns (address, uint256) {
    if (asset == address(STETH)) {
      uint256 wrappedAmount = WSTETH.getWstETHByStETH(amount);

      return (address(WSTETH), wrappedAmount);
    }

    return (asset, amount);
  }

  /// @dev stETH is being wrapped to supply wstETH to the v3 pool
  function _preSupply(address asset, uint256 amount) internal override returns (address, uint256) {
    if (asset == address(STETH)) {
      uint256 wrappedAmount = WSTETH.wrap(amount);

      return (address(WSTETH), wrappedAmount);
    }

    return (asset, amount);
  }
}