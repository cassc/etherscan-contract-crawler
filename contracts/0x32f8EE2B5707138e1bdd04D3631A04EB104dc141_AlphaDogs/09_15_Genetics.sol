// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.14;

import {Chromossomes} from "./Chromossomes.sol";

/// @title  AlphaDogs Genetics Library
/// @author Aleph Retamal <github.com/alephao>, Gustavo Tiago <github.com/gutiago>
/// @notice Library containing functions for creating and manipulating genes.
///
/// ### Creating a new gene
///
/// • When creating a new gene, we get a pseudo-random seed derive other seeds for each trait
/// • We're using A.J. Walker Alias Algorithm to pick traits with pre-defined rarity table
///   these are the weird hard-coded arrays in the `seedTo{Trait}` functions
/// • Note: we use a pseudo-random seed, meaning that the result can be somewhat manipulated
///   by mad-scientists of the chain.
///
/// ### Breeding
///
/// • For breeding we use uniform cross-over algorithm which is commonly used
///   in genetic algorithms. We walk throught each chromossome, picking from either mom or dad.
library Genetics {
    /// @dev    Generate genes from a seed
    ///
    ///         • Start with                  0x0
    ///         • Add background chromossome  0x77 = 0x0 + 0x77
    ///         • Shift 1 byte to the left    0x7700 = 0x77 << 8
    ///         • Add fur chromossome         0x7766 = 0x7700 + 0x66
    ///         • Same for each chromossome
    function generateGenes(uint256 seed) internal pure returns (uint256 genes) {
        genes |= Chromossomes.seedToBackground(seed);
        genes <<= 8;

        genes |= Chromossomes.seedToFur(seed);
        genes <<= 8;

        genes |= Chromossomes.seedToNeck(seed);
        genes <<= 8;

        genes |= Chromossomes.seedToEyes(seed);
        genes <<= 8;

        genes |= Chromossomes.seedToHat(seed);
        genes <<= 8;

        genes |= Chromossomes.seedToMouth(seed);
        genes <<= 8;

        genes |= Chromossomes.seedToNosering(seed);
    }

    /// @dev Increments the gene i in n (big endian/from right to left)
    ///
    /// ### Examples
    ///
    /// • incrementByte(0x110000, 0) = 0x110001
    /// • incrementByte(0x110000, 1) = 0x110100
    /// • incrementByte(0x110000, 2) = 0x120000
    ///
    /// ### A more readable version of the code
    ///
    /// unchecked {
    ///   uint256 shift = (i % 7) * 8;
    ///   uint256 mask = 0xFF << shift;
    ///   uint256 trait = gene & mask;
    ///   uint256 traitRaw = trait >> shift;
    ///   uint256 newTrait = (traitRaw + 1) % [4, 28, 11, 70, 36, 10, 21][i];
    ///   uint256 tokenIdWithoutOldTrait = ~mask & gene;
    ///   uint256 newGene = tokenIdWithoutOldTrait | (newTrait << shift);
    /// }
    ///
    /// ### Step by step explanation
    ///
    /// Explaining this for devs that look into other contracts to learn stuff like myself
    ///
    /// ### Glossary
    /// • Every 2 positions in an hexadecimal representation of a number = 1 byte
    ///   E.g.: In 0x112233, 11 is a byte, 22 is another byte, 33 is another byte
    /// • Zeros on the left can be ignored so 0x00011 = 0x11, using them here to make
    ///   it easier to see the math
    /// • 1 byte = 8 bits, so 0x1 << 8 will move 1 byte to the left (2 positions) resulting in 0x100
    ///
    /// In this example we have 0x1111221111 and want to increment `22` to `23`
    ///
    /// 1. Create a mask to get only the 22
    ///
    /// 0x1111221111 (gene)
    /// AND
    /// 0x0000FF0000 (mask)
    /// =
    /// 0x0000220000 (result)
    ///
    /// 2. Shift the byte "22" to the least significant byte, so we can increment
    ///
    /// 0x220000 >> (8 * 2) = 0x22
    ///
    /// 3. Increment
    ///
    /// 0x22 + 1 = 0x23. We're also checking against the amount of variants a trait has, that's why
    /// we're doing (byte + 1) % [X, X, X][i]
    ///
    /// 4. Move the byte back to its original position
    ///
    /// 0x23 << (8 * 2) = 0x230000
    ///
    /// 5. Invert the original mask to get all original bytes except the position we're manipulating
    ///
    /// ~0x0000FF0000 = 0xFFFF00FFFF
    ///
    /// 0xFFFF00FFFF
    /// AND
    /// 0x1111221111
    /// =
    /// 0x1111001111
    ///
    /// 6. Put the incremented byte back in the original value
    ///
    /// 0x1111001111
    /// OR
    /// 0x0000230000
    /// =
    /// 0x1111231111
    function incrementByte(uint256 gene, uint256 i)
        internal
        pure
        returns (uint256)
    {
        unchecked {
            // Number of bytes to shift, should be between 0 and 7
            uint256 shift = (i % 7) * 8;

            // Create the mask to do all the stuff mentioned in natspec
            uint256 mask = 0xFF << shift;
            return
                (~mask & gene) |
                (((((gene & mask) >> shift) + 1) %
                    [4, 28, 11, 70, 36, 10, 21][i % 7]) << shift);
        }
    }

    /// @dev    Uniform cross-over two "uint7", returns a "uint8" because a child has an extra byte
    /// @param  mom genes from mom
    /// @param  dad genes from dad
    /// @param  seed the seed is used to pick chromossomes between dad and mom.
    ///
    /// @dev If a specific byte in the seed is even, picks mom, otherwise picks dad.
    ///
    /// ### Examples
    ///
    /// • uniformCrossOver(0x11111111111111, 0x22222222222222, 0x0) = 0x0111111111111111
    /// • uniformCrossOver(0x11111111111111, 0x22222222222222, 0x1) = 0x0111111111111122
    /// • uniformCrossOver(0x11111111111111, 0x22222222222222, 0x0101) = 0x0111111111112222
    /// • uniformCrossOver(0x11111111111111, 0x22222222222222, 0x010101) = 0x0111111111222222
    /// • uniformCrossOver(0x11111111111111, 0x22222222222222, 0x01000100010001) = 0x0122112211221122
    function uniformCrossOver(
        uint256 mom,
        uint256 dad,
        uint256 seed
    ) internal pure returns (uint256) {
        unchecked {
            uint256 child = 0x0100000000000000;
            for (uint256 i = 0; i < 7; i++) {
                // Choose mom or dad to pick the chromossome from
                // If the byte on seed is even, pick mom
                uint256 chromossome = ((seed >> (8 * i)) & 0xFF) % 2 == 0
                    ? mom
                    : dad;

                // Create a mask to pick only the current byte/chromossome
                // E.g.: 3rd byte = 0xFF0000
                uint256 mask = 0xFF << (8 * i);

                // Add byte/chromossome to the child
                child |= (chromossome & mask);
            }

            return child;
        }
    }
}