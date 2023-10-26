// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Errors library
 * @author BGD Labs
 * @notice Defines the error messages emitted by the different contracts of the Aave CrossChain Infrastructure
 */
library Errors {
  string public constant ETH_TRANSFER_FAILED = '1'; // failed to transfer eth to destination
  string public constant CALLER_IS_NOT_APPROVED_SENDER = '2'; // caller must be an approved message sender
  string public constant ENVELOPE_NOT_PREVIOUSLY_REGISTERED = '3'; // envelope can only be retried if it has been previously registered
  string public constant CURRENT_OR_DESTINATION_CHAIN_ADAPTER_NOT_SET = '4'; // can not enable bridge adapter if the current or destination chain adapter is 0 address
  string public constant CALLER_NOT_APPROVED_BRIDGE = '5'; // caller must be an approved bridge
  string public constant INVALID_VALIDITY_TIMESTAMP = '6'; // new validity timestamp is not correct (< last validity or in the future
  string public constant CALLER_NOT_CCIP_ROUTER = '7'; // caller must be bridge provider contract
  string public constant CCIP_ROUTER_CANT_BE_ADDRESS_0 = '8'; // CCIP bridge adapters needs a CCIP Router
  string public constant RECEIVER_NOT_SET = '9'; // receiver address on destination chain can not be 0
  string public constant DESTINATION_CHAIN_ID_NOT_SUPPORTED = '10'; // destination chain id must be supported by bridge provider
  string public constant NOT_ENOUGH_VALUE_TO_PAY_BRIDGE_FEES = '11'; // cross chain controller does not have enough funds to forward the message
  string public constant REMOTE_NOT_TRUSTED = '12'; // remote address has not been registered as a trusted origin
  string public constant CALLER_NOT_HL_MAILBOX = '13'; // caller must be the HyperLane Mailbox contract
  string public constant NO_BRIDGE_ADAPTERS_FOR_SPECIFIED_CHAIN = '14'; // no bridge adapters are configured for the specified destination chain
  string public constant ONLY_ONE_EMERGENCY_UPDATE_PER_CHAIN = '15'; // only one emergency update is allowed at the time
  string public constant INVALID_REQUIRED_CONFIRMATIONS = '16'; // required confirmations must be less or equal than allowed adapters or bigger or equal than 1
  string public constant DESTINATION_CHAIN_NOT_SAME_AS_CURRENT_CHAIN = '17'; // destination chain must be the same chain as the current chain where contract is deployed
  string public constant INVALID_BRIDGE_ADAPTER = '18'; // a bridge adapter address can not be the 0 address
  string public constant TRANSACTION_NOT_PREVIOUSLY_FORWARDED = '19'; // to retry sending a transaction, it needs to have been previously sent
  string public constant TRANSACTION_RETRY_FAILED = '20'; // transaction retry has failed (no bridge adapters where able to send)
  string public constant BRIDGE_ADAPTERS_SHOULD_BE_UNIQUE = '21'; // can not use the same bridge adapter twice
  string public constant ENVELOPE_NOT_CONFIRMED_OR_DELIVERED = '22'; // to deliver an envelope, this should have been previously confirmed
  string public constant INVALID_BASE_ADAPTER_CROSS_CHAIN_CONTROLLER = '23'; // crossChainController address can not be 0
  string public constant DELEGATE_CALL_FORBIDDEN = '24'; // calling this function during delegatecall is forbidden
  string public constant CALLER_NOT_LZ_ENDPOINT = '25'; // caller must be the LayerZero endpoint contract
  string public constant INVALID_LZ_ENDPOINT = '26'; // LayerZero endpoint can't be 0
  string public constant INVALID_TRUSTED_REMOTE = '27'; // trusted remote endpoint can't be 0
  string public constant INVALID_EMERGENCY_ORACLE = '28'; // emergency oracle can not be 0 because if not, system could not be rescued on emergency
  string public constant NOT_IN_EMERGENCY = '29'; // execution can only happen when in an emergency
  string public constant LINK_TOKEN_CANT_BE_ADDRESS_0 = '30'; // link token address should be set
  string public constant CCIP_MESSAGE_IS_INVALID = '31'; // ccip message is not an accepted message
  string public constant ADAPTER_PAYMENT_SETUP_FAILED = '32'; // adapter payment setup failed
  string public constant CHAIN_ID_MISMATCH = '33'; // the message delivered to/from wrong network
  string public constant CALLER_NOT_OVM = '34'; // the caller must be the optimism ovm contract
  string public constant CALLER_NOT_FX_TUNNEL = '35'; // the caller must be the fx tunnel contract
  string public constant INVALID_SENDER = '36'; // sender can not be address 0
}