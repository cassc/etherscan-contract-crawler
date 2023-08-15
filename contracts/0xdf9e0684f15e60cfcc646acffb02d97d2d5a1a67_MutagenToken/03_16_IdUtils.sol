//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "hardhat/console.sol";

/**
 * Utility functions and helpers for working with token IDs.
 * Token IDs are unique binary numbers that encode a token type and some properties
 * specific to that type. There are three types of tokens: Geneses, prints and Mutagens.
 */
contract IdUtils {
    /**
     * Genesis IDs are made up of (left to right):
     * - 6 bits for Genesis index (0-39)
     * - 2 bits for token type (0)
     */

    // Genesis token type flag
    uint8 constant GENESIS_TOKEN = 0; // 0b00

    uint8 constant GENESIS_IDX_OFFSET = 2;

    /**
     * @dev Pack a Genesis index into its ID
     */
    function packGenesisId(uint8 genesisIdx)
        public
        pure
        returns (uint256 tokenId)
    {
        return genesisIdx << GENESIS_IDX_OFFSET;
    }

    /**
     * @dev Unpack a Genesis ID to get its index
     */
    function unpackGenesisId(uint256 genesisId)
        public
        pure
        returns (uint8 genesisIdx)
    {
        return uint8(genesisId >> GENESIS_IDX_OFFSET);
    }

    /**
     * Print token IDs are made up of (left to right):
     * - Up to x bits for print nonce (0-...)
     * - 12 bits for print generation (0-3999)
     * - 6 bits for Genesis index
     * - 2 bits for token type (1)
     */

    uint8 constant PRINT_NONCE_OFFSET = 20;

    uint8 constant PRINT_GENERATION_OFFSET = 8;
    uint16 constant PRINT_GENERATION_MASK = 4095; // 0b111111111111

    uint8 constant PRINT_GENESIS_IDX_OFFSET = 2;
    uint8 constant PRINT_GENESIS_IDX_MASK = 63; // 0b111111

    uint8 constant PRINT_TOKEN = 1; // 0b01

    /**
     * @dev Pack print properties into a token ID
     */
    function packPrintId(
        uint8 genesisIdx,
        uint256 printNonce,
        uint16 printGeneration
    ) public pure returns (uint256 tokenId) {
        return
            (uint256(printNonce) << PRINT_NONCE_OFFSET) +
            (uint256(printGeneration) << PRINT_GENERATION_OFFSET) +
            (uint256(genesisIdx) << PRINT_GENESIS_IDX_OFFSET) +
            PRINT_TOKEN;
    }

    /**
     * @dev Unpack a print ID to its components
     */
    function unpackPrintId(uint256 printId)
        public
        pure
        returns (
            uint8 genesisIdx,
            uint256 printNonce,
            uint16 printGeneration
        )
    {
        printNonce = (printId >> PRINT_NONCE_OFFSET);
        printGeneration = uint16(
            (printId >> PRINT_GENERATION_OFFSET) & PRINT_GENERATION_MASK
        );
        genesisIdx = uint8(
            (printId >> PRINT_GENESIS_IDX_OFFSET) & PRINT_GENESIS_IDX_MASK
        );
    }

    /**
     * Mutagen token IDs are made up of (left to right):
     * - 2 bits for layer number (0-3)
     * - 7 bits for variant number (0-99)
     * - 12 bits for Mutagen index (0-3999)
     * - 2 bits for token type (2)
     */

    uint8 constant MUTAGEN_LAYER_OFFSET = 21; // 14 bits from variant offset + 7 bits from variant

    uint8 constant MUTAGEN_VARIANT_OFFSET = 14; // 2 bits from index offset + 12 bits from index
    uint8 constant MUTAGEN_VARIANT_MASK = 127; // 7 bits - 0b1111111

    uint8 constant MUTAGEN_IDX_OFFSET = 2; // 2 bits from token type
    uint16 constant MUTAGEN_IDX_MASK = 4095; // 12 bits - 0b111111111111

    uint8 constant MUTAGEN_TOKEN = 2; // 0b10

    /**
     * @dev Pack Mutagen properties into a unique ID
     */
    function packMutagenId(
        uint8 layer,
        uint8 variant,
        uint16 mutagenIdx
    ) public pure returns (uint256) {
        return
            (uint256(layer) << MUTAGEN_LAYER_OFFSET) +
            (uint256(variant) << MUTAGEN_VARIANT_OFFSET) +
            (uint256(mutagenIdx) << MUTAGEN_IDX_OFFSET) +
            MUTAGEN_TOKEN;
    }

    /**
     * @dev Unpack Mutagen ID into its properties
     */
    function unpackMutagenId(uint256 mutagenId)
        public
        pure
        returns (
            uint8 layer,
            uint8 variant,
            uint256 mutagenIdx
        )
    {
        layer = uint8(mutagenId >> MUTAGEN_LAYER_OFFSET);
        variant = uint8(
            (mutagenId >> MUTAGEN_VARIANT_OFFSET) & MUTAGEN_VARIANT_MASK
        );
        mutagenIdx = (mutagenId >> MUTAGEN_IDX_OFFSET) & MUTAGEN_IDX_MASK;
    }

    // Last two bits of a token ID represent the token type.
    // We can use this mask to quickly check for specific types.
    uint8 constant TOKEN_TYPE_MASK = 3; // 0b11

    /**
     * @dev Require that the provided token ID is the expected type
     */
    modifier isTokenType(uint256 tokenId, uint8 tokenBits) {
        require((_tokenType(tokenId)) == tokenBits, "Incorrect token type");
        _;
    }

    /**
     * @dev Get the token type flag from it's ID
     */
    function _tokenType(uint256 tokenId) internal pure returns (uint8) {
        return uint8(tokenId & TOKEN_TYPE_MASK);
    }
}