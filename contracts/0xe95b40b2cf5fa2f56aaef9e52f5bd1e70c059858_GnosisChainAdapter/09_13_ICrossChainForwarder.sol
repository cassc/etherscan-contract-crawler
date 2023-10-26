// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import {Transaction, Envelope} from '../libs/EncodingUtils.sol';

/**
 * @title ICrossChainForwarder
 * @author BGD Labs
 * @notice interface containing the objects, events and methods definitions of the CrossChainForwarder contract
 */
interface ICrossChainForwarder {
  /**
   * @notice object storing the connected pair of bridge adapters, on current and destination chain
   * @param destinationBridgeAdapter address of the bridge adapter on the destination chain
   * @param currentChainBridgeAdapter address of the bridge adapter deployed on current network
   */
  struct ChainIdBridgeConfig {
    address destinationBridgeAdapter;
    address currentChainBridgeAdapter;
  }

  /**
   * @notice object with the necessary information to remove bridge adapters
   * @param bridgeAdapter address of the bridge adapter to remove
   * @param chainIds array of chain ids where the bridge adapter connects
   */
  struct BridgeAdapterToDisable {
    address bridgeAdapter;
    uint256[] chainIds;
  }

  /**
   * @notice object storing the pair bridgeAdapter (current deployed chain) destination chain bridge adapter configuration
   * @param currentChainBridgeAdapter address of the bridge adapter deployed on current chain
   * @param destinationBridgeAdapter address of the bridge adapter on the destination chain
   * @param destinationChainId id of the destination chain using our own nomenclature
   */
  struct ForwarderBridgeAdapterConfigInput {
    address currentChainBridgeAdapter;
    address destinationBridgeAdapter;
    uint256 destinationChainId;
  }

  /**
   * @notice emitted when a transaction is successfully forwarded through a bridge adapter
   * @param envelopeId internal id of the envelope
   * @param envelope the Envelope type data
   */
  event EnvelopeRegistered(bytes32 indexed envelopeId, Envelope envelope);

  /**
   * @notice emitted when a transaction forwarding is attempted through a bridge adapter
   * @param transactionId id of the forwarded transaction
   * @param envelopeId internal id of the envelope
   * @param encodedTransaction object intended to be bridged
   * @param destinationChainId id of the destination chain in our notation
   * @param bridgeAdapter address of the bridge adapter that failed (deployed on current network)
   * @param destinationBridgeAdapter address of the connected bridge adapter on destination chain
   * @param adapterSuccessful adapter was able to forward the message
   * @param returnData bytes with error information
   */
  event TransactionForwardingAttempted(
    bytes32 transactionId,
    bytes32 indexed envelopeId,
    bytes encodedTransaction,
    uint256 destinationChainId,
    address indexed bridgeAdapter,
    address destinationBridgeAdapter,
    bool indexed adapterSuccessful,
    bytes returnData
  );

  /**
   * @notice emitted when a bridge adapter has been added to the allowed list
   * @param destinationChainId id of the destination chain in our notation
   * @param bridgeAdapter address of the bridge adapter added (deployed on current network)
   * @param destinationBridgeAdapter address of the connected bridge adapter on destination chain
   * @param allowed boolean indicating if the bridge adapter is allowed or disallowed
   */
  event BridgeAdapterUpdated(
    uint256 indexed destinationChainId,
    address indexed bridgeAdapter,
    address destinationBridgeAdapter,
    bool indexed allowed
  );

  /**
   * @notice emitted when a sender has been updated
   * @param sender address of the updated sender
   * @param isApproved boolean that indicates if the sender has been approved or removed
   */
  event SenderUpdated(address indexed sender, bool indexed isApproved);

  /**
   * @notice method to get the current valid envelope nonce
   * @return the current valid envelope nonce
   */
  function getCurrentEnvelopeNonce() external view returns (uint256);

  /**
   * @notice method to get the current valid transaction nonce
   * @return the current valid transaction nonce
   */
  function getCurrentTransactionNonce() external view returns (uint256);

  /**
   * @notice method to check if a envelope has been previously forwarded.
   * @param envelope the Envelope type data
   * @return boolean indicating if the envelope has been registered
   */
  function isEnvelopeRegistered(Envelope memory envelope) external view returns (bool);

  /**
   * @notice method to check if a envelope has been previously forwarded.
   * @param envelopeId the hashed id of the envelope
   * @return boolean indicating if the envelope has been registered
   */
  function isEnvelopeRegistered(bytes32 envelopeId) external view returns (bool);

  /**
   * @notice method to get if a transaction has been forwarded
   * @param transaction the Transaction type data
   * @return flag indicating if a transaction has been forwarded
   */
  function isTransactionForwarded(Transaction memory transaction) external view returns (bool);

  /**
   * @notice method to get if a transaction has been forwarded
   * @param transactionId hashed id of the transaction
   * @return flag indicating if a transaction has been forwarded
   */
  function isTransactionForwarded(bytes32 transactionId) external view returns (bool);

  /**
   * @notice method called to initiate message forwarding to other networks.
   * @param destinationChainId id of the destination chain where the message needs to be bridged
   * @param destination address where the message is intended for
   * @param gasLimit gas cost on receiving side of the message
   * @param message bytes that need to be bridged
   * @return internal id of the envelope and transaction
   */
  function forwardMessage(
    uint256 destinationChainId,
    address destination,
    uint256 gasLimit,
    bytes memory message
  ) external returns (bytes32, bytes32);

  /**
   * @notice method called to re forward a previously sent envelope.
   * @param envelope the Envelope type data
   * @param gasLimit gas cost on receiving side of the message
   * @return the transaction id that has the retried envelope
   * @dev This method will send an existing Envelope using a new Transaction.
   * @dev This method should be used when the intention is to send the Envelope as if it was a new message. This way on
          the Receiver side it will start from 0 to count for the required confirmations. (usual use case would be for
          when an envelope has been invalidated on Receiver side, and needs to be retried as a new message)
   */
  function retryEnvelope(Envelope memory envelope, uint256 gasLimit) external returns (bytes32);

  /**
   * @notice method to retry forwarding an already forwarded transaction
   * @param encodedTransaction the encoded Transaction data
   * @param gasLimit limit of gas to spend on forwarding per bridge
   * @param bridgeAdaptersToRetry list of bridge adapters to be used for the transaction forwarding retry
   * @dev This method will send an existing Transaction with its Envelope to the specified adapters.
   * @dev Should be used when some of the bridges on the initial forwarding did not work (out of gas),
          and we want the Transaction with Envelope to still account for the required confirmations on the Receiver side
   */
  function retryTransaction(
    bytes memory encodedTransaction,
    uint256 gasLimit,
    address[] memory bridgeAdaptersToRetry
  ) external;

  /**
   * @notice method to enable bridge adapters
   * @param bridgeAdapters array of new bridge adapter configurations
   */
  function enableBridgeAdapters(ForwarderBridgeAdapterConfigInput[] memory bridgeAdapters) external;

  /**
   * @notice method to disable bridge adapters
   * @param bridgeAdapters array of bridge adapter addresses to disable
   */
  function disableBridgeAdapters(BridgeAdapterToDisable[] memory bridgeAdapters) external;

  /**
   * @notice method to remove sender addresses
   * @param senders list of addresses to remove
   */
  function removeSenders(address[] memory senders) external;

  /**
   * @notice method to approve new sender addresses
   * @param senders list of addresses to approve
   */
  function approveSenders(address[] memory senders) external;

  /**
   * @notice method to get all the forwarder bridge adapters of a chain
   * @param chainId id of the chain we want to get the adapters from
   * @return an array of chain configurations where the bridge adapter can communicate
   */
  function getForwarderBridgeAdaptersByChain(
    uint256 chainId
  ) external view returns (ChainIdBridgeConfig[] memory);

  /**
   * @notice method to get if a sender is approved
   * @param sender address that we want to check if approved
   * @return boolean indicating if the address has been approved as sender
   */
  function isSenderApproved(address sender) external view returns (bool);
}