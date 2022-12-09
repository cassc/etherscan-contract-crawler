// SPDX-License-Identifier: Commons-Clause-1.0
//  __  __     _        ___     _
// |  \/  |___| |_ __ _| __|_ _| |__
// | |\/| / -_)  _/ _` | _/ _` | '_ \
// |_|  |_\___|\__\__,_|_|\__,_|_.__/
//
// Launch your crypto game or gamefi project's blockchain
// infrastructure & game APIs fast with https://trymetafab.com

pragma solidity ^0.8.16;

interface ISystem_Delegate_Approver {
  function isDelegateApprovedForSystem(address account, bytes32 systemId, address delegate) external view returns (bool);
  function setDelegateApprovalForSystem(bytes32 systemId, address delegate, bool approved) external;
  function setDelegateApprovalForSystemBySignature(bytes32 systemId, address delegate, bool approved, address signer, uint256 nonce, bytes calldata signature) external;
}