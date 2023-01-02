/// SPDX-License-Identifier: UNLICENSED
/// (c) Theori, Inc. 2022
/// All rights reserved

/**
 * @title MPT
 * @author Theori, Inc.
 * @notice Implements proof checking for Ethereum Merkle-Patricia Tries.
 *         Only supports fixed-size 256-bit keys. To save gas, it assumes
 *         nodes are validly structured, so soundness is only guaranteed
 *         if the rootHash belongs to a valid ethereum block.
 */

pragma solidity >=0.8.0;

import "./RLP.sol";
import "./CoreTypes.sol";

library MPT {
    // prefix constants
    uint8 constant ODD_LENGTH = 1;
    uint8 constant LEAF = 2;
    uint8 constant MAX_PREFIX = 3;

    /**
     * @notice Checks if the provided bytes match the key at a given offset
     * @param key the MPT key to check against
     * @param keyLen the length (in nibbles) of the key
     * @param testBytes the subkey to check
     */
    function subkeysEqual(
        bytes32 key,
        uint256 keyLen,
        bytes calldata testBytes
    ) private pure returns (bool result) {
        // arithmetic cannot overflow because testBytes is from calldata
        uint256 nibbleLength;
        unchecked {
            nibbleLength = 2 * testBytes.length;
            require(nibbleLength <= keyLen);
        }

        assembly {
            let shiftAmount := sub(256, shl(2, nibbleLength))
            let testValue := shr(shiftAmount, calldataload(testBytes.offset))
            let subkey := shr(shiftAmount, key)
            result := eq(testValue, subkey)
        }
    }

    /**
     * @notice checks the MPT proof. Note: for certain optimizations, we assume
     *         that the rootHash belongs to a valid ethereum block. Correctness
     *         is only guaranteed in that case.
     *         Gas usage depends on both proof size and key nibble values.
     *         Gas usage for actual ethereum account proofs: ~ 30000 - 45000
     * @param proof the encoded MPT proof noodes concatenated
     * @param key the MPT key, padded with trailing 0s if needed
     * @param keyLen the byte length of the MPT key, must be <= 32
     * @param rootHash the root hash of the MPT
     */
    function verifyTrieValue(
        bytes calldata proof,
        bytes32 key,
        uint256 keyLen,
        bytes32 rootHash
    ) internal pure returns (bool exists, bytes calldata value) {
        bytes32 expectedHash = rootHash;

        // we will read the key nibble by nibble, so double the length
        keyLen *= 2;

        // initialize return values to make solc happy;
        // one will always be overwritten before returing
        value = proof[:0];
        exists = true;

        while (true) {
            bytes calldata node;
            {
                (uint256 listSize, uint256 offset) = RLP.parseList(proof);

                // include the list prefix for the hash check
                node = proof[:offset + listSize];
                require(keccak256(node) == expectedHash, "node hash incorrect");
                node = node[offset:];

                // advance to the next proof step
                proof = proof[offset + listSize:];
            }

            // find the length of the first two elements
            uint256 size = RLP.skip(node);
            unchecked {
                size += RLP.skip(node[size:]);
            }

            // we now know which type of node we're looking at:
            // leaf + extension nodes have 2 list elements, branch nodes have 17
            if (size == node.length) {
                // only two elements, leaf or extension node
                bytes calldata encodedPath;
                (encodedPath, node) = RLP.splitBytes(node);

                // keep track of whether the key nibbles match
                bool keysMatch = true;

                // the first nibble of the encodedPath tells us the type of
                // node and if it contains an even or odd number of nibbles
                uint8 firstByte = uint8(encodedPath[0]);
                uint8 prefix = firstByte >> 4;
                require(prefix <= MAX_PREFIX);
                if (prefix & ODD_LENGTH == 0) {
                    // second nibble is padding, must be 0
                    require(firstByte & 0xf == 0);
                } else {
                    // second nibble is part of key
                    keysMatch = keysMatch && (firstByte & 0xf) == (uint8(bytes1(key)) >> 4);
                    unchecked {
                        key <<= 4;
                        keyLen--;
                    }
                }

                // check the remainder of the encodedPath
                encodedPath = encodedPath[1:];
                keysMatch = keysMatch && subkeysEqual(key, keyLen, encodedPath);
                // cannot overflow because encodedPath is from calldata
                unchecked {
                    key <<= 8 * encodedPath.length;
                    keyLen -= 2 * encodedPath.length;
                }

                if (prefix & LEAF == 0) {
                    // extension can't prove nonexistence, subkeys must match
                    require(keysMatch);

                    (expectedHash, ) = CoreTypes.parseHash(node);
                } else {
                    // leaf node, must have used all of key
                    require(keyLen == 0);

                    if (keysMatch) {
                        // if keys equal, we found the value
                        (value, node) = RLP.splitBytes(node);
                        break;
                    } else {
                        // if keys aren't equal, key doesn't exist
                        exists = false;
                        break;
                    }
                }
            } else {
                // branch node, this is the hotspot for gas usage

                // there should be 17 elements (16 branch hashes + a value)
                // we won't explicitly check this in order to save gas, since
                // it's implied by inclusion in a valid ethereum block

                // also note, we never need the value element because we assume
                // fixed length 32-byte keys, so branch nodes never hold values

                // fetch the branch for the next nibble of the key
                uint256 keyNibble = uint256(uint8(bytes1(key)) >> 4);

                // skip past the branches we don't need
                // we already skipped past 2 elements; start there if we can
                uint256 i = 0;
                if (keyNibble >= 2) {
                    i = 2;
                    node = node[size:];
                }
                while (i < keyNibble) {
                    node = node[RLP.skip(node):];
                    unchecked {
                        i++;
                    }
                }

                (expectedHash, ) = CoreTypes.parseHash(node);
                // if we've reached an empty branch, key doesn't exist
                if (expectedHash == 0) {
                    exists = false;
                    break;
                }
                unchecked {
                    key <<= 4;
                    keyLen -= 1;
                }
            }
        }
    }
}