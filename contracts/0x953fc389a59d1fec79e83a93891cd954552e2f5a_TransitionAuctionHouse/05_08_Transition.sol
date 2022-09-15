// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.15;

import "./ERC721A.sol";
import "./TransitionAuctionHouse.sol";

/// [MIT License]
/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <[email protected]>
library Base64 {
    bytes internal constant TABLE =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /// @notice Encodes some bytes to the base64 representation
    function encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((len + 2) / 3);

        // Add some extra buffer at the end
        bytes memory result = new bytes(encodedLen + 32);

        bytes memory table = TABLE;

        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)

            for {
                let i := 0
            } lt(i, len) {

            } {
                i := add(i, 3)
                let input := and(mload(add(data, i)), 0xffffff)

                let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF)
                )
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF)
                )
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(input, 0x3F))), 0xFF)
                )
                out := shl(224, out)

                mstore(resultPtr, out)

                resultPtr := add(resultPtr, 4)
            }

            switch mod(len, 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }

            mstore(result, encodedLen)
        }

        return string(result);
    }
}

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding)
        internal
        pure
        returns (uint256)
    {
        unchecked {
            uint256 result = sqrt(a);
            return
                result +
                (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding)
        internal
        pure
        returns (uint256)
    {
        unchecked {
            uint256 result = log2(value);
            return
                result +
                (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding)
        internal
        pure
        returns (uint256)
    {
        unchecked {
            uint256 result = log10(value);
            return
                result +
                (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding)
        internal
        pure
        returns (uint256)
    {
        unchecked {
            uint256 result = log256(value);
            return
                result +
                (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length)
        internal
        pure
        returns (string memory)
    {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// #################################################
// #################################################
//
//                 THE TRANSITION
//
// #################################################
// #################################################

contract Transition is ERC721A {
    struct BlockData {
        uint256 chainId;
        uint256 blockNumber;
        uint256 timestamp;
        address feeRecipient;
        uint256 difficulty;
        uint256 baseFee;
    }
    BlockData public blockdata;

    address public deployer;
    uint256 public _totalSupply = 100;
    address public auctionHouse = 0x953Fc389a59d1FeC79e83A93891CD954552E2F5a;

    constructor() ERC721A("The Transition", "T-T") {
        deployer = msg.sender;
        _prime(auctionHouse, _totalSupply);
        blockdata = BlockData(block.chainid, 1, 1, auctionHouse, 1, 1);
    }

    /**
     * @dev Mints the collection
     * @param _blockNumber Block Number at which we want to mint
     */
    function mint(uint256 _blockNumber) public {
        require(block.number == _blockNumber);
        require(deployer == msg.sender);
        require(block.difficulty > 2**64 || block.difficulty == 0);
        require(blockdata.blockNumber == 1);

        blockdata.blockNumber = block.number;
        blockdata.timestamp = block.timestamp;
        blockdata.feeRecipient = block.coinbase;
        blockdata.difficulty = block.difficulty;
        blockdata.baseFee = block.basefee;

        _mintERC2309(auctionHouse, _totalSupply);
    }

    /**
     * @dev A distinct URI (RFC 3986) for a given NFT.
     * @param _tokenId Id for which we want uri.
     * @return URI of _tokenId.
     */
    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(_exists(_tokenId), "Token does not exist");
        return draw(_tokenId);
    }

    /**
     * @dev Burns `tokenId`. See {ERC721-_burn}.
     */
    function burn(uint256 _tokenId) public {
        require(_exists(_tokenId));
        require(msg.sender == ownerOf(_tokenId));
        _burn(_tokenId);
    }

    /**
     * @dev Helper function for draw(uint256)
     */
    function getspan(
        string memory x,
        string memory y,
        string memory fontsize,
        bool preserve,
        string memory c
    ) public pure returns (string memory) {
        string memory preserves = 'xml:space="preserve" ';
        if (!preserve) {
            preserves = "";
        }

        string memory tspan = string.concat(
            '<tspan x="',
            x,
            '" ',
            'y="',
            y,
            '" ',
            preserves,
            'font-size="',
            fontsize,
            '">',
            c,
            "</tspan>"
        );

        return tspan;
    }

    /**
     * @dev Renders art corresponding to _tokenId
     */
    function draw(uint256 _tokenId)
        public
        view
        virtual
        returns (string memory)
    {
        string[58] memory parts;
        uint256 i = 0;
        parts[
            i++
        ] = '<svg xmlns="http://www.w3.org/2000/svg" width="1920" height="1080"><rect width="1920" height="1080" fill="black" />';
        parts[
            i++
        ] = '<text x="320" y="60" fill="white" font-family="Courier New, Courier, monospace" font-size="24px">';

        // Panda
        parts[i++] = getspan(
            "1300",
            "122",
            "x-small",
            true,
            "         .%%%%.                                               .%HHHHHH*"
        );
        parts[i++] = getspan(
            "1300",
            "134",
            "x-small",
            true,
            "     %HHHHHHHHHHHHHHH%       .HHHHHHHHHHHHHHHHHHHHH%     .%HHHHHHHHHHHHHHHHH"
        );
        parts[i++] = getspan(
            "1300",
            "146",
            "x-small",
            true,
            "   HHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHH"
        );
        parts[i++] = getspan(
            "1300",
            "158",
            "x-small",
            true,
            " MHHHHHHHHHHHHHHHHHHHHHHHHHH*                        /HHHHHHHHHHHHHHHHHHHHHHHHHM"
        );
        parts[i++] = getspan(
            "1300",
            "170",
            "x-small",
            true,
            " HHHHHHHHHHHHHHHHHHHHHH                                    HHHHHHHHHHHHHHHHHHHHH"
        );
        parts[i++] = getspan(
            "1300",
            "182",
            "x-small",
            true,
            " HHHHHHHHHHHHHHHHHH                                            HHHHHHHHHHHHHHHHH"
        );
        parts[i++] = getspan(
            "1300",
            "194",
            "x-small",
            true,
            " HHHHHHHHHHHHHHH*                                                HHHHHHHHHHHHHHH"
        );
        parts[i++] = getspan(
            "1300",
            "206",
            "x-small",
            true,
            "  HHHHHHHHHHHH                                                     /HHHHHHHHHHH "
        );
        parts[i++] = getspan(
            "1300",
            "218",
            "x-small",
            true,
            "   HHHHHHHHH(                                                        @HHHHHHHH"
        );
        parts[i++] = getspan(
            "1300",
            "230",
            "x-small",
            true,
            "    HHHHHHH                                                            HHHHH"
        );
        parts[i++] = getspan(
            "1300",
            "242",
            "x-small",
            true,
            "     HHHHH                                                              HHHHH"
        );
        parts[i++] = getspan(
            "1300",
            "254",
            "x-small",
            true,
            "    HHHHH                                                                HHHHM"
        );
        parts[i++] = getspan(
            "1300",
            "266",
            "x-small",
            true,
            "   *HHHH            HHHHHHHHHH                    HHHHHHHHHHHHH           HHHH"
        );
        parts[i++] = getspan(
            "1300",
            "278",
            "x-small",
            true,
            "   HHHH*        HHHHHHHHHHHHHHHHH              MHHHHHHHHHHHHHHHHHH        %HHHH"
        );
        parts[i++] = getspan(
            "1300",
            "290",
            "x-small",
            true,
            "   HHHH      MHHHHHHHHH       HHHH            HHHHHH      @[email protected]      HHHH"
        );
        parts[i++] = getspan(
            "1300",
            "302",
            "x-small",
            true,
            "  (HHHH    (HHHHHHHHHH.       HHHHM           HHHHH        HHHHHHHHHHHH    HHHH."
        );
        parts[i++] = getspan(
            "1300",
            "314",
            "x-small",
            true,
            "  %HHHH   HHHHHHHHHHHHHM     HHHHH             HHHHH      HHHHHHHHHHHHHH   HHHH/"
        );
        parts[i++] = getspan(
            "1300",
            "326",
            "x-small",
            true,
            "  MHHHH  .HHHHHHHHHHHHHHHHHHHHHHH               HHHHHHHHHHHHHHHHHHHHHHHH/  HHHH*"
        );
        parts[i++] = getspan(
            "1300",
            "338",
            "x-small",
            true,
            "  ,HHHH  %HHHHHHHHHHHHHHHHHHHHH      HHHHHHHM    ,[email protected]  HHHH"
        );
        parts[i++] = getspan(
            "1300",
            "350",
            "x-small",
            true,
            "   HHHH. .HHHHHHHHHHHHHHHHHHH      HHHHHHHHHHHH     HHHHHHHHHHHHHHHHHHHH( /HHHH"
        );
        parts[i++] = getspan(
            "1300",
            "362",
            "x-small",
            true,
            "   (HHHH  (HHHHHHHHHHHHHHHH       .HHHHHHHHHHHH       HHHHHHHHHHHHHHHHHH  HHHH,"
        );
        parts[i++] = getspan(
            "1300",
            "374",
            "x-small",
            true,
            "    HHHHH   @HHHHHHHHHHH%           HHHHHHHHH           HHHHHHHHHHHHHH   HHHH%"
        );
        parts[i++] = getspan(
            "1300",
            "386",
            "x-small",
            true,
            "     HHHHH     HHHHHHH                                      HHHHHHH     HHHHH"
        );
        parts[i++] = getspan(
            "1300",
            "398",
            "x-small",
            true,
            "      [email protected]                   %HHH           (HHH                    HHHHH."
        );
        parts[i++] = getspan(
            "1300",
            "410",
            "x-small",
            true,
            "        HHHHHH                   ,HHHHHHHHHHHHHH                    HHHHHH"
        );
        parts[i++] = getspan(
            "1300",
            "422",
            "x-small",
            true,
            "          %HHHHHH                                               ,HHHHHH("
        );
        parts[i++] = getspan(
            "1300",
            "434",
            "x-small",
            true,
            "             %[email protected]                                      HHHHHHHHM"
        );
        parts[i++] = getspan(
            "1300",
            "446",
            "x-small",
            true,
            "                 HHHHHHHHHHHH*                      (HHHHHHHHHHH%"
        );
        parts[i++] = getspan(
            "1300",
            "458",
            "x-small",
            true,
            "                      (HHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHH*"
        );
        parts[i++] = getspan(
            "1300",
            "470",
            "x-small",
            true,
            "                               .M%HHHHHHHHHHHHHH%*."
        );

        // Metadata Labels
        parts[i++] = getspan("100", "650", "2em", false, "The Transition");
        parts[i++] = getspan(
            "100",
            "710",
            "1.5em",
            false,
            "Non-Fungible Ethereum Merge Token"
        );
        parts[i++] = getspan(
            "100",
            "755",
            "larger",
            true,
            "Edition           / 100"
        );
        parts[i++] = getspan("100", "795", "larger", true, "Chain ID      :");
        parts[i++] = getspan("100", "835", "larger", true, "Block Number  :");
        parts[i++] = getspan("100", "875", "larger", true, "Timestamp     :");
        parts[i++] = getspan("100", "915", "larger", true, "Fee Recipient :");
        parts[i++] = getspan("100", "955", "larger", true, "Difficulty    :");
        parts[i++] = getspan("100", "995", "larger", true, "Base Fee      :");

        // metadata values
        parts[i++] = getspan(
            "340",
            "755",
            "larger",
            false,
            Strings.toString(_tokenId + 1)
        );
        parts[i++] = getspan(
            "400",
            "795",
            "larger",
            false,
            Strings.toString(blockdata.chainId)
        );
        parts[i++] = getspan(
            "400",
            "835",
            "larger",
            false,
            Strings.toString(blockdata.blockNumber)
        );
        parts[i++] = getspan(
            "400",
            "875",
            "larger",
            false,
            Strings.toString(blockdata.timestamp)
        );
        parts[i++] = getspan(
            "400",
            "915",
            "larger",
            false,
            Strings.toHexString(blockdata.feeRecipient)
        );
        parts[i++] = getspan(
            "400",
            "955",
            "larger",
            false,
            Strings.toString(blockdata.difficulty)
        );
        parts[i++] = getspan(
            "400",
            "995",
            "larger",
            false,
            Strings.toString(blockdata.baseFee)
        );
        parts[i++] = "</text></svg>";

        string memory art = string(
            abi.encodePacked(
                parts[0],
                parts[1],
                parts[2],
                parts[3],
                parts[4],
                parts[5],
                parts[6],
                parts[7],
                parts[8]
            )
        );
        art = string(
            abi.encodePacked(
                art,
                parts[9],
                parts[10],
                parts[11],
                parts[12],
                parts[13],
                parts[14],
                parts[15],
                parts[16]
            )
        );
        art = string(
            abi.encodePacked(
                art,
                parts[17],
                parts[18],
                parts[19],
                parts[20],
                parts[21],
                parts[22],
                parts[23],
                parts[24]
            )
        );
        art = string(
            abi.encodePacked(
                art,
                parts[25],
                parts[26],
                parts[27],
                parts[28],
                parts[29],
                parts[30],
                parts[31],
                parts[32]
            )
        );
        art = string(
            abi.encodePacked(
                art,
                parts[33],
                parts[34],
                parts[35],
                parts[36],
                parts[37],
                parts[38],
                parts[39],
                parts[40]
            )
        );
        art = string(
            abi.encodePacked(
                art,
                parts[41],
                parts[42],
                parts[43],
                parts[44],
                parts[45],
                parts[46],
                parts[47],
                parts[48]
            )
        );
        art = string(
            abi.encodePacked(
                art,
                parts[49],
                parts[50],
                parts[51],
                parts[52],
                parts[53],
                parts[54],
                parts[55],
                parts[56]
            )
        );
        string memory output = string(abi.encodePacked(art, parts[57]));
        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "The Transition #',
                        Strings.toString(_tokenId + 1),
                        '", "description": "A Non-Fungible Ethereum Merge Token.", "external_url": "https://thetransition.wtf", "image": "data:image/svg+xml;base64,',
                        Base64.encode(bytes(output)),
                        '"}'
                    )
                )
            )
        );
        return string(abi.encodePacked("data:application/json;base64,", json));
    }
}