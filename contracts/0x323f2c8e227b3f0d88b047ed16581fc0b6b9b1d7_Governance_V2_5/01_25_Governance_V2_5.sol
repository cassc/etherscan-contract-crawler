// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {Initializable} from 'solidity-utils/contracts/transparent-proxy/Initializable.sol';
import {IGovernance_V2_5, PayloadsControllerUtils} from './IGovernance_V2_5.sol';
import {ICrossChainForwarder} from 'aave-delivery-infrastructure/contracts/interfaces/ICrossChainForwarder.sol';
import {AaveGovernanceV2} from 'aave-address-book/AaveGovernanceV2.sol';
import {GovernanceV3Ethereum} from 'aave-address-book/GovernanceV3Ethereum.sol';
import {Errors} from '../libraries/Errors.sol';

/**
 * @title Governance V2.5
 * @author BGD Labs
 * @notice this contract contains the logic to relay payload execution message to the governance v3 payloadsController
           to execute a payload registered there, on the same or different network.
 */
contract Governance_V2_5 is IGovernance_V2_5, Initializable {
  /// @inheritdoc IGovernance_V2_5
  address public constant CROSS_CHAIN_CONTROLLER =
    GovernanceV3Ethereum.CROSS_CHAIN_CONTROLLER;

  /// @inheritdoc IGovernance_V2_5
  uint256 public constant GAS_LIMIT = 150_000;

  /// @inheritdoc IGovernance_V2_5
  string public constant NAME = 'Aave Governance v2.5';

  /// @dev Thrown when the caller of message forwarding is not the ShortExecutor
  error CallerNotShortExecutor();

  /// @inheritdoc IGovernance_V2_5
  function initialize() external reinitializer(2) {}

  /// @inheritdoc IGovernance_V2_5
  function forwardPayloadForExecution(
    PayloadsControllerUtils.Payload memory payload
  ) external {
    if (msg.sender != AaveGovernanceV2.SHORT_EXECUTOR)
      revert CallerNotShortExecutor();

    require(
      payload.accessLevel == PayloadsControllerUtils.AccessControl.Level_1,
      Errors.G_INVALID_PAYLOAD_ACCESS_LEVEL
    );
    require(
      payload.payloadsController != address(0),
      Errors.G_INVALID_PAYLOADS_CONTROLLER
    );
    require(payload.chain > 0, Errors.G_INVALID_PAYLOAD_CHAIN);

    ICrossChainForwarder(CROSS_CHAIN_CONTROLLER).forwardMessage(
      payload.chain,
      payload.payloadsController,
      GAS_LIMIT,
      abi.encode(
        payload.payloadId,
        payload.accessLevel,
        uint40(block.timestamp)
      )
    );
  }
}