// SPDX-License-Identifier: MIT
pragma solidity >0.5.0 <0.9.0;

/* Library Imports */
import { Lib_OVMCodec } from "../../libraries/codec/Lib_OVMCodec.sol";

/* Interface Imports */
import { IChainStorageContainer } from "./IChainStorageContainer.sol";

/**
 * @title ICanonicalTransactionChain
 */
interface ICanonicalTransactionChain {
    /**********
     * Events *
     **********/
    event QueueGlobalMetadataSet(
        address _sender,
        uint256 _chainId,
        bytes27 _globalMetadata
    );
    
    event QueuePushed(
        address _sender,
        uint256 _chainId,
        Lib_OVMCodec.QueueElement _object
    );

    event QueueSetted(
        address _sender,
        uint256 _chainId,
        uint256 _index,
        Lib_OVMCodec.QueueElement _object
    );

    event QueueElementDeleted(
        address _sender,
        uint256 _chainId,
        uint256 _index,
        bytes27 _globalMetadata
    );

    event BatchesGlobalMetadataSet(
        address _sender,
        uint256 _chainId,
        bytes27 _globalMetadata
    );
    
    event BatchPushed(
        address _sender,
        uint256 _chainId,
        bytes32 _object,
        bytes27 _globalMetadata
    );

    event BatchSetted(
        address _sender,
        uint256 _chainId,
        uint256 _index,
        bytes32 _object
    );

    event BatchElementDeleted(
        address _sender,
        uint256 _chainId,
        uint256 _index,
        bytes27 _globalMetadata
    );

    event L2GasParamsUpdated(
        uint256 l2GasDiscountDivisor,
        uint256 enqueueGasCost,
        uint256 enqueueL2GasPrepaid
    );

    event TransactionEnqueued(
        uint256 _chainId,
        address indexed _l1TxOrigin,
        address indexed _target,
        uint256 _gasLimit,
        bytes _data,
        uint256 indexed _queueIndex,
        uint256 _timestamp
    );

    event QueueBatchAppended(
        uint256 _chainId,
        uint256 _startingQueueIndex,
        uint256 _numQueueElements,
        uint256 _totalElements
    );

    event SequencerBatchAppended(
        uint256 _chainId,
        uint256 _startingQueueIndex,
        uint256 _numQueueElements,
        uint256 _totalElements
    );

    event TransactionBatchAppended(
        uint256 _chainId,
        uint256 indexed _batchIndex,
        bytes32 _batchRoot,
        uint256 _batchSize,
        uint256 _prevTotalElements,
        bytes _extraData
    );

    /***********
     * Structs *
     ***********/

    struct BatchContext {
        uint256 numSequencedTransactions;
        uint256 numSubsequentQueueTransactions;
        uint256 timestamp;
        uint256 blockNumber;
    }

    /*******************************
     * Authorized Setter Functions *
     *******************************/

    /**
     * Allows the Burn Admin to update the parameters which determine the amount of gas to burn.
     * The value of enqueueL2GasPrepaid is immediately updated as well.
     */
    function setGasParams(uint256 _l2GasDiscountDivisor, uint256 _enqueueGasCost) external;

    /********************
     * Public Functions *
     ********************/

    /**
     * Accesses the batch storage container.
     * @return Reference to the batch storage container.
     */
    function batches() external view returns (IChainStorageContainer);

    /**
     * Accesses the queue storage container.
     * @return Reference to the queue storage container.
     */
    function queue() external view returns (IChainStorageContainer);

    /**
     * Retrieves the total number of elements submitted.
     * @return _totalElements Total submitted elements.
     */
    function getTotalElements() external view returns (uint256 _totalElements);

    /**
     * Retrieves the total number of batches submitted.
     * @return _totalBatches Total submitted batches.
     */
    function getTotalBatches() external view returns (uint256 _totalBatches);

    /**
     * Returns the index of the next element to be enqueued.
     * @return Index for the next queue element.
     */
    function getNextQueueIndex() external view returns (uint40);

    /**
     * Gets the queue element at a particular index.
     * @param _index Index of the queue element to access.
     * @return _element Queue element at the given index.
     */
    function getQueueElement(uint256 _index)
        external
        view
        returns (Lib_OVMCodec.QueueElement memory _element);

    /**
     * Returns the timestamp of the last transaction.
     * @return Timestamp for the last transaction.
     */
    function getLastTimestamp() external view returns (uint40);

    /**
     * Returns the blocknumber of the last transaction.
     * @return Blocknumber for the last transaction.
     */
    function getLastBlockNumber() external view returns (uint40);

    /**
     * Get the number of queue elements which have not yet been included.
     * @return Number of pending queue elements.
     */
    function getNumPendingQueueElements() external view returns (uint40);

    /**
     * Retrieves the length of the queue, including
     * both pending and canonical transactions.
     * @return Length of the queue.
     */
    function getQueueLength() external view returns (uint40);

    /**
     * Adds a transaction to the queue.
     * @param _target Target contract to send the transaction to.
     * @param _gasLimit Gas limit for the given transaction.
     * @param _data Transaction data.
     */
    function enqueue(
        address _target,
        uint256 _gasLimit,
        bytes memory _data
    ) external;

    /**
     * Allows the sequencer to append a batch of transactions.
     * @dev This function uses a custom encoding scheme for efficiency reasons.
     * .param _shouldStartAtElement Specific batch we expect to start appending to.
     * .param _totalElementsToAppend Total number of batch elements we expect to append.
     * .param _contexts Array of batch contexts.
     * .param _transactionDataFields Array of raw transaction data.
     */
    function appendSequencerBatch(
        // uint40 _shouldStartAtElement,
        // uint24 _totalElementsToAppend,
        // BatchContext[] _contexts,
        // bytes[] _transactionDataFields
    )
        external;
        
    //added chain id function
    
    /**
     * Retrieves the total number of elements submitted.
     * @param _chainId identity for the l2 chain.
     * @return _totalElements Total submitted elements.
     */
    function getTotalElementsByChainId(
        uint256 _chainId
        )
        external
        view
        returns (
            uint256 _totalElements
        );

    /**
     * Retrieves the total number of batches submitted.
     * @param _chainId identity for the l2 chain.
     * @return _totalBatches Total submitted batches.
     */
    function getTotalBatchesByChainId(
        uint256 _chainId
        )
        external
        view
        returns (
            uint256 _totalBatches
        );

    /**
     * Returns the index of the next element to be enqueued.
     * @param _chainId identity for the l2 chain.
     * @return Index for the next queue element.
     */
    function getNextQueueIndexByChainId(
        uint256 _chainId
        )
        external
        view
        returns (
            uint40
        );

    /**
     * Gets the queue element at a particular index.
     * @param _chainId identity for the l2 chain.
     * @param _index Index of the queue element to access.
     * @return _element Queue element at the given index.
     */
    function getQueueElementByChainId(
        uint256 _chainId,
        uint256 _index
    )
        external
        view
        returns (
            Lib_OVMCodec.QueueElement memory _element
        );

    /**
     * Returns the timestamp of the last transaction.
     * @param _chainId identity for the l2 chain.
     * @return Timestamp for the last transaction.
     */
    function getLastTimestampByChainId(
        uint256 _chainId
        )
        external
        view
        returns (
            uint40
        );

    /**
     * Returns the blocknumber of the last transaction.
     * @param _chainId identity for the l2 chain.
     * @return Blocknumber for the last transaction.
     */
    function getLastBlockNumberByChainId(
        uint256 _chainId
        )
        external
        view
        returns (
            uint40
        );

    /**
     * Get the number of queue elements which have not yet been included.
     * @param _chainId identity for the l2 chain.
     * @return Number of pending queue elements.
     */
    function getNumPendingQueueElementsByChainId(
        uint256 _chainId
        )
        external
        view
        returns (
            uint40
        );

    /**
     * Retrieves the length of the queue, including
     * both pending and canonical transactions.
     * @param _chainId identity for the l2 chain.
     * @return Length of the queue.
     */
    function getQueueLengthByChainId(
        uint256 _chainId
        )
        external
        view
        returns (
            uint40
        );


    /**
     * Adds a transaction to the queue.
     * @param _chainId identity for the l2 chain.
     * @param _target Target contract to send the transaction to.
     * @param _gasLimit Gas limit for the given transaction.
     * @param _data Transaction data.
     */
    function enqueueByChainId(
        uint256 _chainId,
        address _target,
        uint256 _gasLimit,
        bytes memory _data
    )
        external;
        
    /**
     * Allows the sequencer to append a batch of transactions.
     * @dev This function uses a custom encoding scheme for efficiency reasons.
     * .param _chainId identity for the l2 chain.
     * .param _shouldStartAtElement Specific batch we expect to start appending to.
     * .param _totalElementsToAppend Total number of batch elements we expect to append.
     * .param _contexts Array of batch contexts.
     * .param _transactionDataFields Array of raw transaction data.
     */
    function appendSequencerBatchByChainId(
        // uint256 _chainId,
        // uint40 _shouldStartAtElement,
        // uint24 _totalElementsToAppend,
        // BatchContext[] _contexts,
        // bytes[] _transactionDataFields
    )
        external;
    
    function pushQueueByChainId(
        uint256 _chainId,
        Lib_OVMCodec.QueueElement calldata _object
    )
        external;

    function setQueueByChainId(
        uint256 _chainId,
        uint256 _index,
        Lib_OVMCodec.QueueElement calldata _object
    )
        external;

    function setBatchGlobalMetadataByChainId(
        uint256 _chainId,
        bytes27 _globalMetadata
    )
        external;
    
    function getBatchGlobalMetadataByChainId(uint256 _chainId)
        external
        view
        returns (
            bytes27
        );
        
    function lengthBatchByChainId(uint256 _chainId)
        external
        view
        returns (
            uint256
        );
        
    function pushBatchByChainId(
        uint256 _chainId,
        bytes32 _object,
        bytes27 _globalMetadata
    )
        external;
    
    function setBatchByChainId(
        uint256 _chainId,
        uint256 _index,
        bytes32 _object
    )
        external;
        
    function getBatchByChainId(
        uint256 _chainId,
        uint256 _index
    )
        external
        view
        returns (
            bytes32
        );
        
    function deleteBatchElementsAfterInclusiveByChainId(
        uint256 _chainId,
        uint256 _index,
        bytes27 _globalMetadata
    )
        external;
}