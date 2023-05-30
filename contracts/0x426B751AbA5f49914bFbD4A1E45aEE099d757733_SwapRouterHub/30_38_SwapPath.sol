// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "./BytesLib.sol";
import "./Protocols.sol";

/// @title Functions for manipulating path data for multihop swaps
library SwapPath {
    using BytesLib for bytes;

    /// @dev The length of the bytes encoded token index
    uint256 private constant TOKEN_INDEX_SIZE = 1;

    /// @dev The length of the bytes encoded protocol
    uint256 private constant PROTOCOL_SIZE = 1;

    /// @dev The length of the bytes encoded address
    uint256 private constant ADDR_SIZE = 20;

    /// @dev The length of the bytes encoded resolution
    uint256 private constant RESOLUTION_SIZE = 3;

    /// @dev The offset of the encoded resolution
    uint256 private constant RESOLUTION_OFFSET = ADDR_SIZE + PROTOCOL_SIZE;

    /// @dev The size of the resolution payload
    uint256 private constant RESOLUTION_PAYLOAD_SIZE = PROTOCOL_SIZE + RESOLUTION_SIZE;

    /// @dev The offset of a single token address and resolution payload
    uint256 private constant RESOLUTION_PAYLOAD_NEXT_OFFSET = ADDR_SIZE + RESOLUTION_PAYLOAD_SIZE;

    /// @dev The offset of the encoded resolution payload grid key
    uint256 private constant RESOLUTION_PAYLOAD_POP_OFFSET = RESOLUTION_PAYLOAD_NEXT_OFFSET + ADDR_SIZE;

    /// @dev The offset of the encoded swap address in the curve payload
    uint256 private constant CURVE_PAYLOAD_SWAP_ADDRESS_OFFSET = RESOLUTION_OFFSET + ADDR_SIZE;

    /// @dev The offset of the encoded token A index in the curve payload
    uint256 private constant CURVE_PAYLOAD_TOKEN_A_INDEX_OFFSET = CURVE_PAYLOAD_SWAP_ADDRESS_OFFSET + ADDR_SIZE;

    /// @dev The offset of the encoded token B index in the curve payload
    uint256 private constant CURVE_PAYLOAD_TOKEN_B_INDEX_OFFSET = CURVE_PAYLOAD_TOKEN_A_INDEX_OFFSET + TOKEN_INDEX_SIZE;

    /// @dev The size of the curve payload
    uint256 private constant CURVE_PAYLOAD_SIZE = PROTOCOL_SIZE + ADDR_SIZE * 2 + TOKEN_INDEX_SIZE * 2;

    /// @dev The offset of a single token address and curve payload
    uint256 private constant CURVE_PAYLOAD_NEXT_OFFSET = ADDR_SIZE + CURVE_PAYLOAD_SIZE;

    /// @dev The offset of an encoded curve payload grid key
    uint256 private constant CURVE_PAYLOAD_POP_OFFSET = CURVE_PAYLOAD_NEXT_OFFSET + ADDR_SIZE;

    /// @notice Returns true if the path contains two or more grids
    /// @param path The encoded swap path
    /// @return True if path contains two or more grids, otherwise false
    function hasMultipleGrids(bytes memory path) internal pure returns (bool) {
        if (getProtocol(path) < Protocols.CURVE) {
            return path.length > RESOLUTION_PAYLOAD_POP_OFFSET;
        } else {
            return path.length > CURVE_PAYLOAD_POP_OFFSET;
        }
    }

    /// @notice Decodes the first grid in path
    /// @param path The bytes encoded swap path
    /// @return tokenA The first token of the given grid
    /// @return tokenB The second token of the given grid
    /// @return resolution The resolution of the given grid
    function decodeFirstGrid(
        bytes memory path
    ) internal pure returns (address tokenA, address tokenB, int24 resolution) {
        tokenA = path.toAddress(0);
        resolution = int24(path.toUint24(RESOLUTION_OFFSET));
        tokenB = path.toAddress(RESOLUTION_PAYLOAD_NEXT_OFFSET);
    }

    /// @notice Decodes the first curve pool in path
    /// @param path The bytes encoded swap path
    /// @return tokenA The first token of the given pool
    /// @return tokenB The second token of the given pool
    /// @return poolAddress The address of the given pool
    /// @return swapAddress The swap address only for curve protocol
    /// @return tokenAIndex The index of the tokenA
    /// @return tokenBIndex The index of the tokenB
    function decodeFirstCurvePool(
        bytes memory path
    )
        internal
        pure
        returns (
            address tokenA,
            address tokenB,
            address poolAddress,
            address swapAddress,
            uint8 tokenAIndex,
            uint8 tokenBIndex
        )
    {
        tokenA = path.toAddress(0);
        poolAddress = path.toAddress(RESOLUTION_OFFSET);
        swapAddress = path.toAddress(CURVE_PAYLOAD_SWAP_ADDRESS_OFFSET);
        tokenAIndex = uint8(path[CURVE_PAYLOAD_TOKEN_A_INDEX_OFFSET]);
        tokenBIndex = uint8(path[CURVE_PAYLOAD_TOKEN_B_INDEX_OFFSET]);
        tokenB = path.toAddress(CURVE_PAYLOAD_NEXT_OFFSET);
    }

    /// @notice Gets the segment corresponding to the first grid in the path
    /// @param path The bytes encoded swap path
    /// @return The segment containing all data necessary to target the first grid in the path
    function getFirstGrid(bytes memory path) internal pure returns (bytes memory) {
        if (getProtocol(path) < Protocols.CURVE) return path.slice(0, RESOLUTION_PAYLOAD_POP_OFFSET);
        else return path.slice(0, CURVE_PAYLOAD_POP_OFFSET);
    }

    /// @notice Skips the token and the payload element from the buffer and returns the remainder
    /// @param path The swap path
    /// @return The remaining token + payload elements in the path
    function skipToken(bytes memory path) internal pure returns (bytes memory) {
        if (getProtocol(path) < Protocols.CURVE)
            return path.slice(RESOLUTION_PAYLOAD_NEXT_OFFSET, path.length - RESOLUTION_PAYLOAD_NEXT_OFFSET);
        else return path.slice(CURVE_PAYLOAD_NEXT_OFFSET, path.length - CURVE_PAYLOAD_NEXT_OFFSET);
    }

    /// @notice Returns the protocol identifier for the given path
    /// @param path The encoded swap path
    /// @return The protocol identifier
    function getProtocol(bytes memory path) internal pure returns (uint8) {
        return uint8(path[ADDR_SIZE]);
    }

    /// @notice Returns the first token address for the given path
    /// @param path The encoded swap path
    /// @return The first token address
    function getTokenA(bytes memory path) internal pure returns (address) {
        return path.toAddress(0);
    }
}