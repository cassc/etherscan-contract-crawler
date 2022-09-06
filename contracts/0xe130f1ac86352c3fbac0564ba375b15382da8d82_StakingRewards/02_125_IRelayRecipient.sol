// SPDX-License-Identifier:MIT

/*
  Vendored from @opengsn/[email protected]
  Reason:
   * @opengsn/gsn is deprecated and does not compile for node 16. Replacement package
   * has incompatable changes.
  Alterations:
   * change solidity version from 0.6.2 -> 0.6.12 to match our contracts
*/

pragma solidity 0.6.12;

/**
 * a contract must implement this interface in order to support relayed transaction.
 * It is better to inherit the BaseRelayRecipient as its implementation.
 */
abstract contract IRelayRecipient {
  /**
   * return if the forwarder is trusted to forward relayed transactions to us.
   * the forwarder is required to verify the sender's signature, and verify
   * the call is not a replay.
   */
  function isTrustedForwarder(address forwarder) public view virtual returns (bool);

  /**
   * return the sender of this call.
   * if the call came through our trusted forwarder, then the real sender is appended as the last 20 bytes
   * of the msg.data.
   * otherwise, return `msg.sender`
   * should be used in the contract anywhere instead of msg.sender
   */
  function _msgSender() internal view virtual returns (address payable);

  /**
   * return the msg.data of this call.
   * if the call came through our trusted forwarder, then the real sender was appended as the last 20 bytes
   * of the msg.data - so this method will strip those 20 bytes off.
   * otherwise, return `msg.data`
   * should be used in the contract instead of msg.data, where the difference matters (e.g. when explicitly
   * signing or hashing the
   */
  function _msgData() internal view virtual returns (bytes memory);

  function versionRecipient() external view virtual returns (string memory);
}