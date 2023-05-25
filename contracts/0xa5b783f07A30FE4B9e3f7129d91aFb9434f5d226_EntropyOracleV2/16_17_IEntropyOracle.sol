// SPDX-License-Identifier: MIT
// Copyright 2023 Proof Holdings Inc.
pragma solidity ^0.8.0;

interface IEntropyOracleEvents {
    /**
     * @notice Emitted when entropy is requested, to signal the oracle.
     */
    event EntropyRequested(uint256 indexed blockNumber);

    /**
     * @notice Emitted when an entropy request is fulfilled.
     */
    event EntropyProvided(uint256 indexed blockNumber, bytes32 entropy);
}

interface IEntropyOracle is IEntropyOracleEvents {
    /**
     * @notice Equivalent to requestEntropy(block.number). This is safe as the request will only be fulfilled once the
     * block is mined.
     */
    function requestEntropy() external;

    /**
     * @notice Signal to the oracle that entropy is requested for the specified block. The request will only be
     * fulfilled once the block is mined.
     * @dev NOTE that this must be used with care. If a historical block is requested, the entropy may be known by a bad
     * actor. It is only safe to request entropy for a historical block i.f.f. said block was commited to before it was
     * mined.
     */
    function requestEntropy(uint256 blockNumber) external;

    /**
     * @notice Entropy values, keyed by block number.
     * @dev Not all blocks will have entropy available; check that the returned value is non-zero.
     */
    function blockEntropy(uint256) external view returns (bytes32);
}