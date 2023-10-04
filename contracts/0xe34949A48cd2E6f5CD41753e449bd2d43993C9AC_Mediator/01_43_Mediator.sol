// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IOwnable} from 'solidity-utils/contracts/transparent-proxy/interfaces/IOwnable.sol';
import {ITransparentUpgradeableProxy} from './dependencies/ITransparentUpgradeableProxy.sol';
import {IProxyAdmin} from './dependencies/IProxyAdmin.sol';
import {AaveGovernanceV2} from 'aave-address-book/AaveGovernanceV2.sol';
import {GovernanceV3Ethereum} from 'aave-address-book/GovernanceV3Ethereum.sol';
import {AaveV2Ethereum} from 'aave-address-book/AaveV2Ethereum.sol';
import {AaveV3EthereumAssets} from 'aave-address-book/AaveV3Ethereum.sol';
import {AaveMisc} from 'aave-address-book/AaveMisc.sol';
import {AaveSafetyModule} from 'aave-address-book/AaveSafetyModule.sol';
import {IExecutor as IExecutorV3} from 'aave-governance-v3/contracts/payloads/interfaces/IExecutor.sol';
import {IMediator} from './interfaces/IMediator.sol';

/**
 * @title Mediator
 * @notice Accept the stkAave and aave token permissions from the Long executor to transfer
 * them to the new v3 executor level 2 for the synchronization of the migration from governance v2 to v3.
 * @author BGD Labs
 **/
contract Mediator is IMediator {
  bool private _isCancelled;
  uint256 private _overdueDate;

  uint256 public constant OVERDUE = 172800; // 2 days

  address public constant AAVE_IMPL = 0x5D4Aa78B08Bc7C530e21bf7447988b1Be7991322;
  address public constant STK_AAVE_IMPL = 0x27FADCFf20d7A97D3AdBB3a6856CB6DedF2d2132;

  /**
   * @dev Throws if the caller is not the short executor.
   */
  modifier onlyShortExecutor() {
    if (msg.sender != AaveGovernanceV2.SHORT_EXECUTOR) {
      revert InvalidCaller();
    }
    _;
  }

  /**
   * @dev Throws if the caller is not the long executor.
   */
  modifier onlyLongExecutor() {
    if (msg.sender != AaveGovernanceV2.LONG_EXECUTOR) {
      revert InvalidCaller();
    }
    _;
  }

  function getIsCancelled() external view returns (bool) {
    return _isCancelled;
  }

  function setOverdueDate() external onlyLongExecutor {
    _overdueDate = block.timestamp + OVERDUE;

    emit OverdueDateUpdated(_overdueDate);
  }

  function execute() external onlyShortExecutor {
    if (_isCancelled) {
      revert ProposalIsCancelled();
    }

    if (_overdueDate == 0) {
      revert LongProposalNotExecuted();
    }

    // UPDATE TOKENS

    // update Aave token impl
    IProxyAdmin(AaveMisc.PROXY_ADMIN_ETHEREUM_LONG).upgradeAndCall(
      ITransparentUpgradeableProxy(payable(AaveV3EthereumAssets.AAVE_UNDERLYING)),
      address(AAVE_IMPL),
      abi.encodeWithSignature('initialize()')
    );

    // upgrade stk aave
    IProxyAdmin(AaveMisc.PROXY_ADMIN_ETHEREUM_LONG).upgradeAndCall(
      ITransparentUpgradeableProxy(payable(AaveSafetyModule.STK_AAVE)),
      address(STK_AAVE_IMPL),
      abi.encodeWithSignature('initialize()')
    );

    // PROXY ADMIN
    IOwnable(AaveMisc.PROXY_ADMIN_ETHEREUM_LONG).transferOwnership(
      address(GovernanceV3Ethereum.EXECUTOR_LVL_2)
    );

    // new executor - call execute payload to accept new permissions
    IExecutorV3(GovernanceV3Ethereum.EXECUTOR_LVL_2).executeTransaction(
      AaveGovernanceV2.LONG_EXECUTOR,
      0,
      'acceptAdmin()',
      bytes(''),
      false
    );

    // new executor - change owner to payload controller
    IOwnable(GovernanceV3Ethereum.EXECUTOR_LVL_2).transferOwnership(
      address(GovernanceV3Ethereum.PAYLOADS_CONTROLLER)
    );

    emit Executed();
  }

  /**
   * @dev Will prevent the execution of the migration
   */
  function cancel() external {
    if (msg.sender != AaveV2Ethereum.EMERGENCY_ADMIN && block.timestamp < _overdueDate) {
      revert NotGuardianOrNotOverdue();
    }

    if (_isCancelled) {
      revert ProposalIsCancelled();
    }

    // proxy admin
    IOwnable(AaveMisc.PROXY_ADMIN_ETHEREUM_LONG).transferOwnership(
      address(AaveGovernanceV2.LONG_EXECUTOR)
    );

    // new executor - change owner from the mediator contract to LongExecutor
    IOwnable(GovernanceV3Ethereum.EXECUTOR_LVL_2).transferOwnership(
      address(AaveGovernanceV2.LONG_EXECUTOR)
    );

    _isCancelled = true;
    emit Cancelled();
  }
}