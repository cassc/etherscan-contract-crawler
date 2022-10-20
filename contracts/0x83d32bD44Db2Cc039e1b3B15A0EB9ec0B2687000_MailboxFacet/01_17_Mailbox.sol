pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT OR Apache-2.0



import "../interfaces/IMailbox.sol";
import "../libraries/Merkle.sol";
import "../libraries/PriorityQueue.sol";
import "../Storage.sol";
import "../Config.sol";
import "../../common/L2ContractHelper.sol";
import "./Base.sol";

/// @title zkSync Mailbox contract providing interfaces for L1 <-> L2 interaction.
/// @author Matter Labs
contract MailboxFacet is Base, IMailbox {
    using PriorityQueue for PriorityQueue.Queue;

    /// @notice Prove that a specific arbitrary-length message was sent in a specific L2 block number
    /// @param _blockNumber The executed L2 block number in which the message appeared
    /// @param _index The position in the L2 logs Merkle tree of the l2Log that was sent with the message
    /// @param _message Information about the sent message: sender address, the message itself, tx index in the L2 block where the message was sent
    /// @param _proof Merkle proof for inclusion of L2 log that was sent with the message
    /// @return Whether the proof is valid
    function proveL2MessageInclusion(
        uint256 _blockNumber,
        uint256 _index,
        L2Message calldata _message,
        bytes32[] calldata _proof
    ) external view returns (bool) {
        return _proveL2LogInclusion(_blockNumber, _index, _L2MessageToLog(_message), _proof);
    }

    /// @notice Prove that a specific L2 log was sent in a specific L2 block
    /// @param _blockNumber The executed L2 block number in which the log appeared
    /// @param _index The position of the l2log in the L2 logs Merkle tree
    /// @param _log Information about the sent log
    /// @param _proof Merkle proof for inclusion of the L2 log
    function proveL2LogInclusion(
        uint256 _blockNumber,
        uint256 _index,
        L2Log memory _log,
        bytes32[] calldata _proof
    ) external view returns (bool) {
        return _proveL2LogInclusion(_blockNumber, _index, _log, _proof);
    }

    /// @dev Prove that a specific L2 log was sent in a specific L2 block number
    function _proveL2LogInclusion(
        uint256 _blockNumber,
        uint256 _index,
        L2Log memory _log,
        bytes32[] calldata _proof
    ) internal view returns (bool) {
        require(_blockNumber <= s.totalBlocksExecuted, "xx");

        bytes32 hashedLog = keccak256(
            abi.encodePacked(_log.l2ShardId, _log.isService, _log.txNumberInBlock, _log.sender, _log.key, _log.value)
        );
        // Check that hashed log is not the default one,
        // otherwise it means that the value is out of range of sent L2 -> L1 logs
        require(hashedLog != L2_L1_LOGS_TREE_DEFAULT_LEAF_HASH, "tw");
        // Check that the proof length is exactly the same as tree height, to prevent
        // any shorter/longer paths attack on the Merkle path validation
        require(_proof.length == L2_TO_L1_LOG_MERKLE_TREE_HEIGHT, "rz");

        bytes32 calculatedRootHash = Merkle.calculateRoot(_proof, _index, hashedLog);
        bytes32 actualRootHash = s.l2LogsRootHashes[_blockNumber];

        return actualRootHash == calculatedRootHash;
    }

    /// @dev Convert arbitrary-length message to the raw l2 log
    function _L2MessageToLog(L2Message calldata _message) internal pure returns (L2Log memory) {
        return
            L2Log({
                l2ShardId: 0,
                isService: true,
                txNumberInBlock: _message.txNumberInBlock,
                sender: L2_TO_L1_MESSENGER,
                key: bytes32(uint256(uint160(_message.sender))),
                value: keccak256(_message.data)
            });
    }

    /// @notice Estimates the cost in Ether of requesting execution of an L2 transaction from L1
    /// @return The estimated ergs
    function l2TransactionBaseCost(
        uint256, // _gasPrice
        uint256, // _ergsLimit
        uint32 // _calldataLength
    ) public pure returns (uint256) {
        // TODO: estimate gas for L1 execute
        return 0;
    }

    /// @notice Request execution of L2 transaction from L1.
    /// @param _contractL2 The L2 receiver address
    /// @param _l2Value `msg.value` of L2 transaction. Please note, this ether is not transferred with requesting priority op,
    /// but will be taken from the balance in L2 during the execution
    /// @param _calldata The input of the L2 transaction
    /// @param _ergsLimit Maximum amount of ergs that transaction can consume during execution on L2
    /// @param _factoryDeps An array of L2 bytecodes that will be marked as known on L2
    /// @return canonicalTxHash The hash of the requested L2 transaction. This hash can be used to follow the transaction status
    function requestL2Transaction(
        address _contractL2,
        uint256 _l2Value,
        bytes calldata _calldata,
        uint256 _ergsLimit,
        bytes[] calldata _factoryDeps
    ) external payable nonReentrant senderCanCallFunction(s.allowList) returns (bytes32 canonicalTxHash) {
        canonicalTxHash = _requestL2Transaction(msg.sender, _contractL2, _l2Value, _calldata, _ergsLimit, _factoryDeps);
    }

    function _requestL2Transaction(
        address _sender,
        address _contractL2,
        uint256 _l2Value,
        bytes calldata _calldata,
        uint256 _ergsLimit,
        bytes[] calldata _factoryDeps
    ) internal returns (bytes32 canonicalTxHash) {
        require(_ergsLimit <= PRIORITY_TX_MAX_ERGS_LIMIT, "ui");
        uint64 expirationBlock = uint64(block.number + PRIORITY_EXPIRATION);
        uint256 txId = s.priorityQueue.getTotalPriorityTxs();
        // TODO: Restore after stable priority op fee modeling. (SMA-1230)
        // uint256 baseCost = l2TransactionBaseCost(tx.gasprice, _ergsLimit, uint32(_calldata.length));
        // uint256 layer2Tip = msg.value - baseCost;

        canonicalTxHash = _writePriorityOp(
            _sender,
            txId,
            _l2Value,
            _contractL2,
            _calldata,
            expirationBlock,
            _ergsLimit,
            _factoryDeps
        );
    }

    /// @notice Stores a transaction record in storage & send event about that
    function _writePriorityOp(
        address _sender,
        uint256 _txId,
        uint256 _l2Value,
        address _contractAddressL2,
        bytes calldata _calldata,
        uint64 _expirationBlock,
        uint256 _ergsLimit,
        bytes[] calldata _factoryDeps
    ) internal returns (bytes32 canonicalTxHash) {
        L2CanonicalTransaction memory transaction = serializeL2Transaction(
            _txId,
            _l2Value,
            _sender,
            _contractAddressL2,
            _calldata,
            _ergsLimit,
            _factoryDeps
        );
        canonicalTxHash = keccak256(abi.encode(transaction));

        s.priorityQueue.pushBack(
            PriorityOperation({
                canonicalTxHash: canonicalTxHash,
                expirationBlock: _expirationBlock,
                layer2Tip: uint192(0) // TODO: Restore after fee modeling will be stable. (SMA-1230)
            })
        );

        // Data that needed for operator to simulate priority queue offchain
        emit NewPriorityRequest(_txId, canonicalTxHash, _expirationBlock, transaction, _factoryDeps);
    }

    /// @dev Accepts the parameters of the l2 transaction and converts it to the canonical form.
    /// @param _txId Priority operation ID, used as a unique identifier so that transactions always have a different hash
    /// @param _l2Value `msg.value` of L2 transaction. Please note, this ether is not transferred with requesting priority op,
    /// but will be taken from the balance in L2 during the execution
    /// @param _sender The L2 address of the account that initiates the transaction
    /// @param _contractAddressL2 The L2 receiver address
    /// @param _calldata The input of the L2 transaction
    /// @param _ergsLimit Maximum amount of ergs that transaction can consume during execution on L2
    /// @param _factoryDeps An array of L2 bytecodes that will be marked as known on L2
    /// @return The canonical form of the l2 transaction parameters
    function serializeL2Transaction(
        uint256 _txId,
        uint256 _l2Value,
        address _sender,
        address _contractAddressL2,
        bytes calldata _calldata,
        uint256 _ergsLimit,
        bytes[] calldata _factoryDeps
    ) public pure returns (L2CanonicalTransaction memory) {
        return
            L2CanonicalTransaction({
                txType: PRIORITY_OPERATION_L2_TX_TYPE,
                from: uint256(uint160(_sender)),
                to: uint256(uint160(_contractAddressL2)),
                ergsLimit: _ergsLimit,
                ergsPerPubdataByteLimit: uint256(1),
                maxFeePerErg: uint256(0),
                maxPriorityFeePerErg: uint256(0),
                paymaster: uint256(0),
                reserved: [uint256(_txId), _l2Value, 0, 0, 0, 0],
                data: _calldata,
                signature: new bytes(0),
                factoryDeps: _hashFactoryDeps(_factoryDeps),
                paymasterInput: new bytes(0),
                reservedDynamic: new bytes(0)
            });
    }

    /// @notice hashes the L2 bytecodes and returns them in the format in which they are processed by the bootloader
    function _hashFactoryDeps(bytes[] calldata _factoryDeps)
        internal
        pure
        returns (uint256[] memory hashedFactoryDeps)
    {
        uint256 factoryDepsLen = _factoryDeps.length;
        hashedFactoryDeps = new uint256[](factoryDepsLen);
        for (uint256 i = 0; i < factoryDepsLen; ) {
            bytes32 hashedBytecode = L2ContractHelper.hashL2Bytecode(_factoryDeps[i]);

            // Store the resulting hash sequentially in bytes.
            assembly {
                mstore(add(hashedFactoryDeps, mul(add(i, 1), 32)), hashedBytecode)
            }

            unchecked {
                ++i;
            }
        }
    }
}