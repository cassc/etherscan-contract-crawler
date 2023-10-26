// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {PayloadsControllerUtils} from '../payloads/PayloadsControllerUtils.sol';

interface IGovernance_V2_5 {
  /**
   * @notice emitted when gas limit gets updated
   * @param gasLimit the new gas limit
   */
  event GasLimitUpdated(uint256 indexed gasLimit);

  /**
   * @notice method to get the CrossChainController contract address of the currently deployed address
   * @return address of CrossChainController contract
   */
  function CROSS_CHAIN_CONTROLLER() external view returns (address);

  /**
   * @notice method to get the name of the contract
   * @return name string
   */
  function NAME() external view returns (string memory);

  /**
   * @notice method to get the gas limit used on destination chain to execute bridged message
   * @return gas limit
   * @dev this gas limit is assuming that the messages to forward are only payload execution messages
   */
  function GAS_LIMIT() external view returns (uint256);

  /**
   * @notice method to send a payload to execution chain
   * @param payload object with the information needed for execution
   */
  function forwardPayloadForExecution(
    PayloadsControllerUtils.Payload memory payload
  ) external;

  /**
   * @notice method to initialize governance v2.5
   */
  function initialize() external;
}