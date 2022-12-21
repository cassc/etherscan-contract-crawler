// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

abstract contract BEPContext {

  function _msgSender() internal view returns (address payable) {
    return payable(msg.sender);
  }

  function _msgData() internal view returns (bytes memory) {
    this;
    return msg.data;
  }
}