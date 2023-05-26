// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.14;

/// @title  AlphaDogs Gene Library
/// @author Aleph Retamal <github.com/alephao>
/// @notice Library containing functions for querying info about a gene.
library Gene {
    /// @notice A gene is puppy if its 8th byte is greater than 0
    function isPuppy(uint256 gene) internal pure returns (bool) {
        return (gene & 0xFF00000000000000) > 0;
    }

    /// @notice Get a specific chromossome in a gene, first position is 0
    function getChromossome(uint256 gene, uint32 position)
        internal
        pure
        returns (uint256)
    {
        unchecked {
            uint32 shift = 8 * position;
            return (gene & (0xFF << shift)) >> shift;
        }
    }

    function getBackground(uint256 gene) internal pure returns (uint256) {
        return getChromossome(gene, 6);
    }

    function getFur(uint256 gene) internal pure returns (uint256) {
        return getChromossome(gene, 5);
    }

    function getNeck(uint256 gene) internal pure returns (uint256) {
        return getChromossome(gene, 4);
    }

    function getEyes(uint256 gene) internal pure returns (uint256) {
        return getChromossome(gene, 3);
    }

    function getHat(uint256 gene) internal pure returns (uint256) {
        return getChromossome(gene, 2);
    }

    function getMouth(uint256 gene) internal pure returns (uint256) {
        return getChromossome(gene, 1);
    }

    function getNosering(uint256 gene) internal pure returns (uint256) {
        return getChromossome(gene, 0);
    }
}