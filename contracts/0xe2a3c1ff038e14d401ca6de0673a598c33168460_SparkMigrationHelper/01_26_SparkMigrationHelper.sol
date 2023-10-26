// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {IERC20WithPermit} from 'solidity-utils/contracts/oz-common/interfaces/IERC20WithPermit.sol';
import {SafeERC20} from 'solidity-utils/contracts/oz-common/SafeERC20.sol';
import {IPool} from 'aave-v3-core/contracts/interfaces/IPool.sol';

import {AaveV2Ethereum} from 'aave-address-book/AaveV2Ethereum.sol';

import {IWstETH} from 'V2-V3-migration-helpers/src/interfaces/IWstETH.sol';
import {MigrationHelper} from 'V2-V3-migration-helpers/src/contracts/MigrationHelper.sol';

interface PsmLike {
    function gemJoin() external view returns (address);
    function tin() external view returns (uint256);
    function tout() external view returns (uint256);
    function sellGem(address usr, uint256 gemAmt) external;
    function buyGem(address usr, uint256 gemAmt) external;
}

contract SparkMigrationHelper is MigrationHelper {
  using SafeERC20 for IERC20WithPermit;
  using SafeERC20 for IWstETH;

  IERC20WithPermit public constant STETH =
    IERC20WithPermit(0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84);
  IWstETH public constant WSTETH = IWstETH(0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0);
  IPool public constant SPARK_POOL = IPool(0xC13e21B648A5Ee794902342038FF3aDAB66BE987);
  IERC20WithPermit public constant DAI = IERC20WithPermit(0x6B175474E89094C44Da98b954EedeAC495271d0F);
  IERC20WithPermit public constant USDC = IERC20WithPermit(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
  PsmLike public constant PSM = PsmLike(0x89B78CfA322F6C5dE0aBcEecab66Aee45393cC5A);

  constructor() MigrationHelper(SPARK_POOL, AaveV2Ethereum.POOL) {
        STETH.safeApprove(address(WSTETH), type(uint256).max);
        WSTETH.safeApprove(address(SPARK_POOL), type(uint256).max);
        USDC.safeApprove(PSM.gemJoin(), type(uint256).max);
        DAI.safeApprove(address(PSM), type(uint256).max);
  }

  /// @inheritdoc MigrationHelper
  function getMigrationSupply(
    address asset,
    uint256 amount
  ) external view override returns (address, uint256) {
    if (asset == address(STETH)) {
        uint256 wrappedAmount = WSTETH.getWstETHByStETH(amount);

        return (address(WSTETH), wrappedAmount);
    } else if (asset == address(USDC)) {
        uint256 swappedAmount = amount * 1e12;

        return (address(DAI), swappedAmount - swappedAmount * PSM.tin() / 1e18);
    }

    return (asset, amount);
  }

  /// @dev stETH is being wrapped to supply wstETH to the v3 pool
  function _preSupply(address asset, uint256 amount) internal override returns (address, uint256) {
    if (asset == address(STETH)) {
        uint256 wrappedAmount = WSTETH.wrap(amount);

        return (address(WSTETH), wrappedAmount);
    } else if (asset == address(USDC)) {
        PSM.sellGem(address(this), amount);
        uint256 swappedAmount = amount * 1e12;

        return (address(DAI), swappedAmount - swappedAmount * PSM.tin() / 1e18);
    }

    return (asset, amount);
  }

  function _preFlashLoan(address asset, uint256 amount) internal view override returns (address, uint256) {
    if (asset == address(USDC)) {
        uint256 daiAmount = amount * 1e12;

        return (address(DAI), daiAmount + daiAmount * PSM.tout() / 1e18);
    }

    return (asset, amount);
  }

  function _postFlashLoan(address, uint256, address desiredAsset, uint256 desiredAmount) internal override {
    if (desiredAsset == address(USDC)) {
        PSM.buyGem(address(this), desiredAmount);
    }
  }
}