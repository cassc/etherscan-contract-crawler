// SPDX-License-Identifier: MIT
// Copyright 2023 Proof Holdings Inc.
pragma solidity ^0.8.0;

import {IEntropyOracle} from "./IEntropyOracle.sol";

/**
 * @notice Contracts that call IEntropyOracleV2.requestEntropyWithCallback(…) MUST implement IEntropyConsumer to be
 * notified of entropy provision.
 */
interface IEntropyConsumer {
    function consumeEntropy(uint256 blockNumber, uint96 callbackId, bytes32 entropy) external;
}

interface IEntropyOracleV2Events {
    /**
     * @notice Emitted when entropy is provided and the callback of an IEntropyConsumer reverts.
     */
    event CallbackFailed(uint256 indexed blockNumber, address indexed consumer, bytes reason);
}

/**
 * @dev There are deliberately no request options with only callbackId or only block number as these risk confusion that
 * may not be picked up by the compiler should constants be used.
 */
interface IEntropyOracleV2 is IEntropyOracle {
    /**
     * @notice Equivalent to requestEntropyWithCallback(block.number, 0). This is safe as the request will only be
     * fulfilled once the block is mined.
     */
    function requestEntropyWithCallback() external;

    /**
     * @notice Equivalent to requestEntropy(blockNumber) with an additional request for callback when the block's
     * entropy is provided.
     * @dev The requesting contract MUST implement IEntropyConsumer to receive the callback.
     * @dev Multiple calls with the same ID and block number, made before the block entropy is set, are deduplicated
     * such that this function is idempotent. Calls made after entropy is set for the block trigger the callback
     * in the same call stack and are not deduplicated.
     */
    function requestEntropyWithCallback(uint256 blockNumber, uint96 callbackId) external;
}