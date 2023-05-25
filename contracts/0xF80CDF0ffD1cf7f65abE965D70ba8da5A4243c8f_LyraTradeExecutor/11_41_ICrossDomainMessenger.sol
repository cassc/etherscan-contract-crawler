// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

/**
 * @title ICrossDomainMessenger
 */
interface ICrossDomainMessenger {
    /**********
     * Events *
     **********/

    event SentMessage(bytes message);
    event RelayedMessage(bytes32 msgHash);
    event FailedRelayedMessage(bytes32 msgHash);

    event TransactionEnqueued(
        address indexed _l1TxOrigin,
        address indexed _target,
        uint256 _gasLimit,
        bytes _data,
        uint256 indexed _queueIndex,
        uint256 _timestamp
    );

    event QueueBatchAppended(
        uint256 _startingQueueIndex,
        uint256 _numQueueElements,
        uint256 _totalElements
    );

    event SequencerBatchAppended(
        uint256 _startingQueueIndex,
        uint256 _numQueueElements,
        uint256 _totalElements
    );

    event TransactionBatchAppended(
        uint256 indexed _batchIndex,
        bytes32 _batchRoot,
        uint256 _batchSize,
        uint256 _prevTotalElements,
        bytes _extraData
    );

    /********************
     * View Functions *
     ********************/

    function receivedMessages(bytes32 messageHash) external view returns (bool);

    function sentMessages(bytes32 messageHash) external view returns (bool);

    function targetMessengerAddress() external view returns (address);

    function messageNonce() external view returns (uint256);

    function xDomainMessageSender() external view returns (address);

    /********************
     * Public Functions *
     ********************/

    /**
     * Sets the target messenger address.
     * @param _targetMessengerAddress New messenger address.
     */
    function setTargetMessengerAddress(address _targetMessengerAddress)
        external;

    /**
     * Sends a cross domain message to the target messenger.
     * @param _target Target contract address.
     * @param _message Message to send to the target.
     * @param _gasLimit Gas limit for the provided message.
     */
    function sendMessage(
        address _target,
        bytes memory _message,
        uint32 _gasLimit
    ) external;
}