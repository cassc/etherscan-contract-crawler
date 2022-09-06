//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.15;

import {RLPReader} from "./lib/RLPReader.sol";
import {MerklePatriciaProof} from "./lib/MerklePatriciaProof.sol";
import {Merkle} from "./lib/Merkle.sol";
import "./lib/ExitPayloadReader.sol";
import "./lib/IRootChain.sol";
import "./lib/IRootChainManager.sol";
import "./lib/IRootToken.sol";

/// @title Withdraw To Wrapper (Root) for Polygon PoS
/// @author QEDK
/// @notice This contract enables withdrawals on the root chain for Polygon PoS to specific addresses using the
/// `MessageSent` event.
/// @custom:experimental This is an experimental contract.
contract WithdrawToWrapperRoot {
    using RLPReader for RLPReader.RLPItem;
    using Merkle for bytes32;
    using ExitPayloadReader for bytes;
    using ExitPayloadReader for ExitPayloadReader.ExitPayload;
    using ExitPayloadReader for ExitPayloadReader.Log;
    using ExitPayloadReader for ExitPayloadReader.LogTopics;
    using ExitPayloadReader for ExitPayloadReader.Receipt;
    IRootChainManager public immutable rootChainManager;
    IRootChain public immutable rootChain;

    bytes32 private constant SEND_MESSAGE_EVENT_SIG =
        0x8c5261668696ce22758910d05bab8f186d6eb247ceac2af2e82c7dc17669b036;

    mapping(bytes32 => bool) public processedExits;

    constructor(IRootChain _rootChain, IRootChainManager _rootChainManager) {
        rootChain = _rootChain;
        rootChainManager = _rootChainManager;
    }

    /// @notice Allows for special exits using PoS burn proof and an offset.
    /// @dev We use the offset to read the log of the MessageSent event.
    /// @param _burnProof Proof of a Pos burn event (see more below)
    /// @param offset Offset of the MessageSent relative to the burn event
    function exit(bytes calldata _burnProof, uint8 offset) external {
        rootChainManager.exit(_burnProof); // token -> contract

        bytes memory _messageProof = abi.encodePacked(
            _burnProof[:_burnProof.length - 1],
            uint8(_burnProof[_burnProof.length - 1]) + offset
        );

        (address rootToken, , uint256 amount, address destination) = abi.decode(
            _validateAndExtractMessage(_messageProof),
            (address, address, uint256, address)
        );

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = rootToken.call(
            abi.encodeWithSelector(
                IRootToken.transfer.selector,
                destination,
                amount
            )
        ); // contract -> user
        if (returndata.length != 0) {
            bool returnvalue = abi.decode(returndata, (bool));
            require(success && returnvalue, "TRANSFER_FAILED");
        } else {
            require(success, "TRANSFER_FAILED");
        }
    }

    /* @notice Internal function that we use to read and verify the MessageSent event from RootChain contract
     * @param inputData RLP encoded data of the MessageSent tx containing following list of fields
     *  0 - headerNumber - Checkpoint header block number containing the reference tx
     *  1 - blockProof - Proof that the block header (in the child chain) is a leaf in the submitted merkle root
     *  2 - blockNumber - Block number containing the reference tx on child chain
     *  3 - blockTime - Reference tx block time
     *  4 - txRoot - Transactions root of block
     *  5 - receiptRoot - Receipts root of block
     *  6 - receipt - Receipt of the reference transaction
     *  7 - receiptProof - Merkle proof of the reference receipt
     *  8 - branchMask - 32 bits denoting the path of receipt in merkle tree
     *  9 - receiptLogIndex - Log Index to read from the receipt
     * @return Returns the decoded log event of the `MessageSent` event
     */
    function _validateAndExtractMessage(bytes memory inputData)
        internal
        returns (bytes memory)
    {
        ExitPayloadReader.ExitPayload memory payload = inputData
            .toExitPayload();

        bytes memory branchMaskBytes = payload.getBranchMaskAsBytes();
        uint256 blockNumber = payload.getBlockNumber();
        // checking if exit has already been processed
        // unique exit is identified using hash of (blockNumber, branchMask, receiptLogIndex)
        bytes32 exitHash = keccak256(
            abi.encodePacked(
                blockNumber,
                // first 2 nibbles are dropped while generating nibble array
                // this allows branch masks that are valid but bypass exitHash check (changing first 2 nibbles only)
                // so converting to nibble array and then hashing it
                MerklePatriciaProof._getNibbleArray(branchMaskBytes),
                payload.getReceiptLogIndex()
            )
        );
        require(
            processedExits[exitHash] == false,
            "WITHDRAW: EXIT_ALREADY_PROCESSED"
        );
        processedExits[exitHash] = true;

        ExitPayloadReader.Receipt memory receipt = payload.getReceipt();
        ExitPayloadReader.Log memory log = receipt.getLog();

        // check that emitting address is same
        require(log.getEmitter() == address(this), "WITHDRAW: INVALID_EMITTER");

        bytes32 receiptRoot = payload.getReceiptRoot();
        // verify receipt inclusion
        require(
            MerklePatriciaProof.verify(
                receipt.toBytes(),
                branchMaskBytes,
                payload.getReceiptProof(),
                receiptRoot
            ),
            "WITHDRAW: INVALID_RECEIPT_PROOF"
        );

        // verify checkpoint inclusion
        _checkBlockMembershipInCheckpoint(
            blockNumber,
            payload.getBlockTime(),
            payload.getTxRoot(),
            receiptRoot,
            payload.getHeaderNumber(),
            payload.getBlockProof()
        );

        ExitPayloadReader.LogTopics memory topics = log.getTopics();

        require(
            bytes32(topics.getField(0).toUint()) == SEND_MESSAGE_EVENT_SIG, // topic0 is event sig
            "WITHDRAW: INVALID_SIGNATURE"
        );

        // received message data
        bytes memory message = abi.decode(log.getData(), (bytes)); // event decodes params again, so decoding bytes to get message
        return message;
    }

    /// @notice Internal function that we use to check block membership of a submitted proof
    /// @param blockNumber Block number of proof
    /// @param blockTime Timestamp
    function _checkBlockMembershipInCheckpoint(
        uint256 blockNumber,
        uint256 blockTime,
        bytes32 txRoot,
        bytes32 receiptRoot,
        uint256 headerNumber,
        bytes memory blockProof
    ) private view returns (uint256) {
        IRootChain.HeaderBlock memory headerBlock = rootChain.headerBlocks(
            headerNumber
        );

        require(
            keccak256(
                abi.encodePacked(blockNumber, blockTime, txRoot, receiptRoot)
            ).checkMembership(
                    blockNumber - headerBlock.start,
                    headerBlock.root,
                    blockProof
                ),
            "WITHDRAW: INVALID_HEADER"
        );
        return headerBlock.createdAt;
    }
}