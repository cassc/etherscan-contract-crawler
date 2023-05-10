// SPDX-License-Identifier: MIT
// modified from OpenZeppelin Contracts (last updated v4.8.0) (utils/structs/BitMaps.sol)
pragma solidity ^0.8.0;

/**
 * @dev Library for managing uint256 to bool mapping in a compact and efficient way, providing the keys are sequential.
 * Largely inspired by Uniswap's https://github.com/Uniswap/merkle-distributor/blob/master/contracts/MerkleDistributor.sol[merkle-distributor].
 */
library BitMap {
    struct Instance {
        uint256 _data;
    }

    /**
     * @dev Returns whether the bit at `index` is set.
     */
    function get(Instance storage self, uint8 index) internal view returns (bool) {
        uint256 mask = 1 << index;
        return self._data & mask != 0;
    }

    /**
     * @dev Sets the bit at `index`.
     */
    function set(Instance storage self, uint8 index) internal {
        uint256 mask = 1 << index;
        self._data |= mask;
    }

    /**
     * @dev Unsets the bit at `index`.
     */
    function unset(Instance storage self, uint8 index) internal {
        uint256 mask = 1 << index;
        self._data &= ~mask;
    }
}