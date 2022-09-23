// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

/// @title Merkle Base
/// @author Modified from Murky (https://github.com/dmfxyz/murky/blob/main/src/common/MurkyBase.sol)
/// @notice Utility contract for generating merkle roots and verifying proofs
abstract contract MerkleBase {
    constructor() {}

    /// @notice Hashes two leaf pairs
    /// @param _left Node on left side of tree level
    /// @param _right Node on right side of tree level
    /// @return data Result hash of node params
    function hashLeafPairs(bytes32 _left, bytes32 _right) public pure returns (bytes32 data) {
        // Return opposite node if checked node is of bytes zero value
        if (_left == bytes32(0)) return _right;
        if (_right == bytes32(0)) return _left;

        assembly {
            // TODO: This can be aesthetically simplified with a switch. Not sure it will
            // save much gas but there are other optimizations to be had in here.
            if or(lt(_left, _right), eq(_left, _right)) {
                mstore(0x0, _left)
                mstore(0x20, _right)
            }
            if gt(_left, _right) {
                mstore(0x0, _right)
                mstore(0x20, _left)
            }
            data := keccak256(0x0, 0x40)
        }
    }

    /// @notice Verifies the merkle proof of a given value
    /// @param _root Hash of merkle root
    /// @param _proof Merkle proof
    /// @param _valueToProve Leaf node being proven
    /// @return Status of proof verification
    function verifyProof(
        bytes32 _root,
        bytes32[] memory _proof,
        bytes32 _valueToProve
    ) public pure returns (bool) {
        // proof length must be less than max array size
        bytes32 rollingHash = _valueToProve;
        unchecked {
            for (uint256 i = 0; i < _proof.length; ++i) {
                rollingHash = hashLeafPairs(rollingHash, _proof[i]);
            }
        }
        return _root == rollingHash;
    }

    /// @notice Generates the merkle root of a tree
    /// @param _data Leaf nodes of the merkle tree
    /// @return Hash of merkle root
    function getRoot(bytes32[] memory _data) public pure returns (bytes32) {
        require(_data.length > 1, "wont generate root for single leaf");
        while (_data.length > 1) {
            _data = hashLevel(_data);
        }
        return _data[0];
    }

    /// @notice Generates the merkle proof for a leaf node in a given tree
    /// @param _data Leaf nodes of the merkle tree
    /// @param _node Index of the node in the tree
    /// @return Merkle proof
    function getProof(bytes32[] memory _data, uint256 _node)
        public
        pure
        returns (bytes32[] memory)
    {
        require(_data.length > 1, "wont generate proof for single leaf");
        // The size of the proof is equal to the ceiling of log2(numLeaves)
        uint256 size = log2ceil_naive(_data.length);
        bytes32[] memory result = new bytes32[](size);
        uint256 pos;
        uint256 counter;

        // Two overflow risks: node, pos
        // node: max array size is 2**256-1. Largest index in the array will be 1 less than that. Also,
        // for dynamic arrays, size is limited to 2**64-1
        // pos: pos is bounded by log2(data.length), which should be less than type(uint256).max
        while (_data.length > 1) {
            unchecked {
                if (_node % 2 == 1) {
                    result[pos] = _data[_node - 1];
                } else if (_node + 1 == _data.length) {
                    result[pos] = bytes32(0);
                    ++counter;
                } else {
                    result[pos] = _data[_node + 1];
                }
                ++pos;
                _node = _node / 2;
            }
            _data = hashLevel(_data);
        }

        // Dynamic array to filter out address(0) since proof size is rounded up
        // This is done to return the actual proof size of the indexed node
        bytes32[] memory arr = new bytes32[](size - counter);
        unchecked {
            uint256 offset;
            for (uint256 i; i < result.length; ++i) {
                if (result[i] != bytes32(0)) {
                    arr[i - offset] = result[i];
                } else {
                    ++offset;
                }
            }
        }

        return arr;
    }

    /// @dev Hashes nodes at the given tree level
    /// @param _data Nodes at the current level
    /// @return result Hashes of nodes at the next level
    function hashLevel(bytes32[] memory _data) private pure returns (bytes32[] memory result) {
        // Function is private, and all internal callers check that data.length >=2.
        // Underflow is not possible as lowest possible value for data/result index is 1
        // overflow should be safe as length is / 2 always.
        unchecked {
            uint256 length = _data.length;
            if (length & 0x1 == 1) {
                result = new bytes32[](length / 2 + 1);
                result[result.length - 1] = hashLeafPairs(_data[length - 1], bytes32(0));
            } else {
                result = new bytes32[](length / 2);
            }

            // pos is upper bounded by data.length / 2, so safe even if array is at max size
            uint256 pos;
            for (uint256 i; i < length - 1; i += 2) {
                result[pos] = hashLeafPairs(_data[i], _data[i + 1]);
                ++pos;
            }
        }
    }

    /// @notice Calculates proof size based on size of tree
    /// @dev Note that x is assumed > 0 and proof size is not precise
    /// @param x Size of the merkle tree
    /// @return ceil Rounded value of proof size
    function log2ceil_naive(uint256 x) public pure returns (uint256 ceil) {
        uint256 pOf2;
        // If x is a power of 2, then this function will return a ceiling
        // that is 1 greater than the actual ceiling. So we need to check if
        // x is a power of 2, and subtract one from ceil if so.
        assembly {
            // we check by seeing if x == (~x + 1) & x. This applies a mask
            // to find the lowest set bit of x and then checks it for equality
            // with x. If they are equal, then x is a power of 2.

            /* Example
                x has single bit set
                x := 0000_1000
                (~x + 1) = (1111_0111) + 1 = 1111_1000
                (1111_1000 & 0000_1000) = 0000_1000 == x
                x has multiple bits set
                x := 1001_0010
                (~x + 1) = (0110_1101 + 1) = 0110_1110
                (0110_1110 & x) = 0000_0010 != x
            */

            // we do some assembly magic to treat the bool as an integer later on
            pOf2 := eq(and(add(not(x), 1), x), x)
        }

        // if x == type(uint256).max, than ceil is capped at 256
        // if x == 0, then pO2 == 0, so ceil won't underflow
        unchecked {
            while (x > 0) {
                x >>= 1;
                ceil++;
            }
            ceil -= pOf2; // see above
        }
    }
}