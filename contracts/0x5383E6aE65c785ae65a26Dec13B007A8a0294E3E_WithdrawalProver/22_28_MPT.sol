/// SPDX-License-Identifier: UNLICENSED
/// (c) Theori, Inc. 2022
/// All rights reserved

/**
 * @title MPT
 * @author Theori, Inc.
 * @notice Implements proof checking for Ethereum Merkle-Patricia Tries.
 *         To save gas, it assumes nodes are validly structured,
 *         so soundness is only guaranteed if the rootHash belongs
 *         to a valid ethereum block.
 */

pragma solidity >=0.8.0;

import "./RLP.sol";
import "./CoreTypes.sol";
import "./BytesCalldata.sol";

library MPT {
    using BytesCalldataOps for bytes;

    struct Node {
        BytesCalldata data;
        bytes32 hash;
    }

    // prefix constants
    uint8 constant ODD_LENGTH = 1;
    uint8 constant LEAF = 2;
    uint8 constant MAX_PREFIX = 3;

    /**
     * @notice parses concatenated MPT nodes into processed Node structs
     * @param input the concatenated MPT nodes
     * @return result the parsed nodes array, containing a calldata slice and hash
     *                for each node
     */
    function parseNodes(bytes calldata input) internal pure returns (Node[] memory result) {
        uint256 freePtr;
        uint256 firstNode;

        // we'll use a dynamic amount of memory starting at the free pointer
        // it is crucial that no other allocations happen during parsing
        assembly {
            freePtr := mload(0x40)

            // corrupt free pointer to cause out-of-gas if allocation occurs
            mstore(0x40, 0xcccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc)

            firstNode := freePtr
        }

        uint256 count;
        while (input.length > 0) {
            (uint256 listsize, uint256 offset) = RLP.parseList(input);
            bytes calldata node = input.slice(offset, listsize);
            BytesCalldata slice = node.convert();

            uint256 len;
            assembly {
                len := add(listsize, offset)

                // compute node hash
                calldatacopy(freePtr, input.offset, len)
                let nodeHash := keccak256(freePtr, len)

                // store the Node struct (calldata slice and hash)
                mstore(freePtr, slice)
                mstore(add(freePtr, 0x20), nodeHash)

                // advance pointer
                count := add(count, 1)
                freePtr := add(freePtr, 0x40)
            }

            input = input.suffix(len);
        }

        assembly {
            // allocate the result array and fill it with the node pointers
            result := freePtr
            mstore(result, count)
            freePtr := add(freePtr, 0x20)
            for {
                let i := 0
            } lt(i, count) {
                i := add(i, 1)
            } {
                mstore(freePtr, add(firstNode, mul(0x40, i)))
                freePtr := add(freePtr, 0x20)
            }

            // update the free pointer
            mstore(0x40, freePtr)
        }
    }

    /**
     * @notice parses a compressed MPT proof into arrays of Node structs
     * @param nodes the set of nodes used in the compressed proofs
     * @param compressed the compressed MPT proof
     * @param count the number of proofs expected from the compressed proof
     * @return result the array of proofs
     */
    function parseCompressedProofs(
        Node[] memory nodes,
        bytes calldata compressed,
        uint256 count
    ) internal pure returns (Node[][] memory result) {
        uint256 resultPtr;
        uint256 freePtr;

        // we'll use a dynamic amount of memory starting at the free pointer
        // it is crucial that no other allocations happen during parsing
        assembly {
            result := mload(0x40)

            // corrupt free pointer to cause out-of-gas if allocation occurs
            mstore(0x40, 0xcccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc)

            mstore(result, count)
            resultPtr := add(result, 0x20)
            freePtr := add(resultPtr, mul(0x20, count))
        }

        (uint256 listSize, uint256 offset) = RLP.parseList(compressed);
        compressed = compressed.slice(offset, listSize);

        // parse the indices and populate the proof list
        for (; count > 0; count--) {
            bytes calldata indices;
            (listSize, offset) = RLP.parseList(compressed);
            indices = compressed.slice(offset, listSize);
            compressed = compressed.suffix(listSize + offset);

            // begin next proof array
            uint256 arr;
            assembly {
                arr := freePtr
                freePtr := add(freePtr, 0x20)
            }

            // fill proof array
            uint256 len;
            for (len = 0; indices.length > 0; len++) {
                uint256 idx;
                (idx, offset) = RLP.parseUint(indices);
                indices = indices.suffix(offset);
                require(idx < nodes.length, "invalid node index in compressed proof");
                assembly {
                    let node := mload(add(add(nodes, 0x20), mul(0x20, idx)))
                    mstore(freePtr, node)
                    freePtr := add(freePtr, 0x20)
                }
            }

            assembly {
                // store the array length
                mstore(arr, len)

                // store the array pointer in the result
                mstore(resultPtr, arr)
                resultPtr := add(resultPtr, 0x20)
            }
        }

        assembly {
            // update the free pointer
            mstore(0x40, freePtr)
        }
    }

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
     * @param nodes MPT proof nodes, parsed using parseNodes()
     * @param key the MPT key, padded with trailing 0s if needed
     * @param keyLen the byte length of the MPT key, must be <= 32
     * @param expectedHash the root hash of the MPT
     */
    function verifyTrieValueWithNodes(
        Node[] memory nodes,
        bytes32 key,
        uint256 keyLen,
        bytes32 expectedHash
    ) internal pure returns (bool exists, bytes calldata value) {
        // handle completely empty trie case
        if (nodes.length == 0) {
            require(keccak256(hex"80") == expectedHash, "root hash incorrect");
            return (false, msg.data[:0]);
        }

        // we will read the key nibble by nibble, so double the length
        unchecked {
            keyLen *= 2;
        }

        // initialize return values to make solc happy;
        // one will always be overwritten before returing
        assembly {
            value.offset := 0
            value.length := 0
        }
        exists = true;

        // we'll use nodes as a pointer, advancing through each element
        // end will point to the end of the array
        uint256 end;
        assembly {
            end := add(nodes, add(0x20, mul(0x20, mload(nodes))))
            nodes := add(nodes, 0x20)
        }

        while (true) {
            bytes calldata node;
            {
                BytesCalldata slice;
                bytes32 nodeHash;

                // load the element and advance the proof pointer
                assembly {
                    // bounds checking
                    if iszero(lt(nodes, end)) {
                        revert(0, 0)
                    }

                    let ptr := mload(nodes)
                    nodes := add(nodes, 0x20)

                    slice := mload(ptr)
                    nodeHash := mload(add(ptr, 0x20))
                }
                node = slice.convert();

                require(nodeHash == expectedHash, "node hash incorrect");
            }

            // find the length of the first two elements
            uint256 size = RLP.nextSize(node);
            unchecked {
                size += RLP.nextSize(node.suffix(size));
            }

            // we now know which type of node we're looking at:
            // leaf + extension nodes have 2 list elements, branch nodes have 17
            if (size == node.length) {
                // only two elements, leaf or extension node
                bytes calldata encodedPath;
                (encodedPath, node) = RLP.splitBytes(node);

                // keep track of whether the key nibbles match
                bool keysMatch;

                // the first nibble of the encodedPath tells us the type of
                // node and if it contains an even or odd number of nibbles
                uint8 firstByte = uint8(encodedPath[0]);
                uint8 prefix = firstByte >> 4;
                require(prefix <= MAX_PREFIX);
                if (prefix & ODD_LENGTH == 0) {
                    // second nibble is padding, must be 0
                    require(firstByte & 0xf == 0);
                    keysMatch = true;
                } else {
                    // second nibble is part of key
                    keysMatch = (firstByte & 0xf) == (uint8(bytes1(key)) >> 4);
                    unchecked {
                        key <<= 4;
                        keyLen--;
                    }
                }

                // check the remainder of the encodedPath
                encodedPath = encodedPath.suffix(1);
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
                // uniquely-prefixed keys, so branch nodes never hold values

                // fetch the branch for the next nibble of the key
                uint256 keyNibble = uint256(key >> 252);

                // skip past the branches we don't need
                // we already skipped past 2 elements; start there if we can
                uint256 i = 0;
                if (keyNibble >= 2) {
                    i = 2;
                    node = node.suffix(size);
                }
                while (i < keyNibble) {
                    node = RLP.skip(node);
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
        Node[] memory nodes = parseNodes(proof);
        return verifyTrieValueWithNodes(nodes, key, keyLen, rootHash);
    }
}