// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IBaseReceiverPortal} from '../../src/contracts/interfaces/IBaseReceiverPortal.sol';

contract MockDestination is IBaseReceiverPortal {
  address public immutable CROSS_CHAIN_CONTROLLER;

  event TestWorked(address indexed originSender, uint256 indexed originChainId, bytes message);

  constructor(address crossChainController) {
    CROSS_CHAIN_CONTROLLER = crossChainController;
  }

  function receiveCrossChainMessage(
    address originSender,
    uint256 originChainId,
    bytes memory message
  ) external {
    require(msg.sender == CROSS_CHAIN_CONTROLLER, 'CALLER_NOT_CROSS_CHAIN_CONTROLLER');
    emit TestWorked(originSender, originChainId, message);
  }
}