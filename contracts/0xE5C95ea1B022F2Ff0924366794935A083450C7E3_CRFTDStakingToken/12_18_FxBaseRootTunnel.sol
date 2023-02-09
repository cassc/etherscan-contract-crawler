// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Merkle} from "../lib/Merkle.sol";
import {RLPReader} from "../lib/RLPReader.sol";
import {ExitPayloadReader} from "../lib/ExitPayloadReader.sol";
import {MerklePatriciaProof} from "../lib/MerklePatriciaProof.sol";

// ------------- interfaces

interface IFxStateSender {
    function sendMessageToChild(address _receiver, bytes calldata _data) external;
}

interface ICheckpointManager {
    function headerBlocks(uint256 headerNumber)
        external
        view
        returns (bytes32 root, uint256 start, uint256 end, uint256 createdAt, address proposer);
}

// ------------- storage

bytes32 constant DIAMOND_STORAGE_FX_BASE_ROOT_TUNNEL = keccak256("diamond.storage.fx.base.root.tunnel");

function s() pure returns (FxBaseRootTunnelDS storage diamondStorage) {
    bytes32 slot = DIAMOND_STORAGE_FX_BASE_ROOT_TUNNEL;
    assembly {
        diamondStorage.slot := slot
    }
}

struct FxBaseRootTunnelDS {
    address fxChildTunnel;
    mapping(bytes32 => bool) processedExits;
}

// ------------- errors

error FxChildUnset();
error InvalidHeader();
error InvalidSelector();
error InvalidReceiptProof();
error InvalidFxChildTunnel();
error ExitAlreadyProcessed();

abstract contract FxBaseRootTunnel {
    using RLPReader for RLPReader.RLPItem;
    using Merkle for bytes32;
    using ExitPayloadReader for bytes;
    using ExitPayloadReader for ExitPayloadReader.ExitPayload;
    using ExitPayloadReader for ExitPayloadReader.Log;
    using ExitPayloadReader for ExitPayloadReader.LogTopics;
    using ExitPayloadReader for ExitPayloadReader.Receipt;

    bytes32 private constant SEND_MESSAGE_EVENT_SELECTOR =
        0x8c5261668696ce22758910d05bab8f186d6eb247ceac2af2e82c7dc17669b036;

    IFxStateSender public immutable fxRoot;
    ICheckpointManager public immutable checkpointManager;

    constructor(address checkpointManager_, address fxRoot_) {
        checkpointManager = ICheckpointManager(checkpointManager_);
        fxRoot = IFxStateSender(fxRoot_);
    }

    /* ------------- virtual ------------- */

    function _authorizeTunnelController() internal virtual;

    /* ------------- view ------------- */

    function fxChildTunnel() public view virtual returns (address) {
        return s().fxChildTunnel;
    }

    function processedExits(bytes32 exitHash) public view virtual returns (bool) {
        return s().processedExits[exitHash];
    }

    function setFxChildTunnel(address fxChildTunnel_) public virtual {
        _authorizeTunnelController();

        s().fxChildTunnel = fxChildTunnel_;
    }

    /* ------------- internal ------------- */

    function _sendMessageToChild(bytes memory message) internal virtual {
        if (s().fxChildTunnel == address(0)) revert FxChildUnset();

        fxRoot.sendMessageToChild(s().fxChildTunnel, message);
    }

    /**
     * @notice receive message from  L2 to L1, validated by proof
     * @dev This function verifies if the transaction actually happened on child chain
     *
     * @param proofData RLP encoded data of the reference tx containing following list of fields
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
     */
    function _validateAndExtractMessage(bytes memory proofData) internal returns (bytes memory) {
        address childTunnel = s().fxChildTunnel;

        if (childTunnel == address(0)) revert FxChildUnset();

        ExitPayloadReader.ExitPayload memory payload = proofData.toExitPayload();

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

        if (s().processedExits[exitHash]) revert ExitAlreadyProcessed();

        s().processedExits[exitHash] = true;

        ExitPayloadReader.Receipt memory receipt = payload.getReceipt();
        ExitPayloadReader.Log memory log = receipt.getLog();

        // check child tunnel
        if (childTunnel != log.getEmitter()) revert InvalidFxChildTunnel();

        bytes32 receiptRoot = payload.getReceiptRoot();
        // verify receipt inclusion
        if (!MerklePatriciaProof.verify(receipt.toBytes(), branchMaskBytes, payload.getReceiptProof(), receiptRoot)) {
            revert InvalidReceiptProof();
        }

        (bytes32 headerRoot, uint256 startBlock,,,) = checkpointManager.headerBlocks(payload.getHeaderNumber());

        bytes32 leaf =
            keccak256(abi.encodePacked(blockNumber, payload.getBlockTime(), payload.getTxRoot(), receiptRoot));

        if (!leaf.checkMembership(blockNumber - startBlock, headerRoot, payload.getBlockProof())) {
            revert InvalidHeader();
        }

        ExitPayloadReader.LogTopics memory topics = log.getTopics();

        if (bytes32(topics.getField(0).toUint()) != SEND_MESSAGE_EVENT_SELECTOR) revert InvalidSelector();

        // received message data
        bytes memory message = abi.decode(log.getData(), (bytes)); // event decodes params again, so decoding bytes to get message

        return message;
    }
}