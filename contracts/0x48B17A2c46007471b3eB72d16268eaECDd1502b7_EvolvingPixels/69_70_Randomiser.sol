// SPDX-License-Identifier: MIT
// Copyright 2023 Proof Holdings Inc.
pragma solidity >=0.8.17;

import {SafeCast} from "openzeppelin-contracts/utils/math/SafeCast.sol";
import {Math} from "openzeppelin-contracts/utils/math/Math.sol";

import {NextShuffler} from "ethier/random/NextShuffler.sol";
import {PRNG} from "ethier/random/PRNG.sol";
import {ERC4906} from "ethier/erc721/ERC4906.sol";

import {IEntropyConsumer, IEntropyOracleV2} from "proof/entropy/EntropyOracleV2.sol";

import {TokenInfoManager} from "./TokenInfoManager.sol";

/**
 * @notice Project randomisation module for Evolving Pixels.
 * @author David Huber (@cxkoda)
 * @custom:reviewer Arran Schlosberg (@divergencearran)
 */
abstract contract Randomiser is ERC4906, IEntropyConsumer, TokenInfoManager {
    using NextShuffler for NextShuffler.State;
    using PRNG for PRNG.Source;

    // =================================================================================================================
    //                          Errors
    // =================================================================================================================

    /**
     * @notice Thrown when the caller is not the oracle.
     */
    error CallerNotOracle();

    // =================================================================================================================
    //                          Types
    // =================================================================================================================

    /**
     * @notice Encodes a range of tokens [start,end) that are revealed in the same entropy oracle callback.
     * @param revealed Whether the tokens in this range have already been revealed.
     * @param start The first token ID in the range (included).
     * @param end The last token ID in the range (excluded).
     */
    struct RevealBatch {
        bool revealed;
        uint64 start;
        uint64 end;
    }

    // =================================================================================================================
    //                          Constants
    // =================================================================================================================

    /**
     * @notice The maximum number of tokens that can be revealed in a single entropy oracle callback.
     * @dev With <200k gas per reveal, this puts us at a <10M gas per callback.
     */
    uint256 internal constant _MAX_TOKENS_PER_ENTROPY_CALLBACK = 50;

    /**
     * @notice The maximum supply of tokens.
     */
    uint64 public immutable maxTotalSupply;

    // =================================================================================================================
    //                          Storage
    // =================================================================================================================

    /**
     * @notice The entropy oracle.
     */
    IEntropyOracleV2 public entropyOracle;

    /**
     * @notice The shuffler used to sample project IDs via pool sampling during reveal.
     */
    NextShuffler.State internal _shuffler;

    /**
     * @notice The token ranges awaiting reveal keyed by block number and callback ID.
     */
    mapping(uint256 => mapping(uint96 => RevealBatch)) internal _batches;

    /**
     * @notice The current callback ID for a given block number.
     * @dev This counter will be increased if the number of tokens to be revealed exceeds the maximum number of tokens
     * per callback.
     */
    mapping(uint256 => uint96) internal _currentCallbackId;

    // =================================================================================================================
    //                          Construction
    // =================================================================================================================

    constructor(IEntropyOracleV2 oracle) {
        entropyOracle = oracle;

        uint64 total;
        uint256[] memory sizes = _projectSizes();
        for (uint256 i = 0; i < sizes.length; ++i) {
            total += uint64(sizes[i]);
        }
        maxTotalSupply = total;
        _shuffler.init(total);
    }

    // =================================================================================================================
    //                          The meat
    // =================================================================================================================

    /**
     * @notice Commits the purchased tokens to be revealed through future entropy; adding them to a reveal batch and
     * requesting the required entropy from the oracle.
     * @dev Must be called without gaps in sequential order for all token ranges, i.e.
     * `(0, num_1), (num_1, num_2), (num_1 + num_2, num_3), ...`.
     */
    function _commitAndRequestEntropy(uint256 tokenId, uint256 num) internal {
        if (num == 0) {
            return;
        }

        uint256 entropyBlockNumber = block.number;
        uint96 callbackId = _currentCallbackId[entropyBlockNumber];

        RevealBatch memory batch = _batches[entropyBlockNumber][callbackId];
        assert(!batch.revealed);

        uint256 batchSize = batch.end - batch.start;
        if (batchSize == 0) {
            // This batch has not been initialised yet.
            batch.start = SafeCast.toUint64(tokenId);
            entropyOracle.requestEntropyWithCallback(entropyBlockNumber, callbackId);
        }

        uint256 batchSizeLeft = _MAX_TOKENS_PER_ENTROPY_CALLBACK - batchSize;
        uint256 numThisBatch = Math.min(num, batchSizeLeft);

        batch.end = SafeCast.toUint64(tokenId + numThisBatch);
        _batches[entropyBlockNumber][callbackId] = batch;

        if (numThisBatch == batchSizeLeft) {
            // The commitment exhausts the current batch. Moving to the next one.
            ++_currentCallbackId[entropyBlockNumber];
        }

        // if `num - numThisBatch == 0` this will return early.
        _commitAndRequestEntropy(tokenId + numThisBatch, num - numThisBatch);
    }

    /**
     * @notice Consumes the entropy provided by the oracle and reveals the tokens in the corresponding reveal batch.
     * @dev The randomised reveal can be understood as shuffling a deck that contains each project ID
     * `_projectSizes()[pID]` times.
     */
    function consumeEntropy(uint256 blockNumber, uint96 callbackId, bytes32 entropy) external {
        if (msg.sender != address(entropyOracle)) {
            revert CallerNotOracle();
        }

        RevealBatch storage $batch = _batches[blockNumber][callbackId];
        RevealBatch memory batch = $batch;
        assert(!batch.revealed);
        $batch.revealed = true;

        // Doing this before actually revealing the tokens to simplify detecting this event while testing.
        _refreshMetadata(batch.start, batch.end);

        uint256[] memory sizes = _projectSizes();
        PRNG.Source rng = PRNG.newSource(keccak256(abi.encode(entropy, batch)));
        uint256 end = batch.end;
        for (uint256 tokenId = batch.start; tokenId < end; ++tokenId) {
            uint256 randIdx = _shuffler.next(rng);
            uint8 projectId = _findProjectId(randIdx, sizes);
            _assignProject(tokenId, projectId);
        }
    }

    /**
     * @notice Finds the project ID for a given index.
     * @dev The project ID is determined by stepping through the project sizes. It can also be understood by accessing
     * the array `[pID_0,...,pID_0,pID_1,...,pID_n]` where each project ID is contained `projectSizes[pID]` times at the
     * given index.
     */
    function _findProjectId(uint256 index, uint256[] memory projectSizes) internal pure returns (uint8) {
        uint8 projectId = 0;

        while (index >= projectSizes[projectId]) {
            index -= projectSizes[projectId];
            ++projectId;
        }

        return projectId;
    }

    // =================================================================================================================
    //                          Internal linking
    // =================================================================================================================

    /**
     * @notice Hook that is called after the project ID has been reavealed, assigning the project and its next edition
     * to a token.
     * @dev This is intended to trigger ArtBlock's rendering engine if the revealed project is a longform one.
     */
    function _assignProject(uint256 tokenId, uint8 projectId) internal virtual;

    /**
     * @notice Returns the number of tokens for each project.
     */
    function _projectSizes() internal pure virtual returns (uint256[] memory);
}