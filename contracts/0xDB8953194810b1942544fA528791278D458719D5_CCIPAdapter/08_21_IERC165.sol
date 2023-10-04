// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC165 {
  // @dev Should indicate whether the contract implements IAny2EVMMessageReceiver
  // e.g. return interfaceId == type(IAny2EVMMessageReceiver).interfaceId || interfaceId == type(IERC165).interfaceId
  // This allows CCIP to check if ccipReceive is available before calling it.
  // If this returns false or reverts, only tokens are transferred to the receiver.
  // If this returns true, tokens are transferred and ccipReceive is called atomically.
  // Additionally, if the receiver address does not have code associated with
  // it at the time of execution (EXTCODESIZE returns 0), only tokens will be transferred.
  function supportsInterface(bytes4 interfaceId) external view returns (bool);
}