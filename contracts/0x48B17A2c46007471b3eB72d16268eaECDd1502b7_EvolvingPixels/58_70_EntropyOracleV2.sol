// SPDX-License-Identifier: MIT
// Copyright 2023 Proof Holdings Inc.
pragma solidity >=0.8.17;

import {EntropyOracle} from "./EntropyOracle.sol";
import {IEntropyOracle} from "./IEntropyOracle.sol";
import {IEntropyOracleV2, IEntropyOracleV2Events, IEntropyConsumer} from "./IEntropyOracleV2.sol";
import {Address} from "openzeppelin-contracts/utils/Address.sol";
import {EnumerableSet} from "openzeppelin-contracts/utils/structs/EnumerableSet.sol";

contract EntropyOracleV2 is EntropyOracle, IEntropyOracleV2, IEntropyOracleV2Events {
    using Address for address;
    using EnumerableSet for EnumerableSet.Bytes32Set;

    /**
     * @notice Callbacks MUST NOT be triggered for a block if entropy is not yet set.
     */
    error EntropyNotAvailable(uint256 blockNumber);

    /**
     * @notice Thrown if removeCallback() is called on a non-existent callback.
     */
    error CallbackNotRegistered(address consumer, uint96 callbackId, uint256 blockNumber);

    /**
     * @notice IEntropyConsumer contracts to be triggered when entropy is provided for a block, keyed by block number.
     */
    mapping(uint256 => EnumerableSet.Bytes32Set) private _callbacks;

    /**
     * @notice V1 EntropyOracle from which entropy is sourced if this contract doesn't have it available.
     */
    IEntropyOracle public v1Override;

    constructor(address admin, address steerer) EntropyOracle(admin, steerer) {}

    /**
     * @inheritdoc IEntropyOracleV2
     */
    function requestEntropyWithCallback() external {
        requestEntropyWithCallback(block.number, 0);
    }

    /**
     * @inheritdoc IEntropyOracleV2
     */
    function requestEntropyWithCallback(uint256 blockNumber, uint96 callbackId) public {
        bytes32 entropy = blockEntropy(blockNumber);
        if (uint256(entropy) != 0) {
            IEntropyConsumer(msg.sender).consumeEntropy(blockNumber, callbackId, entropy);
        } else {
            EntropyOracle.requestEntropy(blockNumber);
            // We don't perform any check of msg.sender compatibility because this is handled in provideEntropy. Even if
            // we were to use, for example, supportsInterface, this provides no guarantee that the callback doesn't
            // fail.
            _callbacks[blockNumber].add(_packCallback(msg.sender, callbackId));
        }
    }

    /**
     * @notice Returns the number of callbacks registered for the block.
     */
    function numCallbacks(uint256 blockNumber) external view returns (uint256) {
        return _callbacks[blockNumber].length();
    }

    /**
     * @notice Returns the i'th callback registered for the block.
     */
    function callback(uint256 blockNumber, uint256 i) external view returns (address, uint96) {
        return _unpackCallback(_callbacks[blockNumber].at(i));
    }

    /**
     * @notice Returns whether the consumer has requested a callback with the specified ID and block number.
     */
    function isCallbackRegistered(address consumer, uint96 callbackId, uint256 blockNumber)
        external
        view
        returns (bool)
    {
        return _callbacks[blockNumber].contains(_packCallback(consumer, callbackId));
    }

    /**
     * @notice Packs a callback address and ID into a bytes32.
     */
    function _packCallback(address addr, uint96 id) internal pure returns (bytes32) {
        return bytes32(uint256(uint160(addr)) << 96 | (id & type(uint96).max));
    }

    /**
     * @notice Reverses _packCallback().
     */
    function _unpackCallback(bytes32 packed) internal pure returns (address consumer, uint96 id) {
        consumer = address(uint160(uint256(packed) >> 96));
        id = uint96(uint256(packed));
    }

    /**
     * @notice Fulfil a request for entropy. The block MUST be historical.
     * @dev Entropy MAY be provided for a block even if it wasn't explicitly requested.
     * @dev This will result in callback functions of requesters being executed, up to maxCallbacks. To trigger
     * remaining callbacks, call triggerCallbacks().
     */
    function provideEntropy(EntropyFulfilment calldata entropy, uint256 maxCallbacks) public virtual {
        bytes32 hashed = EntropyOracle._provideEntropy(entropy);
        _triggerCallbacks(entropy.blockNumber, hashed, maxCallbacks);
    }

    /**
     * @notice Equivalent to provideEntropy(entropy, 2^256-1).
     */
    function provideEntropy(EntropyFulfilment calldata entropy) external virtual override {
        provideEntropy(entropy, type(uint256).max);
    }

    /**
     * @inheritdoc EntropyOracle
     */
    function provideEntropy(EntropyFulfilment[] calldata entropy) external virtual override {
        // TODO(arran) add an option to provide multiple blocks with maxCallbacksPerBlock.
        for (uint256 i = 0; i < entropy.length; ++i) {
            provideEntropy(entropy[i], type(uint256).max);
        }
    }

    /**
     * @notice Removes a specific consumer from the block so it isn't called by provideEntropy() nor triggerCallbacks().
     */
    function removeCallback(address consumer, uint96 callbackId, uint256 blockNumber)
        external
        onlyRole(DEFAULT_STEERING_ROLE)
    {
        EnumerableSet.Bytes32Set storage callbacks = _callbacks[blockNumber];
        bytes32 packed = _packCallback(consumer, callbackId);
        if (!callbacks.contains(packed)) {
            revert CallbackNotRegistered(consumer, callbackId, blockNumber);
        }
        _callbacks[blockNumber].remove(packed);
    }

    /**
     * @notice Triggers callbacks for a blockNumber i.f.f. respective entropy has already been provided.
     * @dev If a callback reverts during a call to provideEntropy() it fails gracefully with only an event emitted. This
     * function allows for it to be retried.
     * @dev Triggering of callbacks is idempotent, whether caused by a call to provideEntropy() or triggerCallbacks(),
     * as long as the callback is successful.
     */
    function triggerCallbacks(uint256 blockNumber, uint256 max) external {
        bytes32 entropy = blockEntropy(blockNumber);
        if (uint256(entropy) == 0) revert EntropyNotAvailable(blockNumber);
        _triggerCallbacks(blockNumber, entropy, max);
    }

    /**
     * @dev Assumes that entropy is already set for the blockNumber, which is the responsibility of the calling
     * function. provideEntropy() calls this after setting, and triggerCallbacks() reverts if not set.
     */
    function _triggerCallbacks(uint256 blockNumber, bytes32 entropy, uint256 max) internal {
        EnumerableSet.Bytes32Set storage callbacks = _callbacks[blockNumber];
        uint256 n = callbacks.length();
        if (n > max) {
            n = max;
        }
        bytes32[] memory successful = new bytes32[](n);
        uint256 cursor;

        for (uint256 i = 0; i < n; ++i) {
            bytes32 packed = callbacks.at(i);
            (address consumer, uint96 id) = _unpackCallback(packed);

            bytes memory data =
                abi.encodeWithSelector(IEntropyConsumer.consumeEntropy.selector, blockNumber, id, entropy);
            (bool ok, bytes memory reason) = consumer.call(data);
            if (ok) {
                successful[cursor++] = packed;
            } else {
                emit CallbackFailed(blockNumber, consumer, reason);
            }
        }

        while (cursor > 0) {
            callbacks.remove(successful[--cursor]);
        }
    }

    /**
     * @notice Returns the entropy value for the block number. If a non-zero v1Override address is set and it has
     * entropy available for the block, said entropy is returned.
     * @dev Not all blocks will have entropy available; check that the returned value is non-zero.
     */
    function blockEntropy(uint256 blockNumber)
        public
        view
        virtual
        override(EntropyOracle, IEntropyOracle)
        returns (bytes32)
    {
        if (address(v1Override) != address(0)) {
            bytes32 entropy = v1Override.blockEntropy(blockNumber);
            if (uint256(entropy) != 0) {
                return entropy;
            }
        }
        return EntropyOracle.blockEntropy(blockNumber);
    }

    /**
     * @notice Sets the address of the override EntropyOracle (v1) contract from which entropy is preferentially sourced
     * if available.
     */
    function setOverride(IEntropyOracle v1) external onlyRole(DEFAULT_STEERING_ROLE) {
        v1Override = v1;
    }
}