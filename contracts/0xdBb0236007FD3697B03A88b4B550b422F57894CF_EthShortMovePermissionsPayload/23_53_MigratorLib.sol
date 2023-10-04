// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IOwnable} from 'solidity-utils/contracts/transparent-proxy/interfaces/IOwnable.sol';
import {IERC20} from 'solidity-utils/contracts/oz-common/interfaces/IERC20.sol';
import {ILendingPoolAddressesProvider, IAaveOracle, ILendingRateOracle} from 'aave-address-book/AaveV2.sol';
import {IACLManager, IPoolAddressesProvider, IPool} from 'aave-address-book/AaveV3.sol';
import {ICollector} from 'aave-address-book/common/ICollector.sol';
import {IWrappedTokenGateway} from './dependencies/IWrappedTokenGateway.sol';

/**
 * @title MigratorLib
 * @notice Library to migrate permissions from governance V2 to V3.
 * @author BGD Labs
 **/
library MigratorLib {
  function migrateV2PoolPermissions(
    address executor,
    ILendingPoolAddressesProvider poolAddressesProvider,
    IAaveOracle oracle, // per chain
    ILendingRateOracle lendingRateOracle, // per chain
    address wETHGateway,
    address poolAddressesProviderRegistry,
    address swapCollateralAdapter,
    address repayWithCollateralAdapter,
    address debtSwapAdapter
  ) internal {
    poolAddressesProvider.setPoolAdmin(executor);
    IOwnable(address(poolAddressesProvider)).transferOwnership(executor);
    IOwnable(wETHGateway).transferOwnership(executor);

    // this components are common across different pools, and maybe already transfered
    if (IOwnable(address(oracle)).owner() == address(this)) {
      IOwnable(address(oracle)).transferOwnership(executor);
    }
    if (IOwnable(address(lendingRateOracle)).owner() == address(this)) {
      IOwnable(address(lendingRateOracle)).transferOwnership(executor);
    }
    if (IOwnable(address(poolAddressesProviderRegistry)).owner() == address(this)) {
      IOwnable(poolAddressesProviderRegistry).transferOwnership(executor);
    }

    if (swapCollateralAdapter != address(0)) {
      IOwnable(swapCollateralAdapter).transferOwnership(executor);
    }

    if (repayWithCollateralAdapter != address(0)) {
      IOwnable(repayWithCollateralAdapter).transferOwnership(executor);
    }

    if (debtSwapAdapter != address(0)) {
      IOwnable(debtSwapAdapter).transferOwnership(executor);
    }
  }

  function migrateV3PoolPermissions(
    address executor,
    IACLManager aclManager,
    IPoolAddressesProvider poolAddressesProvider,
    address emissionManager,
    address poolAddressesProviderRegistry,
    ICollector collector,
    address proxyAdmin,
    address wETHGateway,
    address swapCollateralAdapter,
    address repayWithCollateralAdapter,
    address withdrawSwapAdapter,
    address debtSwapAdapter
  ) internal {
    // grant pool admin role
    aclManager.grantRole(aclManager.POOL_ADMIN_ROLE(), executor);
    aclManager.renounceRole(aclManager.POOL_ADMIN_ROLE(), address(this));

    // grant default admin role
    aclManager.grantRole(aclManager.DEFAULT_ADMIN_ROLE(), executor);
    aclManager.renounceRole(aclManager.DEFAULT_ADMIN_ROLE(), address(this));

    poolAddressesProvider.setACLAdmin(executor);

    // transfer pool address provider ownership
    IOwnable(address(poolAddressesProvider)).transferOwnership(executor);

    IOwnable(emissionManager).transferOwnership(executor);

    IOwnable(poolAddressesProviderRegistry).transferOwnership(executor);

    collector.setFundsAdmin(executor);

    IOwnable(proxyAdmin).transferOwnership(executor);

    // Optional components
    if (wETHGateway != address(0)) {
      IOwnable(wETHGateway).transferOwnership(executor);
    }

    if (swapCollateralAdapter != address(0)) {
      IOwnable(swapCollateralAdapter).transferOwnership(executor);
    }

    if (repayWithCollateralAdapter != address(0)) {
      IOwnable(repayWithCollateralAdapter).transferOwnership(executor);
    }

    if (withdrawSwapAdapter != address(0)) {
      IOwnable(withdrawSwapAdapter).transferOwnership(executor);
    }

    if (debtSwapAdapter != address(0)) {
      IOwnable(debtSwapAdapter).transferOwnership(executor);
    }
  }

  function fundCrosschainControllerNative(
    ICollector collector,
    address crosschainController,
    address nativeAToken,
    uint256 nativeAmount,
    address wethGateway
  ) internal {
    // transfer native a token
    collector.transfer(nativeAToken, address(this), nativeAmount);

    IERC20(nativeAToken).approve(wethGateway, nativeAmount);

    // withdraw native
    IWrappedTokenGateway(wethGateway).withdrawETH(
      address(this),
      nativeAmount,
      crosschainController
    );
  }

  function fetchLinkTokens(
    ICollector collector,
    address pool,
    address linkToken,
    address linkAToken,
    uint256 linkAmount,
    bool withdrawALink
  ) internal {
    if (withdrawALink) {
      // transfer aLINK token from the treasury to the current address
      collector.transfer(linkAToken, address(this), linkAmount);

      // withdraw aLINK from the aave pool and receive LINK
      IPool(pool).withdraw(linkToken, linkAmount, address(this));
    } else {
      collector.transfer(linkToken, address(this), linkAmount);
    }
  }
}