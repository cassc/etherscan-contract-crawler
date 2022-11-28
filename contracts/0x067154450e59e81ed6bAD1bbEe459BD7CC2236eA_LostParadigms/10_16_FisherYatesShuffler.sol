// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

/// @title FisherYatesShuffler
/// @author dievardump (https://twitter.com/dievardump, [email protected])
contract FisherYatesShuffler {
    /// @notice Uses FisherYates and `seed` to shuffle an array containing all integers in [0, `amount`[
    /// @dev this should only be called off-chain. It easily costs 15+ million gas for 10k items
    /// @param seed the seed to use for the shuffle
    /// @param amount the amount of ids wanted
    /// @return an array containing all integers in [0, amount[, shuffled.
    function shuffle(uint256 seed, uint256 amount)
        public
        pure
        returns (uint256[] memory)
    {
        uint256[] memory permutations = new uint256[](amount);
        uint256[] memory result = new uint256[](amount);

        uint256 perm;
        uint256 value;
        uint256 index;

        uint256 indexes = amount;

        for (uint256 i; i < amount; i++) {
            seed = uint256(keccak256(abi.encodePacked(seed, i)));
            index = seed % indexes;

            value = permutations[index];
            perm = permutations[indexes - 1];

            result[i] = value == 0 ? index : value - 1;
            permutations[index] = perm == 0 ? indexes : perm;

            indexes--;
        }

        return result;
    }
}