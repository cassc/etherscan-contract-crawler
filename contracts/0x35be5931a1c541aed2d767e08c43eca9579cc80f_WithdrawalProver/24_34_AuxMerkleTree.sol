/// SPDX-License-Identifier: UNLICENSED
/// (c) Theori, Inc. 2022
/// All rights reserved

pragma solidity >=0.8.0;

import "./AnemoiJive.sol";

/**
 * @title Auxiliary Merkle Tree
 * @author Theori, Inc.
 * @notice Gas optimized arithmetic-friendly merkle tree code.
 * @dev uses Anemoi / Jive 2-to-1
 */
library AuxMerkleTree {
    /**
     * @notice computes a jive merkle root of the provided hashes, in place
     * @param temp the mutable array of hashes
     * @return root the merkle root hash
     */
    function computeRoot(bytes32[] memory temp) internal view returns (bytes32 root) {
        uint256 count = temp.length;
        while (count > 1) {
            unchecked {
                for (uint256 i = 0; i < count / 2; i++) {
                    uint256 x;
                    uint256 y;
                    assembly {
                        let ptr := add(temp, add(0x20, mul(0x40, i)))
                        x := mload(ptr)
                        ptr := add(ptr, 0x20)
                        y := mload(ptr)
                    }
                    x = AnemoiJive.compress(x, y);
                    assembly {
                        mstore(add(temp, add(0x20, mul(0x20, i))), x)
                    }
                }
                count >>= 1;
            }
        }
        return temp[0];
    }
}