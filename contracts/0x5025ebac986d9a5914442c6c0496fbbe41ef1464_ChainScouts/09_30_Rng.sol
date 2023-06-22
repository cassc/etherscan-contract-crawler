//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title A pseudo random number generator
 *
 * @dev This is not a true random number generator because smart contracts must be deterministic (every node a transaction goes to must produce the same result).
 *      True randomness requires an oracle which is both expensive in terms of gas and would take a critical part of the project off the chain.
 */
struct Rng {
    bytes32 state;
}

/**
 * @title A library for working with the Rng struct.
 *
 * @dev Rng cannot be a contract because then anyone could manipulate it by generating random numbers.
 */
library RngLibrary {
    /**
     * Creates a new Rng.
     */
    function newRng() internal view returns (Rng memory) {
        return Rng(getEntropy());
    }

    /**
     * Creates a pseudo-random value from the current block miner's address and sender.
     */
    function getEntropy() internal view returns (bytes32) {
        return keccak256(abi.encodePacked(block.coinbase, msg.sender));
    }

    /**
     * Generates a random uint256.
     */
    function generate(Rng memory self) internal view returns (uint256) {
        self.state = keccak256(abi.encodePacked(getEntropy(), self.state));
        return uint256(self.state);
    }

    /**
     * Generates a random uint256 from min to max inclusive.
     *
     * @dev This function is not subject to modulo bias.
     *      The chance that this function has to reroll is astronomically unlikely, but it can theoretically reroll forever.
     */
    function generate(Rng memory self, uint min, uint max) internal view returns (uint256) {
        require(min <= max, "min > max");

        uint delta = max - min;

        if (delta == 0) {
            return min;
        }

        return generate(self) % (delta + 1) + min;
    }
}