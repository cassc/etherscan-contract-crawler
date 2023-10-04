// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IOwnable} from 'solidity-utils/contracts/transparent-proxy/interfaces/IOwnable.sol';
import {ITransparentUpgradeableProxy} from './dependencies/ITransparentUpgradeableProxy.sol';
import {AaveV3EthereumAssets} from 'aave-address-book/AaveV3Ethereum.sol';
import {AaveMisc} from 'aave-address-book/AaveMisc.sol';
import {GovernanceV3Ethereum} from 'aave-address-book/GovernanceV3Ethereum.sol';
import {IExecutor as IExecutorV2} from './dependencies/IExecutor.sol';
import {IExecutor as IExecutorV3} from 'aave-governance-v3/contracts/payloads/interfaces/IExecutor.sol';
import {IMediator} from './interfaces/IMediator.sol';

/**
 * @title EthLongMovePermissionsPayload
 * @notice Migrate permissions for stkAave and Aave tokens from Long executor to the mediator contract.
 * @author BGD Labs
 **/
contract EthLongMovePermissionsPayload {
  address public immutable MEDIATOR;

  constructor(address mediator) {
    MEDIATOR = mediator;
  }

  function execute() external {
    // move aave token proxy admin owner from Long Executor to ProxyAdminLong
    ITransparentUpgradeableProxy(payable(AaveV3EthereumAssets.AAVE_UNDERLYING)).changeAdmin(
      AaveMisc.PROXY_ADMIN_ETHEREUM_LONG
    );

    // proxy admin
    IOwnable(AaveMisc.PROXY_ADMIN_ETHEREUM_LONG).transferOwnership(address(MEDIATOR));

    // set the new executor as the pending admin
    IExecutorV2(address(this)).setPendingAdmin(address(GovernanceV3Ethereum.EXECUTOR_LVL_2));

    // new executor - change owner to the mediator contract
    IOwnable(GovernanceV3Ethereum.EXECUTOR_LVL_2).transferOwnership(address(MEDIATOR));

    // set the overdue date for the migration
    IMediator(MEDIATOR).setOverdueDate();
  }
}