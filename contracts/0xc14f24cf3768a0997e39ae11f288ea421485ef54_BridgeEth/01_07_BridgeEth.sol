// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './BridgeBase.sol';

contract BridgeEth is BridgeBase {
  constructor(address token) BridgeBase(token) {}

  function tokenTransfer(address to, uint amount, uint256 otherChainNonce) external nonReentrant onlyOwner {
    require(processedNonces[otherChainNonce] == false, 'transfer already processed');
    processedNonces[otherChainNonce] = true;
    token.transfer(to, amount);
    emit Transfer(msg.sender, to, amount, block.timestamp, otherChainNonce, Step.Transfer);
  }
}