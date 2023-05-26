// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/* Interface Imports */
import { IL1CrossDomainMessenger } from "@eth-optimism/contracts/contracts/L1/messaging/IL1CrossDomainMessenger.sol";

/**
 * @title IL1CrossDomainMessengerFast
 */
interface IL1CrossDomainMessengerFast is IL1CrossDomainMessenger {

  /********************
   * Public Functions *
   ********************/

  /**
   * Relays a cross domain message to a contract.
   * @param _target Target contract address.
   * @param _sender Message sender address.
   * @param _message Message to send to the target.
   * @param _messageNonce Nonce for the provided message.
   * @param _proof Inclusion proof for the given message.
   * @param _standardBridgeDepositHash current deposit hash of standard bridges
   * @param _lpDepositHash current deposit hash of LP1
   */
  function relayMessage(
    address _target,
    address _sender,
    bytes memory _message,
    uint256 _messageNonce,
    L2MessageInclusionProof memory _proof,
    bytes32 _standardBridgeDepositHash,
    bytes32 _lpDepositHash
  ) external;

}