// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8;

// solhint-disable no-inline-assembly, no-empty-blocks

/// @title FeistelShuffle
/// @author kevincharm
/// @notice Implementation of a Feistel shuffle, adapted from vbuterin's python implementation [1].
///     [1]: https://github.com/ethereum/research/blob/master/shuffling/feistel_shuffle.py
library FeistelShuffle {
    /// @notice Compute the bijective mapping of `x` using a Feistel shuffle
    /// @param x index of element in the list
    /// @param modulus cardinality of list
    /// @param seed random seed to (re-)produce the mapping
    /// @param rounds number of Feistel rounds
    /// @return resulting shuffled/permuted index
    function getPermutedIndex(
        uint256 x,
        uint256 modulus,
        uint256 seed,
        uint256 rounds
    ) internal pure returns (uint256) {
        modulus ** (rounds - 1); // lazy checked exponentiation
        assembly {
            // Assert some preconditions
            // (x < modulus): index to be permuted must lie within the domain of [0, modulus)
            let xGteModulus := gt(x, sub(modulus, 1))
            // (modulus != 0): domain must be non-zero (value of 1 also doesn't really make sense)
            let modulusZero := iszero(modulus)
            if or(xGteModulus, modulusZero) {
                revert(0, 0)
            }

            // Calculate sqrt(s) using Babylonian method
            function sqrt(s) -> z {
                switch gt(s, 3)
                // if (s > 3)
                case 1 {
                    z := s
                    let r := add(div(s, 2), 1)

                    for {

                    } lt(r, z) {

                    } {
                        z := r
                        r := div(add(div(s, r), r), 2)
                    }
                }
                default {
                    if iszero(iszero(s)) {
                        // else if (s != 0)
                        z := 1
                    }
                }
            }

            // nps <- nextPerfectSquare(modulus)
            let sqrtN := sqrt(modulus)
            let nps
            switch eq(exp(sqrtN, 2), modulus)
            case 1 {
                nps := modulus
            }
            default {
                let sqrtN1 := add(sqrtN, 1)
                // pre-check for square overflow
                if gt(sqrtN1, sub(exp(2, 128), 1)) {
                    // overflow
                    revert(0, 0)
                }
                nps := exp(sqrtN1, 2)
            }
            // h <- sqrt(nps)
            let h := sqrt(nps)
            // Perform Feistel rounds until result is in the correct domain
            // i.e. Loop until x < modulus
            for {

            } 1 {

            } {
                let L := div(x, h)
                let R := mod(x, h)
                // Loop for desired number of rounds
                for {
                    let r := 0
                } lt(r, rounds) {
                    r := add(r, 1)
                } {
                    // Load R and seed for next keccak256 round into scratch space
                    mstore(0, R)
                    mstore(0x20, seed)
                    // roundHash <- (keccak256(R,seed) / (modulus**r)) % modulus
                    let roundHash := mod(
                        div(keccak256(0, 0x40), exp(modulus, r)),
                        modulus
                    )
                    let newR := mod(add(L, roundHash), h)
                    L := R
                    R := newR
                }
                x := add(mul(L, h), R)
                if lt(x, modulus) {
                    break
                }
            }
        }
        return x;
    }
}