// SPDX-License-Identifier: MIT
pragma solidity >0.7.5;
pragma experimental ABIEncoderV2;

/* Interface Imports */
import {IL1CrossDomainMessenger} from './IL1CrossDomainMessenger.sol';

/* Library Imports */
import {Lib_AddressResolver} from '../../libraries/resolver/Lib_AddressResolver.sol';

/**
 * @title L1MultiMessageRelayer
 * @dev The L1 Multi-Message Relayer contract is a gas efficiency optimization which enables the
 * relayer to submit multiple messages in a single transaction to be relayed by the L1 Cross Domain
 * Message Sender.
 *
 * Compiler used: solc
 * Runtime target: EVM
 */
contract L1MultiMessageRelayer is Lib_AddressResolver {
  /***************
   * Structure *
   ***************/

  struct L2ToL1Message {
    address target;
    address sender;
    bytes message;
    uint256 messageNonce;
    IL1CrossDomainMessenger.L2MessageInclusionProof proof;
  }

  /***************
   * Constructor *
   ***************/

  /**
   * @param _libAddressManager Address of the Address Manager.
   */
  constructor(address _libAddressManager)
    Lib_AddressResolver(_libAddressManager)
  {}

  /**********************
   * Function Modifiers *
   **********************/

  modifier onlyBatchRelayer() {
    require(
      msg.sender == resolve('L2BatchMessageRelayer'),
      // solhint-disable-next-line max-line-length
      'L1MultiMessageRelayer: Function can only be called by the L2BatchMessageRelayer'
    );
    _;
  }

  /********************
   * Public Functions *
   ********************/

  /**
   * @notice Forwards multiple cross domain messages to the L1 Cross Domain Messenger for relaying
   * @param _messages An array of L2 to L1 messages
   */
  function batchRelayMessages(L2ToL1Message[] calldata _messages)
    external
    onlyBatchRelayer
  {
    IL1CrossDomainMessenger messenger = IL1CrossDomainMessenger(
      resolve('Proxy__L1CrossDomainMessenger')
    );

    for (uint256 i = 0; i < _messages.length; i++) {
      L2ToL1Message memory message = _messages[i];
      messenger.relayMessage(
        message.target,
        message.sender,
        message.message,
        message.messageNonce,
        message.proof
      );
    }
  }
}