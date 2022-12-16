// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

import { IMultiTokenBridgeTypes } from "./interfaces/IMultiTokenBridge.sol";

/**
 * @title MultiTokenBridge storage version 1
 * @author CloudWalk Inc.
 * @dev See terms in the comments of the {IMultiTokenBridge} interface.
 */
abstract contract MultiTokenBridgeStorageV1 is IMultiTokenBridgeTypes {
    /// @dev The mapping: a destination chain ID => the number of pending relocations to that chain.
    mapping(uint256 => uint256) internal _pendingRelocationCounters;

    /// @dev The mapping: a destination chain ID => the nonce of the last processed relocation to that chain.
    mapping(uint256 => uint256) internal _lastProcessedRelocationNonces;

    /// @dev The mapping: a destination chain ID, a token address => the mode of relocation to that chain for that token.
    mapping(uint256 => mapping(address => OperationMode)) internal _relocationModes;

    /// @dev The mapping: a destination chain ID, a nonce => the relocation structure matching to that chain and nonce.
    mapping(uint256 => mapping(uint256 => Relocation)) internal _relocations;

    /// @dev The mapping: a source chain ID, a token address => the mode of accommodation from that chain for that token.
    mapping(uint256 => mapping(address => OperationMode)) internal _accommodationModes;

    /// @dev The mapping: a source chain ID => the nonce of the last accommodation from that chain.
    mapping(uint256 => uint256) internal _lastAccommodationNonces;
}

/**
 * @title MultiTokenBridge storage
 * @author CloudWalk Inc.
 * @dev Contains storage variables of the multi token bridge contract.
 *
 * We are following Compound's approach of upgrading new contract implementations.
 * See https://github.com/compound-finance/compound-protocol.
 * When we need to add new storage variables, we create a new version of MultiTokenBridgeStorage
 * e.g. MultiTokenBridgeStorage<versionNumber>, so finally it would look like
 * "contract MultiTokenBridgeStorage is MultiTokenBridgeStorageV1, MultiTokenBridgeStorageV2".
 */
abstract contract MultiTokenBridgeStorage is MultiTokenBridgeStorageV1 {

}