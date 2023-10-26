/**
 *Submitted for verification at Etherscan.io on 2023-10-06
*/

// File: @openzeppelin/contracts/utils/math/SignedMath.sol
// OpenZeppelin Contracts (last updated v5.0.0) (utils/math/SignedMath.sol)

pragma solidity ^0.8.20;

/**
 * @dev Standard signed math utilities missing in the Solidity language.
 */
library SignedMath {
    /**
     * @dev Returns the largest of two signed numbers.
     */
    function max(int256 a, int256 b) internal pure returns (int256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two signed numbers.
     */
    function min(int256 a, int256 b) internal pure returns (int256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two signed numbers without overflow.
     * The result is rounded towards zero.
     */
    function average(int256 a, int256 b) internal pure returns (int256) {
        // Formula from the book "Hacker's Delight"
        int256 x = (a & b) + ((a ^ b) >> 1);
        return x + (int256(uint256(x) >> 255) & (a ^ b));
    }

    /**
     * @dev Returns the absolute unsigned value of a signed value.
     */
    function abs(int256 n) internal pure returns (uint256) {
        unchecked {
            // must be unchecked in order to support `n = type(int256).min`
            return uint256(n >= 0 ? n : -n);
        }
    }
}

// File: @openzeppelin/contracts/utils/math/Math.sol


// OpenZeppelin Contracts (last updated v5.0.0) (utils/math/Math.sol)

pragma solidity ^0.8.20;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Muldiv operation overflow.
     */
    error MathOverflowedMulDiv();

    enum Rounding {
        Floor, // Toward negative infinity
        Ceil, // Toward positive infinity
        Trunc, // Toward zero
        Expand // Away from zero
    }

    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
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
     * This differs from standard division with `/` in that it rounds towards infinity instead
     * of rounding towards zero.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        if (b == 0) {
            // Guarantee the same behavior as in a regular Solidity division.
            return a / b;
        }

        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or
     * denominator == 0.
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv) with further edits by
     * Uniswap Labs also under MIT license.
     */
    function mulDiv(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0 = x * y; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                // Solidity will revert if denominator == 0, unlike the div opcode on its own.
                // The surrounding unchecked block does not change this fact.
                // See https://docs.soliditylang.org/en/latest/control-structures.html#checked-or-unchecked-arithmetic.
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            if (denominator <= prod1) {
                revert MathOverflowedMulDiv();
            }

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

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator.
            // Always >= 1. See https://cs.stackexchange.com/q/138556/92363.

            uint256 twos = denominator & (0 - denominator);
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

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also
            // works in modular arithmetic, doubling the correct bits in each step.
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
    function mulDiv(uint256 x, uint256 y, uint256 denominator, Rounding rounding) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (unsignedRoundsUp(rounding) && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded
     * towards zero.
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
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (unsignedRoundsUp(rounding) && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2 of a positive value rounded towards zero.
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
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (unsignedRoundsUp(rounding) && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10 of a positive value rounded towards zero.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10 ** 64) {
                value /= 10 ** 64;
                result += 64;
            }
            if (value >= 10 ** 32) {
                value /= 10 ** 32;
                result += 32;
            }
            if (value >= 10 ** 16) {
                value /= 10 ** 16;
                result += 16;
            }
            if (value >= 10 ** 8) {
                value /= 10 ** 8;
                result += 8;
            }
            if (value >= 10 ** 4) {
                value /= 10 ** 4;
                result += 4;
            }
            if (value >= 10 ** 2) {
                value /= 10 ** 2;
                result += 2;
            }
            if (value >= 10 ** 1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (unsignedRoundsUp(rounding) && 10 ** result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256 of a positive value rounded towards zero.
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
     * @dev Return the log in base 256, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (unsignedRoundsUp(rounding) && 1 << (result << 3) < value ? 1 : 0);
        }
    }

    /**
     * @dev Returns whether a provided rounding mode is considered rounding up for unsigned integers.
     */
    function unsignedRoundsUp(Rounding rounding) internal pure returns (bool) {
        return uint8(rounding) % 2 == 1;
    }
}

// File: @openzeppelin/contracts/utils/Strings.sol


// OpenZeppelin Contracts (last updated v5.0.0) (utils/Strings.sol)

pragma solidity ^0.8.20;



/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant HEX_DIGITS = "0123456789abcdef";
    uint8 private constant ADDRESS_LENGTH = 20;

    /**
     * @dev The `value` string doesn't fit in the specified `length`.
     */
    error StringsInsufficientHexLength(uint256 value, uint256 length);

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
                    mstore8(ptr, byte(mod(value, 10), HEX_DIGITS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `int256` to its ASCII `string` decimal representation.
     */
    function toStringSigned(int256 value) internal pure returns (string memory) {
        return string.concat(value < 0 ? "-" : "", toString(SignedMath.abs(value)));
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
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        uint256 localValue = value;
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = HEX_DIGITS[localValue & 0xf];
            localValue >>= 4;
        }
        if (localValue != 0) {
            revert StringsInsufficientHexLength(value, length);
        }
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal
     * representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), ADDRESS_LENGTH);
    }

    /**
     * @dev Returns true if the two strings are equal.
     */
    function equal(string memory a, string memory b) internal pure returns (bool) {
        return bytes(a).length == bytes(b).length && keccak256(bytes(a)) == keccak256(bytes(b));
    }
}

// File: @rmrk-team/evm-contracts/contracts/implementations/utils/RMRKTokenURIEnumerated.sol



pragma solidity ^0.8.21;


/**
 * @title RMRKTokenURIEnumerated
 * @author RMRK team
 * @notice Implementation of enumerable token URI.
 */
contract RMRKTokenURIEnumerated {
    using Strings for uint256;

    string private _baseTokenURI;

    constructor(string memory baseTokenURI) {
        _baseTokenURI = baseTokenURI;
    }

    /**
     * @notice Used to retrieve the metadata URI of a token.
     * @param tokenId ID of the token to retrieve the metadata URI for
     * @return Metadata URI of the specified token
     */
    function tokenURI(
        uint256 tokenId
    ) public view virtual returns (string memory) {
        return string(abi.encodePacked(_baseTokenURI, tokenId.toString()));
    }
}

// File: .deps/flat.sol


/**
 *Submitted for verification at Etherscan.io on 2023-10-06
*/

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.20;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the value of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the value of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves a `value` amount of tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 value) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets a `value` amount of tokens as the allowance of `spender` over the
     * caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 value) external returns (bool);

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to` using the
     * allowance mechanism. `value` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

// File: @rmrk-team/evm-contracts/contracts/implementations/utils/RMRKTokenURIPerToken.sol



pragma solidity ^0.8.21;

/**
 * @title RMRKTokenURIPerToken
 * @author RMRK team
 * @notice Implementation of token URI per token.
 */
contract RMRKTokenURIPerToken {
    mapping(uint256 => string) private _tokenURIs;

    /**
     * @notice Used to retrieve the metadata URI of a token.
     * @param tokenId ID of the token to retrieve the metadata URI for
     * @return Metadata URI of the specified token
     */
    function tokenURI(
        uint256 tokenId
    ) public view virtual returns (string memory) {
        return _tokenURIs[tokenId];
    }

    /**
     * @notice Used to set the token URI configuration.
     * @param tokenId ID of the token to set the metadata URI for
     * @param tokenURI_ Metadata URI to apply to all tokens, either as base or as full URI for every token
     */
    function _setTokenURI(
        uint256 tokenId,
        string memory tokenURI_
    ) internal virtual {
        _tokenURIs[tokenId] = tokenURI_;
    }
}

// File: @rmrk-team/evm-contracts/contracts/RMRK/library/RMRKErrors.sol



pragma solidity ^0.8.21;

/// @title RMRKErrors
/// @author RMRK team
/// @notice A collection of errors used in the RMRK suite
/// @dev Errors are kept in a centralised file in order to provide a central point of reference and to avoid error
///  naming collisions due to inheritance

/// Attempting to grant the token to 0x0 address
error ERC721AddressZeroIsNotaValidOwner();
/// Attempting to grant approval to the current owner of the token
error ERC721ApprovalToCurrentOwner();
/// Attempting to grant approval when not being owner or approved for all should not be permitted
error ERC721ApproveCallerIsNotOwnerNorApprovedForAll();
/// Attempting to get approvals for a token owned by 0x0 (considered non-existent)
error ERC721ApprovedQueryForNonexistentToken();
/// Attempting to grant approval to self
error ERC721ApproveToCaller();
/// Attempting to use an invalid token ID
error ERC721InvalidTokenId();
/// Attempting to mint to 0x0 address
error ERC721MintToTheZeroAddress();
/// Attempting to manage a token without being its owner or approved by the owner
error ERC721NotApprovedOrOwner();
/// Attempting to mint an already minted token
error ERC721TokenAlreadyMinted();
/// Attempting to transfer the token from an address that is not the owner
error ERC721TransferFromIncorrectOwner();
/// Attempting to safe transfer to an address that is unable to receive the token
error ERC721TransferToNonReceiverImplementer();
/// Attempting to transfer the token to a 0x0 address
error ERC721TransferToTheZeroAddress();
/// Attempting to grant approval of assets to their current owner
error RMRKApprovalForAssetsToCurrentOwner();
/// Attempting to grant approval of assets without being the caller or approved for all
error RMRKApproveForAssetsCallerIsNotOwnerNorApprovedForAll();
/// Attempting to incorrectly configue a Catalog item
error RMRKBadConfig();
/// Attempting to set the priorities with an array of length that doesn't match the length of active assets array
error RMRKBadPriorityListLength();
/// Attempting to add an asset entry with `Part`s, without setting the `Catalog` address
error RMRKCatalogRequiredForParts();
/// Attempting to transfer a soulbound (non-transferrable) token
error RMRKCannotTransferSoulbound();
/// Attempting to accept a child that has already been accepted
error RMRKChildAlreadyExists();
/// Attempting to interact with a child, using index that is higher than the number of children
error RMRKChildIndexOutOfRange();
/// Attempting to find the index of a child token on a parent which does not own it.
error RMRKChildNotFoundInParent();
/// Attempting to pass collaborator address array and collaborator permission array of different lengths
error RMRKCollaboratorArraysNotEqualLength();
/// Attempting to register a collection that is already registered
error RMRKCollectionAlreadyRegistered();
/// Attempting to manage or interact with colleciton that is not registered
error RMRKCollectionNotRegistered();
/// Attempting to equip a `Part` with a child not approved by the Catalog
error RMRKEquippableEquipNotAllowedByCatalog();
/// Attempting to pass an epired ECDSA deadline
error RMRKExpiredDeadline();
/// Attempting to use ID 0, which is not supported
/// @dev The ID 0 in RMRK suite is reserved for empty values. Guarding against its use ensures the expected operation
error RMRKIdZeroForbidden();
/// Attempting to interact with an asset, using index greater than number of assets
error RMRKIndexOutOfRange();
/// Attempting to reclaim a child that can't be reclaimed
error RMRKInvalidChildReclaim();
/// Attempting to use and invalid ECDSA signature
error RMRKInvalidSignature();
/// Attempting to interact with an end-user account when the contract account is expected
error RMRKIsNotContract();
/// Attempting to interact with a contract that had its operation locked
error RMRKLocked();
/// Attempting to add a pending child after the number of pending children has reached the limit (default limit is 128)
error RMRKMaxPendingChildrenReached();
/// Attempting to add a pending asset after the number of pending assets has reached the limit (default limit is
///  128)
error RMRKMaxPendingAssetsReached();
/// Attempting to burn a total number of recursive children higher than maximum set
/// @param childContract Address of the collection smart contract in which the maximum number of recursive burns was reached
/// @param childId ID of the child token at which the maximum number of recursive burns was reached
error RMRKMaxRecursiveBurnsReached(address childContract, uint256 childId);
/// Attempting to mint a number of tokens that would cause the total supply to be greater than maximum supply
error RMRKMintOverMax();
/// Attempting to mint a nested token to a smart contract that doesn't support nesting
error RMRKMintToNonRMRKNestableImplementer();
/// Attempting to mint zero tokens
error RMRKMintZero();
/// Attempting to pass complementary arrays of different lengths
error RMRKMismachedArrayLength();
/// Attempting to transfer a child before it is unequipped
error RMRKMustUnequipFirst();
/// Attempting to nest a child over the nestable limit (current limit is 100 levels of nesting)
error RMRKNestableTooDeep();
/// Attempting to nest the token to own descendant, which would create a loop and leave the looped tokens in limbo
error RMRKNestableTransferToDescendant();
/// Attempting to nest the token to a smart contract that doesn't support nesting
error RMRKNestableTransferToNonRMRKNestableImplementer();
/// Attempting to nest the token into itself
error RMRKNestableTransferToSelf();
/// Attempting to interact with an asset that can not be found
error RMRKNoAssetMatchingId();
/// Attempting to manage an asset without owning it or having been granted permission by the owner to do so
error RMRKNotApprovedForAssetsOrOwner();
/// Attempting to interact with a token without being its owner or having been granted permission by the
///  owner to do so
/// @dev When a token is nested, only the direct owner (NFT parent) can mange it. In that case, approved addresses are
///  not allowed to manage it, in order to ensure the expected behaviour
error RMRKNotApprovedOrDirectOwner();
/// Attempting to manage a collection without being the collection's collaborator
error RMRKNotCollectionCollaborator();
/// Attemting to manage a collection without being the collection's issuer
error RMRKNotCollectionIssuer();
/// Attempting to manage a collection without being the collection's issuer or collaborator
error RMRKNotCollectionIssuerOrCollaborator();
/// Attempting to compose an asset wihtout having an associated Catalog
error RMRKNotComposableAsset();
/// Attempting to unequip an item that isn't equipped
error RMRKNotEquipped();
/// Attempting to interact with a management function without being the smart contract's owner
error RMRKNotOwner();
/// Attempting to interact with a function without being the owner or contributor of the collection
error RMRKNotOwnerOrContributor();
/// Attempting to manage a collection without being the specific address
error RMRKNotSpecificAddress();
/// Attempting to manage a token without being its owner
error RMRKNotTokenOwner();
/// Attempting to transfer the ownership to the 0x0 address
error RMRKNewOwnerIsZeroAddress();
/// Attempting to assign a 0x0 address as a contributor
error RMRKNewContributorIsZeroAddress();
/// Attemtping to use `Ownable` interface without implementing it
error RMRKOwnableNotImplemented();
/// Attempting an operation requiring the token being nested, while it is not
error RMRKParentIsNotNFT();
/// Attempting to add a `Part` with an ID that is already used
error RMRKPartAlreadyExists();
/// Attempting to use a `Part` that doesn't exist
error RMRKPartDoesNotExist();
/// Attempting to use a `Part` that is `Fixed` when `Slot` kind of `Part` should be used
error RMRKPartIsNotSlot();
/// Attempting to interact with a pending child using an index greater than the size of pending array
error RMRKPendingChildIndexOutOfRange();
/// Attempting to add an asset using an ID that has already been used
error RMRKAssetAlreadyExists();
/// Attempting to equip an item into a slot that already has an item equipped
error RMRKSlotAlreadyUsed();
/// Attempting to equip an item into a `Slot` that the target asset does not implement
error RMRKTargetAssetCannotReceiveSlot();
/// Attempting to equip a child into a `Slot` and parent that the child's collection doesn't support
error RMRKTokenCannotBeEquippedWithAssetIntoSlot();
/// Attempting to compose a NFT of a token without active assets
error RMRKTokenDoesNotHaveAsset();
/// Attempting to determine the asset with the top priority on a token without assets
error RMRKTokenHasNoAssets();
/// Attempting to accept or transfer a child which does not match the one at the specified index
error RMRKUnexpectedChildId();
/// Attempting to reject all pending assets but more assets than expected are pending
error RMRKUnexpectedNumberOfAssets();
/// Attempting to reject all pending children but children assets than expected are pending
error RMRKUnexpectedNumberOfChildren();
/// Attempting to accept or reject an asset which does not match the one at the specified index
error RMRKUnexpectedAssetId();
/// Attempting an operation expecting a parent to the token which is not the actual one
error RMRKUnexpectedParent();
/// Attempting not to pass an empty array of equippable addresses when adding or setting the equippable addresses
error RMRKZeroLengthIdsPassed();
/// Attempting to set the royalties to a value higher than 100% (10000 in basis points)
error RMRKRoyaltiesTooHigh();
/// Attempting to do a bulk operation on a token that is not owned by the caller
error RMRKCanOnlyDoBulkOperationsOnOwnedTokens();
/// Attempting to do a bulk operation with multiple tokens at a time
error RMRKCanOnlyDoBulkOperationsWithOneTokenAtATime();
/// Attempting to pay with native token with a value different than expected
error RMRKWrongValueSent();

// File: @openzeppelin/contracts/utils/Context.sol


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// File: @rmrk-team/evm-contracts/contracts/RMRK/access/Ownable.sol



pragma solidity ^0.8.21;



/**
 * @title Ownable
 * @author RMRK team
 * @notice A minimal ownable smart contractf or owner and contributors.
 * @dev This smart contract is based on "openzeppelin's access/Ownable.sol".
 */
contract Ownable is Context {
    address private _owner;
    mapping(address => uint256) private _contributors;

    /**
     * @notice Used to anounce the transfer of ownership.
     * @param previousOwner Address of the account that transferred their ownership role
     * @param newOwner Address of the account receiving the ownership role
     */
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @notice Event that signifies that an address was granted contributor role or that the permission has been
     *  revoked.
     * @dev This can only be triggered by a current owner, so there is no need to include that information in the event.
     * @param contributor Address of the account that had contributor role status updated
     * @param isContributor A boolean value signifying whether the role has been granted (`true`) or revoked (`false`)
     */
    event ContributorUpdate(address indexed contributor, bool isContributor);

    /**
     * @dev Reverts if called by any account other than the owner or an approved contributor.
     */
    modifier onlyOwnerOrContributor() {
        _onlyOwnerOrContributor();
        _;
    }

    /**
     * @dev Reverts if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _onlyOwner();
        _;
    }

    /**
     * @dev Initializes the contract by setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @notice Returns the address of the current owner.
     * @return Address of the current owner
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @notice Leaves the contract without owner. Functions using the `onlyOwner` modifier will be disabled.
     * @dev Can only be called by the current owner.
     * @dev Renouncing ownership will leave the contract without an owner, thereby removing any functionality that is
     *  only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @notice Transfers ownership of the contract to a new owner.
     * @dev Can only be called by the current owner.
     * @param newOwner Address of the new owner's account
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        if (newOwner == address(0)) revert RMRKNewOwnerIsZeroAddress();
        _transferOwnership(newOwner);
    }

    /**
     * @notice Transfers ownership of the contract to a new owner.
     * @dev Internal function without access restriction.
     * @dev Emits ***OwnershipTransferred*** event.
     * @param newOwner Address of the new owner's account
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    /**
     * @notice Adds or removes a contributor to the smart contract.
     * @dev Can only be called by the owner.
     * @dev Emits ***ContributorUpdate*** event.
     * @param contributor Address of the contributor's account
     * @param grantRole A boolean value signifying whether the contributor role is being granted (`true`) or revoked
     *  (`false`)
     */
    function manageContributor(
        address contributor,
        bool grantRole
    ) external onlyOwner {
        if (contributor == address(0)) revert RMRKNewContributorIsZeroAddress();
        grantRole
            ? _contributors[contributor] = 1
            : _contributors[contributor] = 0;
        emit ContributorUpdate(contributor, grantRole);
    }

    /**
     * @notice Used to check if the address is one of the contributors.
     * @param contributor Address of the contributor whose status we are checking
     * @return Boolean value indicating whether the address is a contributor or not
     */
    function isContributor(address contributor) public view returns (bool) {
        return _contributors[contributor] == 1;
    }

    /**
     * @notice Used to verify that the caller is either the owner or a contributor.
     * @dev If the caller is not the owner or a contributor, the execution will be reverted.
     */
    function _onlyOwnerOrContributor() private view {
        if (owner() != _msgSender() && !isContributor(_msgSender()))
            revert RMRKNotOwnerOrContributor();
    }

    /**
     * @notice Used to verify that the caller is the owner.
     * @dev If the caller is not the owner, the execution will be reverted.
     */
    function _onlyOwner() private view {
        if (owner() != _msgSender()) revert RMRKNotOwner();
    }
}

// File: @openzeppelin/contracts/utils/Address.sol


// OpenZeppelin Contracts (last updated v4.9.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     *
     * Furthermore, `isContract` will also return true if the target contract within
     * the same transaction is already scheduled for destruction by `SELFDESTRUCT`,
     * which only has an effect at the end of a transaction.
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.8.0/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

// File: @openzeppelin/contracts/token/ERC721/IERC721Receiver.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// File: @rmrk-team/evm-contracts/contracts/RMRK/core/RMRKCore.sol



pragma solidity ^0.8.21;

/**
 * @title RMRKCore
 * @author RMRK team
 * @notice Smart contract of the RMRK core module.
 * @dev This is currently just a passthrough contract which allows for granular editing of base-level ERC721 functions.
 */
contract RMRKCore {
    /**
     * @notice Version of the @rmrk-team/evm-contracts package
     * @return Version identifier of the smart contract
     */
    string public constant VERSION = "2.1.1";
    bytes4 public constant RMRK_INTERFACE = 0x524D524B; // "RMRK" in ASCII hex
}

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol


// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// File: @openzeppelin/contracts/interfaces/IERC2981.sol


// OpenZeppelin Contracts (last updated v4.9.0) (interfaces/IERC2981.sol)

pragma solidity ^0.8.0;


/**
 * @dev Interface for the NFT Royalty Standard.
 *
 * A standardized way to retrieve royalty payment information for non-fungible tokens (NFTs) to enable universal
 * support for royalty payments across all NFT marketplaces and ecosystem participants.
 *
 * _Available since v4.5._
 */
interface IERC2981 is IERC165 {
    /**
     * @dev Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of
     * exchange. The royalty amount is denominated and should be paid in that same unit of exchange.
     */
    function royaltyInfo(
        uint256 tokenId,
        uint256 salePrice
    ) external view returns (address receiver, uint256 royaltyAmount);
}

// File: @rmrk-team/evm-contracts/contracts/RMRK/extension/RMRKRoyalties.sol



pragma solidity ^0.8.21;



/**
 * @title RMRKRoyalties
 * @author RMRK team
 * @notice Smart contract of the RMRK Royalties module.
 */
abstract contract RMRKRoyalties {
    /** is IERC2981 **/ // Inheritance is commmnted to prevent linearization issues
    address private _royaltyRecipient;
    uint256 private _royaltyPercentageBps;

    /**
     * @notice Used to initiate the smart contract.
     * @dev `royaltyPercentageBps` is expressed in basis points, so 1 basis point equals 0.01% and 500 basis points
     *  equal 5%.
     * @param royaltyRecipient Address to which royalties should be sent
     * @param royaltyPercentageBps The royalty percentage expressed in basis points
     */
    constructor(address royaltyRecipient, uint256 royaltyPercentageBps) {
        _setRoyaltyRecipient(royaltyRecipient);
        if (royaltyPercentageBps >= 10000) revert RMRKRoyaltiesTooHigh();
        _royaltyPercentageBps = royaltyPercentageBps;
    }

    /**
     * @notice Used to update recipient of royalties.
     * @dev Custom access control has to be implemented to ensure that only the intended actors can update the
     *  beneficiary.
     * @param newRoyaltyRecipient Address of the new recipient of royalties
     */
    function updateRoyaltyRecipient(
        address newRoyaltyRecipient
    ) external virtual;

    /**
     * @notice Used to update the royalty recipient.
     * @param newRoyaltyRecipient Address of the new recipient of royalties
     */
    function _setRoyaltyRecipient(address newRoyaltyRecipient) internal {
        _royaltyRecipient = newRoyaltyRecipient;
    }

    /**
     * @notice Used to retrieve the recipient of royalties.
     * @return Address of the recipient of royalties
     */
    function getRoyaltyRecipient() public view virtual returns (address) {
        return _royaltyRecipient;
    }

    /**
     * @notice Used to retrieve the specified royalty percentage.
     * @return The royalty percentage expressed in the basis points
     */
    function getRoyaltyPercentage() public view virtual returns (uint256) {
        return _royaltyPercentageBps;
    }

    /**
     * @notice Used to retrieve the information about who shall receive royalties of a sale of the specified token and
     *  how much they will be.
     * @param tokenId ID of the token for which the royalty info is being retrieved
     * @param salePrice Price of the token sale
     * @return receiver The beneficiary receiving royalties of the sale
     * @return royaltyAmount The value of the royalties recieved by the `receiver` from the sale
     */
    function royaltyInfo(
        uint256 tokenId,
        uint256 salePrice
    ) external view virtual returns (address receiver, uint256 royaltyAmount) {
        receiver = _royaltyRecipient;
        royaltyAmount = (salePrice * _royaltyPercentageBps) / 10000;
    }
}

// File: @rmrk-team/evm-contracts/contracts/implementations/utils/RMRKImplementationBase.sol


pragma solidity ^0.8.21;




/**
 * @title RMRKImplementationBase
 * @author RMRK team
 * @notice Smart contract of the RMRK minting utils module.
 * @dev This smart contract includes the top-level utilities for managing minting and implements Ownable by default.
 */
abstract contract RMRKImplementationBase is RMRKRoyalties, Ownable {
    string private _collectionMetadata;
    string private _name;
    string private _symbol;

    uint256 private _nextId;
    uint256 internal _totalSupply;
    uint256 internal _maxSupply;
    uint256 internal _totalAssets;

    /**
     * @notice Initializes the smart contract with a given maximum supply and minting price.
     * @param name_ Name of the token collection
     * @param symbol_ Symbol of the token collection
     * @param collectionMetadata_ The collection metadata URI
     * @param maxSupply_ The maximum supply of tokens
     * @param royaltyRecipient Address to which royalties should be sent
     * @param royaltyPercentageBps The royalty percentage expressed in basis points
     */
    constructor(
        string memory name_,
        string memory symbol_,
        string memory collectionMetadata_,
        uint256 maxSupply_,
        address royaltyRecipient,
        uint256 royaltyPercentageBps
    ) RMRKRoyalties(royaltyRecipient, royaltyPercentageBps) {
        _name = name_;
        _symbol = symbol_;
        _collectionMetadata = collectionMetadata_;
        _maxSupply = maxSupply_;
    }

    /**
     * @notice Used to retrieve the total supply of the tokens in a collection.
     * @return The number of tokens in a collection
     */
    function totalSupply() public view virtual returns (uint256) {
        return _totalSupply;
    }

    /**
     * @notice Used to retrieve the maximum supply of the collection.
     * @return The maximum supply of tokens in the collection
     */
    function maxSupply() public view virtual returns (uint256) {
        return _maxSupply;
    }

    /**
     * @notice Used to retrieve the total number of assets.
     * @return The total number of assets
     */
    function totalAssets() public view virtual returns (uint256) {
        return _totalAssets;
    }

    /**
     * @notice Used to retrieve the metadata of the collection.
     * @return string The metadata URI of the collection
     */
    function collectionMetadata() public view virtual returns (string memory) {
        return _collectionMetadata;
    }

    /**
     * @notice Used to retrieve the collection name.
     * @return Name of the collection
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @notice Used to retrieve the collection symbol.
     * @return Symbol of the collection
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @inheritdoc RMRKRoyalties
     */
    function updateRoyaltyRecipient(
        address newRoyaltyRecipient
    ) public virtual override onlyOwner {
        _setRoyaltyRecipient(newRoyaltyRecipient);
    }

    /**
     * @notice Used to calculate the token IDs of tokens to be minted.
     * @param numToMint Amount of tokens to be minted
     * @return nextToken The ID of the first token to be minted in the current minting cycle
     * @return totalSupplyOffset The ID of the last token to be minted in the current minting cycle
     */
    function _prepareMint(
        uint256 numToMint
    ) internal virtual returns (uint256 nextToken, uint256 totalSupplyOffset) {
        if (numToMint == uint256(0)) revert RMRKMintZero();
        if (numToMint + _nextId > _maxSupply) revert RMRKMintOverMax();

        unchecked {
            nextToken = _nextId + 1;
            _nextId += numToMint;
            _totalSupply += numToMint;
            totalSupplyOffset = _nextId + 1;
        }
    }
}

// File: @rmrk-team/evm-contracts/contracts/RMRK/nestable/IERC7401.sol



pragma solidity ^0.8.21;


/**
 * @title IERC7401
 * @author RMRK team
 * @notice Interface smart contract of the RMRK nestable module.
 */
interface IERC7401 is IERC165 {
    /**
     * @notice The core struct of RMRK ownership.
     * @dev The `DirectOwner` struct is used to store information of the next immediate owner, be it the parent token or
     *  the externally owned account.
     * @dev If the token is owned by the externally owned account, the `tokenId` should equal `0`.
     * @param tokenId ID of the parent token
     * @param ownerAddress Address of the owner of the token. If the owner is another token, then the address should be
     *  the one of the parent token's collection smart contract. If the owner is externally owned account, the address
     *  should be the address of this account
     * @param isNft A boolean value signifying whether the token is owned by another token (`true`) or by an externally
     *  owned account (`false`)
     */
    struct DirectOwner {
        uint256 tokenId;
        address ownerAddress;
    }

    /**
     * @notice Used to notify listeners that the token is being transferred.
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     * @param from Address of the previous immediate owner, which is a smart contract if the token was nested.
     * @param to Address of the new immediate owner, which is a smart contract if the token is being nested.
     * @param fromTokenId ID of the previous parent token. If the token was not nested before, the value should be `0`
     * @param toTokenId ID of the new parent token. If the token is not being nested, the value should be `0`
     * @param tokenId ID of the token being transferred
     */
    event NestTransfer(
        address indexed from,
        address indexed to,
        uint256 fromTokenId,
        uint256 toTokenId,
        uint256 indexed tokenId
    );

    /**
     * @notice Used to notify listeners that a new token has been added to a given token's pending children array.
     * @dev Emitted when a child NFT is added to a token's pending array.
     * @param tokenId ID of the token that received a new pending child token
     * @param childIndex Index of the proposed child token in the parent token's pending children array
     * @param childAddress Address of the proposed child token's collection smart contract
     * @param childId ID of the child token in the child token's collection smart contract
     */
    event ChildProposed(
        uint256 indexed tokenId,
        uint256 childIndex,
        address indexed childAddress,
        uint256 indexed childId
    );

    /**
     * @notice Used to notify listeners that a new child token was accepted by the parent token.
     * @dev Emitted when a parent token accepts a token from its pending array, migrating it to the active array.
     * @param tokenId ID of the token that accepted a new child token
     * @param childIndex Index of the newly accepted child token in the parent token's active children array
     * @param childAddress Address of the child token's collection smart contract
     * @param childId ID of the child token in the child token's collection smart contract
     */
    event ChildAccepted(
        uint256 indexed tokenId,
        uint256 childIndex,
        address indexed childAddress,
        uint256 indexed childId
    );

    /**
     * @notice Used to notify listeners that all pending child tokens of a given token have been rejected.
     * @dev Emitted when a token removes all a child tokens from its pending array.
     * @param tokenId ID of the token that rejected all of the pending children
     */
    event AllChildrenRejected(uint256 indexed tokenId);

    /**
     * @notice Used to notify listeners a child token has been transferred from parent token.
     * @dev Emitted when a token transfers a child from itself, transferring ownership to the root owner.
     * @param tokenId ID of the token that transferred a child token
     * @param childIndex Index of a child in the array from which it is being transferred
     * @param childAddress Address of the child token's collection smart contract
     * @param childId ID of the child token in the child token's collection smart contract
     * @param fromPending A boolean value signifying whether the token was in the pending child tokens array (`true`) or
     *  in the active child tokens array (`false`)
     * @param toZero A boolean value signifying whether the token is being transferred to the `0x0` address (`true`) or
     *  not (`false`)
     */
    event ChildTransferred(
        uint256 indexed tokenId,
        uint256 childIndex,
        address indexed childAddress,
        uint256 indexed childId,
        bool fromPending,
        bool toZero
    );

    /**
     * @notice The core child token struct, holding the information about the child tokens.
     * @return tokenId ID of the child token in the child token's collection smart contract
     * @return contractAddress Address of the child token's smart contract
     */
    struct Child {
        uint256 tokenId;
        address contractAddress;
    }

    /**
     * @notice Used to retrieve the *root* owner of a given token.
     * @dev The *root* owner of the token is an externally owned account (EOA). If the given token is child of another
     *  NFT, this will return an EOA address. Otherwise, if the token is owned by an EOA, this EOA wil be returned.
     * @param tokenId ID of the token for which the *root* owner has been retrieved
     * @return owner The *root* owner of the token
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @notice Used to retrieve the immediate owner of the given token.
     * @dev If the immediate owner is another token, the address returned, should be the one of the parent token's
     *  collection smart contract.
     * @param tokenId ID of the token for which the RMRK owner is being retrieved
     * @return Address of the given token's owner
     * @return The ID of the parent token. Should be `0` if the owner is an externally owned account
     * @return The boolean value signifying whether the owner is an NFT or not
     */
    function directOwnerOf(
        uint256 tokenId
    ) external view returns (address, uint256, bool);

    /**
     * @notice Used to burn a given token.
     * @dev When a token is burned, all of its child tokens are recursively burned as well.
     * @dev When specifying the maximum recursive burns, the execution will be reverted if there are more children to be
     *  burned.
     * @dev Setting the `maxRecursiveBurn` value to 0 will only attempt to burn the specified token and revert if there
     *  are any child tokens present.
     * @dev The approvals are cleared when the token is burned.
     * @dev Requirements:
     *
     *  - `tokenId` must exist.
     * @dev Emits a {Transfer} event.
     * @param tokenId ID of the token to burn
     * @param maxRecursiveBurns Maximum number of tokens to recursively burn
     * @return Number of recursively burned children
     */
    function burn(
        uint256 tokenId,
        uint256 maxRecursiveBurns
    ) external returns (uint256);

    /**
     * @notice Used to add a child token to a given parent token.
     * @dev This adds the child token into the given parent token's pending child tokens array.
     * @dev Requirements:
     *
     *  - `directOwnerOf` on the child contract must resolve to the called contract.
     *  - the pending array of the parent contract must not be full.
     * @param parentId ID of the parent token to receive the new child token
     * @param childId ID of the new proposed child token
     * @param data Additional data with no specified format
     */
    function addChild(
        uint256 parentId,
        uint256 childId,
        bytes memory data
    ) external;

    /**
     * @notice Used to accept a pending child token for a given parent token.
     * @dev This moves the child token from parent token's pending child tokens array into the active child tokens
     *  array.
     * @param parentId ID of the parent token for which the child token is being accepted
     * @param childIndex Index of a child tokem in the given parent's pending children array
     * @param childAddress Address of the collection smart contract of the child token expected to be located at the
     *  specified index of the given parent token's pending children array
     * @param childId ID of the child token expected to be located at the specified index of the given parent token's
     *  pending children array
     */
    function acceptChild(
        uint256 parentId,
        uint256 childIndex,
        address childAddress,
        uint256 childId
    ) external;

    /**
     * @notice Used to reject all pending children of a given parent token.
     * @dev Removes the children from the pending array mapping.
     * @dev This does not update the ownership storage data on children. If necessary, ownership can be reclaimed by the
     *  rootOwner of the previous parent.
     * @dev Requirements:
     *
     * Requirements:
     *
     * - `parentId` must exist
     * @param parentId ID of the parent token for which to reject all of the pending tokens.
     * @param maxRejections Maximum number of expected children to reject, used to prevent from rejecting children which
     *  arrive just before this operation.
     */
    function rejectAllChildren(
        uint256 parentId,
        uint256 maxRejections
    ) external;

    /**
     * @notice Used to transfer a child token from a given parent token.
     * @dev When transferring a child token, the owner of the token is set to `to`, or is not updated in the event of
     *  `to` being the `0x0` address.
     * @param tokenId ID of the parent token from which the child token is being transferred
     * @param to Address to which to transfer the token to
     * @param destinationId ID of the token to receive this child token (MUST be 0 if the destination is not a token)
     * @param childIndex Index of a token we are transferring, in the array it belongs to (can be either active array or
     *  pending array)
     * @param childAddress Address of the child token's collection smart contract.
     * @param childId ID of the child token in its own collection smart contract.
     * @param isPending A boolean value indicating whether the child token being transferred is in the pending array of
     *  the parent token (`true`) or in the active array (`false`)
     * @param data Additional data with no specified format, sent in call to `_to`
     */
    function transferChild(
        uint256 tokenId,
        address to,
        uint256 destinationId,
        uint256 childIndex,
        address childAddress,
        uint256 childId,
        bool isPending,
        bytes memory data
    ) external;

    /**
     * @notice Used to retrieve the active child tokens of a given parent token.
     * @dev Returns array of Child structs existing for parent token.
     * @dev The Child struct consists of the following values:
     *  [
     *      tokenId,
     *      contractAddress
     *  ]
     * @param parentId ID of the parent token for which to retrieve the active child tokens
     * @return An array of Child structs containing the parent token's active child tokens
     */
    function childrenOf(
        uint256 parentId
    ) external view returns (Child[] memory);

    /**
     * @notice Used to retrieve the pending child tokens of a given parent token.
     * @dev Returns array of pending Child structs existing for given parent.
     * @dev The Child struct consists of the following values:
     *  [
     *      tokenId,
     *      contractAddress
     *  ]
     * @param parentId ID of the parent token for which to retrieve the pending child tokens
     * @return An array of Child structs containing the parent token's pending child tokens
     */
    function pendingChildrenOf(
        uint256 parentId
    ) external view returns (Child[] memory);

    /**
     * @notice Used to retrieve a specific active child token for a given parent token.
     * @dev Returns a single Child struct locating at `index` of parent token's active child tokens array.
     * @dev The Child struct consists of the following values:
     *  [
     *      tokenId,
     *      contractAddress
     *  ]
     * @param parentId ID of the parent token for which the child is being retrieved
     * @param index Index of the child token in the parent token's active child tokens array
     * @return A Child struct containing data about the specified child
     */
    function childOf(
        uint256 parentId,
        uint256 index
    ) external view returns (Child memory);

    /**
     * @notice Used to retrieve a specific pending child token from a given parent token.
     * @dev Returns a single Child struct locating at `index` of parent token's active child tokens array.
     * @dev The Child struct consists of the following values:
     *  [
     *      tokenId,
     *      contractAddress
     *  ]
     * @param parentId ID of the parent token for which the pending child token is being retrieved
     * @param index Index of the child token in the parent token's pending child tokens array
     * @return A Child struct containting data about the specified child
     */
    function pendingChildOf(
        uint256 parentId,
        uint256 index
    ) external view returns (Child memory);

    /**
     * @notice Used to transfer the token into another token.
     * @param from Address of the direct owner of the token to be transferred
     * @param to Address of the receiving token's collection smart contract
     * @param tokenId ID of the token being transferred
     * @param destinationId ID of the token to receive the token being transferred
     * @param data Additional data with no specified format, sent in the addChild call
     */
    function nestTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        uint256 destinationId,
        bytes memory data
    ) external;
}

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol


// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;


/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// File: @rmrk-team/evm-contracts/contracts/RMRK/nestable/RMRKNestable.sol



//Generally all interactions should propagate downstream

pragma solidity ^0.8.21;









/**
 * @title RMRKNestable
 * @author RMRK team
 * @notice Smart contract of the RMRK Nestable module.
 * @dev This contract is hierarchy agnostic and can support an arbitrary number of nested levels up and down, as long as
 *  gas limits allow it.
 */
contract RMRKNestable is Context, IERC165, IERC721, IERC7401, RMRKCore {
    using Address for address;

    uint256 private constant _MAX_LEVELS_TO_CHECK_FOR_INHERITANCE_LOOP = 100;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approver address to approved address
    // The approver is necessary so approvals are invalidated for nested children on transfer
    // WARNING: If a child NFT returns to a previous root owner, old permissions would be active again
    mapping(uint256 => mapping(address => address)) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // ------------------- NESTABLE --------------

    // Mapping from token ID to DirectOwner struct
    mapping(uint256 => DirectOwner) private _RMRKOwners;

    // Mapping of tokenId to array of active children structs
    mapping(uint256 => Child[]) internal _activeChildren;

    // Mapping of tokenId to array of pending children structs
    mapping(uint256 => Child[]) internal _pendingChildren;

    // Mapping of child token address to child token ID to whether they are pending or active on any token
    // We might have a first extra mapping from token ID, but since the same child cannot be nested into multiple tokens
    //  we can strip it for size/gas savings.
    mapping(address => mapping(uint256 => uint256)) internal _childIsInActive;

    // -------------------------- MODIFIERS ----------------------------

    /**
     * @notice Used to verify that the caller is either the owner of the token or approved to manage it by its owner.
     * @dev If the caller is not the owner of the token or approved to manage it by its owner, the execution will be
     *  reverted.
     * @param tokenId ID of the token to check
     */
    function _onlyApprovedOrOwner(uint256 tokenId) private view {
        if (!_isApprovedOrOwner(_msgSender(), tokenId))
            revert ERC721NotApprovedOrOwner();
    }

    /**
     * @notice Used to verify that the caller is either the owner of the token or approved to manage it by its owner.
     * @param tokenId ID of the token to check
     */
    modifier onlyApprovedOrOwner(uint256 tokenId) {
        _onlyApprovedOrOwner(tokenId);
        _;
    }

    /**
     * @notice Used to verify that the caller is approved to manage the given token or it its direct owner.
     * @dev This does not delegate to ownerOf, which returns the root owner, but rater uses an owner from DirectOwner
     *  struct.
     * @dev The execution is reverted if the caller is not immediate owner or approved to manage the given token.
     * @dev Used for parent-scoped transfers.
     * @param tokenId ID of the token to check.
     */
    function _onlyApprovedOrDirectOwner(uint256 tokenId) private view {
        if (!_isApprovedOrDirectOwner(_msgSender(), tokenId))
            revert RMRKNotApprovedOrDirectOwner();
    }

    /**
     * @notice Used to verify that the caller is approved to manage the given token or is its direct owner.
     * @param tokenId ID of the token to check
     */
    modifier onlyApprovedOrDirectOwner(uint256 tokenId) {
        _onlyApprovedOrDirectOwner(tokenId);
        _;
    }

    // ------------------------------- ERC721 ---------------------------------
    /**
     * @inheritdoc IERC165
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual returns (bool) {
        return
            interfaceId == type(IERC165).interfaceId ||
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC7401).interfaceId;
    }

    /**
     * @notice Used to retrieve the number of tokens in `owner`'s account.
     * @param owner Address of the account being checked
     * @return The balance of the given account
     */
    function balanceOf(address owner) public view virtual returns (uint256) {
        if (owner == address(0)) revert ERC721AddressZeroIsNotaValidOwner();
        return _balances[owner];
    }

    ////////////////////////////////////////
    //              TRANSFERS
    ////////////////////////////////////////

    /**
     * @notice Transfers a given token from `from` to `to`.
     * @dev Requirements:
     *
     *  - `from` cannot be the zero address.
     *  - `to` cannot be the zero address.
     *  - `tokenId` token must be owned by `from`.
     *  - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * @dev Emits a {Transfer} event.
     * @param from Address from which to transfer the token from
     * @param to Address to which to transfer the token to
     * @param tokenId ID of the token to transfer
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual onlyApprovedOrDirectOwner(tokenId) {
        _transfer(from, to, tokenId, "");
    }

    /**
     * @notice Used to safely transfer a given token token from `from` to `to`.
     * @dev Requirements:
     *
     *  - `from` cannot be the zero address.
     *  - `to` cannot be the zero address.
     *  - `tokenId` token must exist and be owned by `from`.
     *  - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *  - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     * @dev Emits a {Transfer} event.
     * @param from Address to transfer the tokens from
     * @param to Address to transfer the tokens to
     * @param tokenId ID of the token to transfer
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @notice Used to safely transfer a given token token from `from` to `to`.
     * @dev Requirements:
     *
     *  - `from` cannot be the zero address.
     *  - `to` cannot be the zero address.
     *  - `tokenId` token must exist and be owned by `from`.
     *  - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *  - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     * @dev Emits a {Transfer} event.
     * @param from Address to transfer the tokens from
     * @param to Address to transfer the tokens to
     * @param tokenId ID of the token to transfer
     * @param data Additional data without a specified format to be sent along with the token transaction
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual onlyApprovedOrDirectOwner(tokenId) {
        _safeTransfer(from, to, tokenId, data);
    }

    /**
     * @inheritdoc IERC7401
     */
    function nestTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        uint256 destinationId,
        bytes memory data
    ) public virtual onlyApprovedOrDirectOwner(tokenId) {
        _nestTransfer(from, to, tokenId, destinationId, data);
    }

    /**
     * @notice Used to safely transfer the token form `from` to `to`.
     * @dev The function checks that contract recipients are aware of the ERC721 protocol to prevent tokens from being
     *  forever locked.
     * @dev This internal function is equivalent to {safeTransferFrom}, and can be used to e.g. implement alternative
     *  mechanisms to perform token transfer, such as signature-based.
     * @dev Requirements:
     *
     *  - `from` cannot be the zero address.
     *  - `to` cannot be the zero address.
     *  - `tokenId` token must exist and be owned by `from`.
     *  - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     * @dev Emits a {Transfer} event.
     * @param from Address of the account currently owning the given token
     * @param to Address to transfer the token to
     * @param tokenId ID of the token to transfer
     * @param data Additional data with no specified format, sent in call to `to`
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _transfer(from, to, tokenId, data);
        if (!_checkOnERC721Received(from, to, tokenId, data))
            revert ERC721TransferToNonReceiverImplementer();
    }

    /**
     * @notice Used to transfer the token from `from` to `to`.
     * @dev As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     * @dev Requirements:
     *
     *  - `to` cannot be the zero address.
     *  - `tokenId` token must be owned by `from`.
     * @dev Emits a {Transfer} event.
     * @param from Address of the account currently owning the given token
     * @param to Address to transfer the token to
     * @param tokenId ID of the token to transfer
     * @param data Additional data with no specified format, sent in call to `to`
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        (address immediateOwner, uint256 parentId, ) = directOwnerOf(tokenId);
        if (immediateOwner != from) revert ERC721TransferFromIncorrectOwner();
        if (to == address(0)) revert ERC721TransferToTheZeroAddress();

        _beforeTokenTransfer(from, to, tokenId);
        _beforeNestedTokenTransfer(from, to, parentId, 0, tokenId, data);

        _balances[from] -= 1;
        _updateOwnerAndClearApprovals(tokenId, 0, to);
        _balances[to] += 1;

        emit Transfer(from, to, tokenId);
        emit NestTransfer(from, to, parentId, 0, tokenId);

        _afterTokenTransfer(from, to, tokenId);
        _afterNestedTokenTransfer(from, to, parentId, 0, tokenId, data);
    }

    /**
     * @notice Used to transfer a token into another token.
     * @dev Attempting to nest a token into `0x0` address will result in reverted transaction.
     * @dev Attempting to nest a token into itself will result in reverted transaction.
     * @param from Address of the account currently owning the given token
     * @param to Address of the receiving token's collection smart contract
     * @param tokenId ID of the token to transfer
     * @param destinationId ID of the token receiving the given token
     * @param data Additional data with no specified format, sent in the addChild call
     */
    function _nestTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 destinationId,
        bytes memory data
    ) internal virtual {
        (address immediateOwner, uint256 parentId, ) = directOwnerOf(tokenId);
        if (immediateOwner != from) revert ERC721TransferFromIncorrectOwner();
        if (to == address(0)) revert ERC721TransferToTheZeroAddress();
        if (to == address(this) && tokenId == destinationId)
            revert RMRKNestableTransferToSelf();

        // Destination contract checks:
        // It seems redundant, but otherwise it would revert with no error
        if (!to.isContract()) revert RMRKIsNotContract();
        if (!IERC165(to).supportsInterface(type(IERC7401).interfaceId))
            revert RMRKNestableTransferToNonRMRKNestableImplementer();
        _checkForInheritanceLoop(tokenId, to, destinationId);

        _beforeTokenTransfer(from, to, tokenId);
        _beforeNestedTokenTransfer(
            immediateOwner,
            to,
            parentId,
            destinationId,
            tokenId,
            data
        );
        _balances[from] -= 1;
        _updateOwnerAndClearApprovals(tokenId, destinationId, to);
        _balances[to] += 1;

        // Sending to NFT:
        _sendToNFT(immediateOwner, to, parentId, destinationId, tokenId, data);
    }

    /**
     * @notice Used to send a token to another token.
     * @dev If the token being sent is currently owned by an externally owned account, the `parentId` should equal `0`.
     * @dev Emits {Transfer} event.
     * @dev Emits {NestTransfer} event.
     * @param from Address from which the token is being sent
     * @param to Address of the collection smart contract of the token to receive the given token
     * @param parentId ID of the current parent token of the token being sent
     * @param destinationId ID of the tokento receive the token being sent
     * @param tokenId ID of the token being sent
     * @param data Additional data with no specified format, sent in the addChild call
     */
    function _sendToNFT(
        address from,
        address to,
        uint256 parentId,
        uint256 destinationId,
        uint256 tokenId,
        bytes memory data
    ) private {
        IERC7401 destContract = IERC7401(to);
        destContract.addChild(destinationId, tokenId, data);

        emit Transfer(from, to, tokenId);
        emit NestTransfer(from, to, parentId, destinationId, tokenId);

        _afterTokenTransfer(from, to, tokenId);
        _afterNestedTokenTransfer(
            from,
            to,
            parentId,
            destinationId,
            tokenId,
            data
        );
    }

    /**
     * @notice Used to check if nesting a given token into a specified token would create an inheritance loop.
     * @dev If a loop would occur, the tokens would be unmanageable, so the execution is reverted if one is detected.
     * @dev The check for inheritance loop is bounded to guard against too much gas being consumed.
     * @param currentId ID of the token that would be nested
     * @param targetContract Address of the collection smart contract of the token into which the given token would be
     *  nested
     * @param targetId ID of the token into which the given token would be nested
     */
    function _checkForInheritanceLoop(
        uint256 currentId,
        address targetContract,
        uint256 targetId
    ) private view {
        for (uint256 i; i < _MAX_LEVELS_TO_CHECK_FOR_INHERITANCE_LOOP; ) {
            (
                address nextOwner,
                uint256 nextOwnerTokenId,
                bool isNft
            ) = IERC7401(targetContract).directOwnerOf(targetId);
            // If there's a final address, we're good. There's no loop.
            if (!isNft) {
                return;
            }
            // Ff the current nft is an ancestor at some point, there is an inheritance loop
            if (nextOwner == address(this) && nextOwnerTokenId == currentId) {
                revert RMRKNestableTransferToDescendant();
            }
            // We reuse the parameters to save some contract size
            targetContract = nextOwner;
            targetId = nextOwnerTokenId;
            unchecked {
                ++i;
            }
        }
        revert RMRKNestableTooDeep();
    }

    ////////////////////////////////////////
    //              MINTING
    ////////////////////////////////////////

    /**
     * @notice Used to safely mint the token to the specified address while passing the additional data to contract
     *  recipients.
     * @param to Address to which to mint the token
     * @param tokenId ID of the token to mint
     * @param data Additional data to send with the tokens
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _mint(to, tokenId, data);
        if (!_checkOnERC721Received(address(0), to, tokenId, data))
            revert ERC721TransferToNonReceiverImplementer();
    }

    /**
     * @notice Used to mint a specified token to a given address.
     * @dev WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible.
     * @dev Requirements:
     *
     *  - `tokenId` must not exist.
     *  - `to` cannot be the zero address.
     * @dev Emits a {Transfer} event.
     * @dev Emits a {NestTransfer} event.
     * @param to Address to mint the token to
     * @param tokenId ID of the token to mint
     * @param data Additional data with no specified format, sent in call to `to`
     */
    function _mint(
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _innerMint(to, tokenId, 0, data);

        emit Transfer(address(0), to, tokenId);
        emit NestTransfer(address(0), to, 0, 0, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
        _afterNestedTokenTransfer(address(0), to, 0, 0, tokenId, data);
    }

    /**
     * @notice Used to mint a child token to a given parent token.
     * @param to Address of the collection smart contract of the token into which to mint the child token
     * @param tokenId ID of the token to mint
     * @param destinationId ID of the token into which to mint the new child token
     * @param data Additional data with no specified format, sent in the addChild call
     */
    function _nestMint(
        address to,
        uint256 tokenId,
        uint256 destinationId,
        bytes memory data
    ) internal virtual {
        // It seems redundant, but otherwise it would revert with no error
        if (!to.isContract()) revert RMRKIsNotContract();
        if (!IERC165(to).supportsInterface(type(IERC7401).interfaceId))
            revert RMRKMintToNonRMRKNestableImplementer();

        _innerMint(to, tokenId, destinationId, data);
        _sendToNFT(address(0), to, 0, destinationId, tokenId, data);
    }

    /**
     * @notice Used to mint a child token into a given parent token.
     * @dev Requirements:
     *
     *  - `to` cannot be the zero address.
     *  - `tokenId` must not exist.
     *  - `tokenId` must not be `0`.
     * @param to Address of the collection smart contract of the token into which to mint the child token
     * @param tokenId ID of the token to mint
     * @param destinationId ID of the token into which to mint the new token
     * @param data Additional data with no specified format, sent in call to `to`
     */
    function _innerMint(
        address to,
        uint256 tokenId,
        uint256 destinationId,
        bytes memory data
    ) private {
        if (to == address(0)) revert ERC721MintToTheZeroAddress();
        if (_exists(tokenId)) revert ERC721TokenAlreadyMinted();
        if (tokenId == uint256(0)) revert RMRKIdZeroForbidden();

        _beforeTokenTransfer(address(0), to, tokenId);
        _beforeNestedTokenTransfer(
            address(0),
            to,
            0,
            destinationId,
            tokenId,
            data
        );

        _balances[to] += 1;
        _RMRKOwners[tokenId] = DirectOwner({
            ownerAddress: to,
            tokenId: destinationId
        });
    }

    ////////////////////////////////////////
    //              Ownership
    ////////////////////////////////////////

    /**
     * @inheritdoc IERC7401
     */
    function ownerOf(
        uint256 tokenId
    ) public view virtual override(IERC7401, IERC721) returns (address) {
        (address owner, uint256 ownerTokenId, bool isNft) = directOwnerOf(
            tokenId
        );
        if (isNft) {
            owner = IERC7401(owner).ownerOf(ownerTokenId);
        }
        return owner;
    }

    /**
     * @inheritdoc IERC7401
     */
    function directOwnerOf(
        uint256 tokenId
    ) public view virtual returns (address, uint256, bool) {
        DirectOwner memory owner = _RMRKOwners[tokenId];
        if (owner.ownerAddress == address(0)) revert ERC721InvalidTokenId();

        return (owner.ownerAddress, owner.tokenId, owner.tokenId != 0);
    }

    ////////////////////////////////////////
    //              BURNING
    ////////////////////////////////////////

    /**
     * @notice Used to burn a given token.
     * @dev In case the token has any child tokens, the execution will be reverted.
     * @param tokenId ID of the token to burn
     */
    function burn(uint256 tokenId) public virtual {
        burn(tokenId, 0);
    }

    /**
     * @inheritdoc IERC7401
     */
    function burn(
        uint256 tokenId,
        uint256 maxChildrenBurns
    ) public virtual onlyApprovedOrDirectOwner(tokenId) returns (uint256) {
        return _burn(tokenId, maxChildrenBurns);
    }

    /**
     * @notice Used to burn a token.
     * @dev When a token is burned, its children are recursively burned as well.
     * @dev The approvals are cleared when the token is burned.
     * @dev Requirements:
     *
     *  - `tokenId` must exist.
     * @dev Emits a {Transfer} event.
     * @dev Emits a {NestTransfer} event.
     * @param tokenId ID of the token to burn
     * @param maxChildrenBurns Maximum children to recursively burn
     * @return The number of recursive burns it took to burn all of the children
     */
    function _burn(
        uint256 tokenId,
        uint256 maxChildrenBurns
    ) internal virtual returns (uint256) {
        (address immediateOwner, uint256 parentId, ) = directOwnerOf(tokenId);
        address rootOwner = ownerOf(tokenId);

        _beforeTokenTransfer(immediateOwner, address(0), tokenId);
        _beforeNestedTokenTransfer(
            immediateOwner,
            address(0),
            parentId,
            0,
            tokenId,
            ""
        );

        _balances[immediateOwner] -= 1;
        _approve(address(0), tokenId);
        _cleanApprovals(tokenId);

        Child[] memory children = childrenOf(tokenId);

        delete _activeChildren[tokenId];
        delete _pendingChildren[tokenId];
        delete _tokenApprovals[tokenId][rootOwner];

        uint256 pendingRecursiveBurns;
        uint256 totalChildBurns;

        uint256 length = children.length; //gas savings
        for (uint256 i; i < length; ) {
            if (totalChildBurns >= maxChildrenBurns)
                revert RMRKMaxRecursiveBurnsReached(
                    children[i].contractAddress,
                    children[i].tokenId
                );
            delete _childIsInActive[children[i].contractAddress][
                children[i].tokenId
            ];
            unchecked {
                // At this point we know pendingRecursiveBurns must be at least 1
                pendingRecursiveBurns = maxChildrenBurns - totalChildBurns;
            }
            // We substract one to the next level to count for the token being burned, then add it again on returns
            // This is to allow the behavior of 0 recursive burns meaning only the current token is deleted.
            totalChildBurns +=
                IERC7401(children[i].contractAddress).burn(
                    children[i].tokenId,
                    pendingRecursiveBurns - 1
                ) +
                1;
            unchecked {
                ++i;
            }
        }
        // Can't remove before burning child since child will call back to get root owner
        delete _RMRKOwners[tokenId];

        emit Transfer(immediateOwner, address(0), tokenId);
        emit NestTransfer(immediateOwner, address(0), parentId, 0, tokenId);

        _afterTokenTransfer(immediateOwner, address(0), tokenId);
        _afterNestedTokenTransfer(
            immediateOwner,
            address(0),
            parentId,
            0,
            tokenId,
            ""
        );

        return totalChildBurns;
    }

    ////////////////////////////////////////
    //              APPROVALS
    ////////////////////////////////////////

    /**
     * @notice Used to grant a one-time approval to manage one's token.
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * @dev The approval is cleared when the token is transferred.
     * @dev Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     * @dev Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     * @dev Emits an {Approval} event.
     * @param to Address receiving the approval
     * @param tokenId ID of the token for which the approval is being granted
     */
    function approve(address to, uint256 tokenId) public virtual {
        address owner = ownerOf(tokenId);
        if (to == owner) revert ERC721ApprovalToCurrentOwner();

        if (_msgSender() != owner && !isApprovedForAll(owner, _msgSender()))
            revert ERC721ApproveCallerIsNotOwnerNorApprovedForAll();

        _approve(to, tokenId);
    }

    /**
     * @notice Used to retrieve the account approved to manage given token.
     * @dev Requirements:
     *
     *  - `tokenId` must exist.
     * @param tokenId ID of the token to check for approval
     * @return Address of the account approved to manage the token
     */
    function getApproved(
        uint256 tokenId
    ) public view virtual returns (address) {
        _requireMinted(tokenId);

        return _tokenApprovals[tokenId][ownerOf(tokenId)];
    }

    /**
     * @notice Used to approve or remove `operator` as an operator for the caller.
     * @dev Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     * @dev Requirements:
     *
     * - The `operator` cannot be the caller.
     * @dev Emits an {ApprovalForAll} event.
     * @param operator Address of the operator being managed
     * @param approved A boolean value signifying whether the approval is being granted (`true`) or (`revoked`)
     */
    function setApprovalForAll(address operator, bool approved) public virtual {
        if (_msgSender() == operator) revert ERC721ApproveToCaller();
        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @notice Used to check if the given address is allowed to manage the tokens of the specified address.
     * @param owner Address of the owner of the tokens
     * @param operator Address being checked for approval
     * @return A boolean value signifying whether the *operator* is allowed to manage the tokens of the *owner* (`true`)
     *  or not (`false`)
     */
    function isApprovedForAll(
        address owner,
        address operator
    ) public view virtual returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @notice Used to grant an approval to manage a given token.
     * @dev Emits an {Approval} event.
     * @param to Address to which the approval is being granted
     * @param tokenId ID of the token for which the approval is being granted
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        address owner = ownerOf(tokenId);
        _tokenApprovals[tokenId][owner] = to;
        emit Approval(owner, to, tokenId);
    }

    /**
     * @notice Used to update the owner of the token and clear the approvals associated with the previous owner.
     * @dev The `destinationId` should equal `0` if the new owner is an externally owned account.
     * @param tokenId ID of the token being updated
     * @param destinationId ID of the token to receive the given token
     * @param to Address of account to receive the token
     */
    function _updateOwnerAndClearApprovals(
        uint256 tokenId,
        uint256 destinationId,
        address to
    ) internal {
        _RMRKOwners[tokenId] = DirectOwner({
            ownerAddress: to,
            tokenId: destinationId
        });

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);
        _cleanApprovals(tokenId);
    }

    /**
     * @notice Used to remove approvals for the current owner of the given token.
     * @param tokenId ID of the token to clear the approvals for
     */
    function _cleanApprovals(uint256 tokenId) internal virtual {}

    ////////////////////////////////////////
    //              UTILS
    ////////////////////////////////////////

    /**
     * @notice Used to check whether the given account is allowed to manage the given token.
     * @dev Requirements:
     *
     *  - `tokenId` must exist.
     * @param spender Address that is being checked for approval
     * @param tokenId ID of the token being checked
     * @return A boolean value indicating whether the `spender` is approved to manage the given token
     */
    function _isApprovedOrOwner(
        address spender,
        uint256 tokenId
    ) internal view virtual returns (bool) {
        address owner = ownerOf(tokenId);
        return (spender == owner ||
            isApprovedForAll(owner, spender) ||
            getApproved(tokenId) == spender);
    }

    /**
     * @notice Used to check whether the account is approved to manage the token or its direct owner.
     * @param spender Address that is being checked for approval or direct ownership
     * @param tokenId ID of the token being checked
     * @return A boolean value indicating whether the `spender` is approved to manage the given token or its
     *  direct owner
     */
    function _isApprovedOrDirectOwner(
        address spender,
        uint256 tokenId
    ) internal view virtual returns (bool) {
        (address owner, uint256 parentId, ) = directOwnerOf(tokenId);
        // When the parent is an NFT, only it can do operations
        if (parentId != 0) {
            return (spender == owner);
        }
        // Otherwise, the owner or approved address can
        return (spender == owner ||
            isApprovedForAll(owner, spender) ||
            getApproved(tokenId) == spender);
    }

    /**
     * @notice Used to enforce that the given token has been minted.
     * @dev Reverts if the `tokenId` has not been minted yet.
     * @dev The validation checks whether the owner of a given token is a `0x0` address and considers it not minted if
     *  it is. This means that both tokens that haven't been minted yet as well as the ones that have already been
     *  burned will cause the transaction to be reverted.
     * @param tokenId ID of the token to check
     */
    function _requireMinted(uint256 tokenId) internal view virtual {
        if (!_exists(tokenId)) revert ERC721InvalidTokenId();
    }

    /**
     * @notice Used to check whether the given token exists.
     * @dev Tokens start existing when they are minted (`_mint`) and stop existing when they are burned (`_burn`).
     * @param tokenId ID of the token being checked
     * @return A boolean value signifying whether the token exists
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _RMRKOwners[tokenId].ownerAddress != address(0);
    }

    /**
     * @notice Used to invoke {IERC721Receiver-onERC721Received} on a target address.
     * @dev The call is not executed if the target address is not a contract.
     * @param from Address representing the previous owner of the given token
     * @param to Yarget address that will receive the tokens
     * @param tokenId ID of the token to be transferred
     * @param data Optional data to send along with the call
     * @return Boolean value signifying whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.isContract()) {
            try
                IERC721Receiver(to).onERC721Received(
                    _msgSender(),
                    from,
                    tokenId,
                    data
                )
            returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == uint256(0)) {
                    revert ERC721TransferToNonReceiverImplementer();
                } else {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    ////////////////////////////////////////
    //      CHILD MANAGEMENT PUBLIC
    ////////////////////////////////////////

    /**
     * @inheritdoc IERC7401
     */
    function addChild(
        uint256 parentId,
        uint256 childId,
        bytes memory data
    ) public virtual {
        _requireMinted(parentId);

        address childAddress = _msgSender();
        if (!childAddress.isContract()) revert RMRKIsNotContract();

        Child memory child = Child({
            contractAddress: childAddress,
            tokenId: childId
        });

        _beforeAddChild(parentId, childAddress, childId, data);

        uint256 length = pendingChildrenOf(parentId).length;

        if (length < 128) {
            _pendingChildren[parentId].push(child);
        } else {
            revert RMRKMaxPendingChildrenReached();
        }

        // Previous length matches the index for the new child
        emit ChildProposed(parentId, length, childAddress, childId);

        _afterAddChild(parentId, childAddress, childId, data);
    }

    /**
     * @inheritdoc IERC7401
     */
    function acceptChild(
        uint256 parentId,
        uint256 childIndex,
        address childAddress,
        uint256 childId
    ) public virtual onlyApprovedOrOwner(parentId) {
        _acceptChild(parentId, childIndex, childAddress, childId);
    }

    /**
     * @notice Used to accept a pending child token for a given parent token.
     * @dev This moves the child token from parent token's pending child tokens array into the active child tokens
     *  array.
     * @dev Requirements:
     *
     *  - `tokenId` must exist
     *  - `index` must be in range of the pending children array
     * @dev Emits ***ChildAccepted*** event.
     * @param parentId ID of the parent token for which the child token is being accepted
     * @param childIndex Index of a child tokem in the given parent's pending children array
     * @param childAddress Address of the collection smart contract of the child token expected to be located at the
     *  specified index of the given parent token's pending children array
     * @param childId ID of the child token expected to be located at the specified index of the given parent token's
     *  pending children array
     */
    function _acceptChild(
        uint256 parentId,
        uint256 childIndex,
        address childAddress,
        uint256 childId
    ) internal virtual {
        Child memory child = pendingChildOf(parentId, childIndex);
        _checkExpectedChild(child, childAddress, childId);
        if (_childIsInActive[childAddress][childId] != 0)
            revert RMRKChildAlreadyExists();

        _beforeAcceptChild(parentId, childIndex, childAddress, childId);

        // Remove from pending:
        _removeChildByIndex(_pendingChildren[parentId], childIndex);

        // Add to active:
        _activeChildren[parentId].push(child);
        _childIsInActive[childAddress][childId] = 1; // We use 1 as true

        emit ChildAccepted(parentId, childIndex, childAddress, childId);

        _afterAcceptChild(parentId, childIndex, childAddress, childId);
    }

    /**
     * @inheritdoc IERC7401
     */
    function rejectAllChildren(
        uint256 tokenId,
        uint256 maxRejections
    ) public virtual onlyApprovedOrOwner(tokenId) {
        _rejectAllChildren(tokenId, maxRejections);
    }

    /**
     * @notice Used to reject all pending children of a given parent token.
     * @dev Removes the children from the pending array mapping.
     * @dev This does not update the ownership storage data on children. If necessary, ownership can be reclaimed by the
     *  rootOwner of the previous parent.
     * @dev Requirements:
     *
     *  - `tokenId` must exist
     * @dev Emits ***AllChildrenRejected*** event.
     * @param tokenId ID of the parent token for which to reject all of the pending tokens.
     * @param maxRejections Maximum number of expected children to reject, used to prevent from rejecting children which
     *  arrive just before this operation.
     */
    function _rejectAllChildren(
        uint256 tokenId,
        uint256 maxRejections
    ) internal virtual {
        if (_pendingChildren[tokenId].length > maxRejections)
            revert RMRKUnexpectedNumberOfChildren();

        _beforeRejectAllChildren(tokenId);
        delete _pendingChildren[tokenId];
        emit AllChildrenRejected(tokenId);
        _afterRejectAllChildren(tokenId);
    }

    /**
     * @inheritdoc IERC7401
     */
    function transferChild(
        uint256 tokenId,
        address to,
        uint256 destinationId,
        uint256 childIndex,
        address childAddress,
        uint256 childId,
        bool isPending,
        bytes memory data
    ) public virtual onlyApprovedOrOwner(tokenId) {
        _transferChild(
            tokenId,
            to,
            destinationId,
            childIndex,
            childAddress,
            childId,
            isPending,
            data
        );
    }

    /**
     * @notice Used to transfer a child token from a given parent token.
     * @dev When transferring a child token, the owner of the token is set to `to`, or is not updated in the event of
     *  `to` being the `0x0` address.
     * @dev Requirements:
     *
     *  - `tokenId` must exist.
     * @dev Emits {ChildTransferred} event.
     * @param tokenId ID of the parent token from which the child token is being transferred
     * @param to Address to which to transfer the token to
     * @param destinationId ID of the token to receive this child token (MUST be 0 if the destination is not a token)
     * @param childIndex Index of a token we are transferring, in the array it belongs to (can be either active array or
     *  pending array)
     * @param childAddress Address of the child token's collection smart contract.
     * @param childId ID of the child token in its own collection smart contract.
     * @param isPending A boolean value indicating whether the child token being transferred is in the pending array of
     *  the parent token (`true`) or in the active array (`false`)
     * @param data Additional data with no specified format, sent in call to `_to`
     */
    function _transferChild(
        uint256 tokenId,
        address to,
        uint256 destinationId, // newParentId
        uint256 childIndex,
        address childAddress,
        uint256 childId,
        bool isPending,
        bytes memory data
    ) internal virtual {
        Child memory child;
        if (isPending) {
            child = pendingChildOf(tokenId, childIndex);
        } else {
            child = childOf(tokenId, childIndex);
        }
        _checkExpectedChild(child, childAddress, childId);

        _beforeTransferChild(
            tokenId,
            childIndex,
            childAddress,
            childId,
            isPending,
            data
        );

        if (isPending) {
            _removeChildByIndex(_pendingChildren[tokenId], childIndex);
        } else {
            delete _childIsInActive[childAddress][childId];
            _removeChildByIndex(_activeChildren[tokenId], childIndex);
        }

        if (to != address(0)) {
            if (destinationId == uint256(0)) {
                IERC721(childAddress).safeTransferFrom(
                    address(this),
                    to,
                    childId,
                    data
                );
            } else {
                // Destination is an NFT
                IERC7401(child.contractAddress).nestTransferFrom(
                    address(this),
                    to,
                    child.tokenId,
                    destinationId,
                    data
                );
            }
        }

        emit ChildTransferred(
            tokenId,
            childIndex,
            childAddress,
            childId,
            isPending,
            to == address(0)
        );
        _afterTransferChild(
            tokenId,
            childIndex,
            childAddress,
            childId,
            isPending,
            data
        );
    }

    /**
     * @notice Used to verify that the child being accessed is the intended child.
     * @dev The Child struct consists of the following values:
     *  [
     *      tokenId,
     *      contractAddress
     *  ]
     * @param child A Child struct of a child being accessed
     * @param expectedAddress The address expected to be the one of the child
     * @param expectedId The token ID expected to be the one of the child
     */
    function _checkExpectedChild(
        Child memory child,
        address expectedAddress,
        uint256 expectedId
    ) private pure {
        if (
            expectedAddress != child.contractAddress ||
            expectedId != child.tokenId
        ) revert RMRKUnexpectedChildId();
    }

    ////////////////////////////////////////
    //      CHILD MANAGEMENT GETTERS
    ////////////////////////////////////////

    /**
     * @inheritdoc IERC7401
     */

    function childrenOf(
        uint256 parentId
    ) public view virtual returns (Child[] memory) {
        Child[] memory children = _activeChildren[parentId];
        return children;
    }

    /**
     * @inheritdoc IERC7401
     */

    function pendingChildrenOf(
        uint256 parentId
    ) public view virtual returns (Child[] memory) {
        Child[] memory pendingChildren = _pendingChildren[parentId];
        return pendingChildren;
    }

    /**
     * @inheritdoc IERC7401
     */
    function childOf(
        uint256 parentId,
        uint256 index
    ) public view virtual returns (Child memory) {
        if (childrenOf(parentId).length <= index)
            revert RMRKChildIndexOutOfRange();
        Child memory child = _activeChildren[parentId][index];
        return child;
    }

    /**
     * @inheritdoc IERC7401
     */
    function pendingChildOf(
        uint256 parentId,
        uint256 index
    ) public view virtual returns (Child memory) {
        if (pendingChildrenOf(parentId).length <= index)
            revert RMRKPendingChildIndexOutOfRange();
        Child memory child = _pendingChildren[parentId][index];
        return child;
    }

    // HOOKS

    /**
     * @notice Hook that is called before any token transfer. This includes minting and burning.
     * @dev Calling conditions:
     *
     *  - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be transferred to `to`.
     *  - When `from` is zero, `tokenId` will be minted to `to`.
     *  - When `to` is zero, ``from``'s `tokenId` will be burned.
     *  - `from` and `to` are never zero at the same time.
     *
     *  To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     * @param from Address from which the token is being transferred
     * @param to Address to which the token is being transferred
     * @param tokenId ID of the token being transferred
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @notice Hook that is called after any transfer of tokens. This includes minting and burning.
     * @dev Calling conditions:
     *
     *  - When `from` and `to` are both non-zero.
     *  - `from` and `to` are never zero at the same time.
     *
     *  To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     * @param from Address from which the token has been transferred
     * @param to Address to which the token has been transferred
     * @param tokenId ID of the token that has been transferred
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @notice Hook that is called before nested token transfer.
     * @dev To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     * @param from Address from which the token is being transferred
     * @param to Address to which the token is being transferred
     * @param fromTokenId ID of the token from which the given token is being transferred
     * @param toTokenId ID of the token to which the given token is being transferred
     * @param tokenId ID of the token being transferred
     * @param data Additional data with no specified format, sent in the addChild call
     */
    function _beforeNestedTokenTransfer(
        address from,
        address to,
        uint256 fromTokenId,
        uint256 toTokenId,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {}

    /**
     * @notice Hook that is called after nested token transfer.
     * @dev To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     * @param from Address from which the token was transferred
     * @param to Address to which the token was transferred
     * @param fromTokenId ID of the token from which the given token was transferred
     * @param toTokenId ID of the token to which the given token was transferred
     * @param tokenId ID of the token that was transferred
     * @param data Additional data with no specified format, sent in the addChild call
     */
    function _afterNestedTokenTransfer(
        address from,
        address to,
        uint256 fromTokenId,
        uint256 toTokenId,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {}

    /**
     * @notice Hook that is called before a child is added to the pending tokens array of a given token.
     * @dev The Child struct consists of the following values:
     *  [
     *      tokenId,
     *      contractAddress
     *  ]
     * @dev To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     * @param tokenId ID of the token that will receive a new pending child token
     * @param childAddress Address of the collection smart contract of the child token expected to be located at the
     *  specified index of the given parent token's pending children array
     * @param childId ID of the child token expected to be located at the specified index of the given parent token's
     *  pending children array
     * @param data Additional data with no specified format
     */
    function _beforeAddChild(
        uint256 tokenId,
        address childAddress,
        uint256 childId,
        bytes memory data
    ) internal virtual {}

    /**
     * @notice Hook that is called after a child is added to the pending tokens array of a given token.
     * @dev The Child struct consists of the following values:
     *  [
     *      tokenId,
     *      contractAddress
     *  ]
     * @dev To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     * @param tokenId ID of the token that has received a new pending child token
     * @param childAddress Address of the collection smart contract of the child token expected to be located at the
     *  specified index of the given parent token's pending children array
     * @param childId ID of the child token expected to be located at the specified index of the given parent token's
     *  pending children array
     * @param data Additional data with no specified format
     */
    function _afterAddChild(
        uint256 tokenId,
        address childAddress,
        uint256 childId,
        bytes memory data
    ) internal virtual {}

    /**
     * @notice Hook that is called before a child is accepted to the active tokens array of a given token.
     * @dev The Child struct consists of the following values:
     *  [
     *      tokenId,
     *      contractAddress
     *  ]
     * @dev To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     * @param parentId ID of the token that will accept a pending child token
     * @param childIndex Index of the child token to accept in the given parent token's pending children array
     * @param childAddress Address of the collection smart contract of the child token expected to be located at the
     *  specified index of the given parent token's pending children array
     * @param childId ID of the child token expected to be located at the specified index of the given parent token's
     *  pending children array
     */
    function _beforeAcceptChild(
        uint256 parentId,
        uint256 childIndex,
        address childAddress,
        uint256 childId
    ) internal virtual {}

    /**
     * @notice Hook that is called after a child is accepted to the active tokens array of a given token.
     * @dev The Child struct consists of the following values:
     *  [
     *      tokenId,
     *      contractAddress
     *  ]
     * @dev To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     * @param parentId ID of the token that has accepted a pending child token
     * @param childIndex Index of the child token that was accpeted in the given parent token's pending children array
     * @param childAddress Address of the collection smart contract of the child token that was expected to be located
     *  at the specified index of the given parent token's pending children array
     * @param childId ID of the child token that was expected to be located at the specified index of the given parent
     *  token's pending children array
     */
    function _afterAcceptChild(
        uint256 parentId,
        uint256 childIndex,
        address childAddress,
        uint256 childId
    ) internal virtual {}

    /**
     * @notice Hook that is called before a child is transferred from a given child token array of a given token.
     * @dev The Child struct consists of the following values:
     *  [
     *      tokenId,
     *      contractAddress
     *  ]
     * @dev To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     * @param tokenId ID of the token that will transfer a child token
     * @param childIndex Index of the child token that will be transferred from the given parent token's children array
     * @param childAddress Address of the collection smart contract of the child token that is expected to be located
     *  at the specified index of the given parent token's children array
     * @param childId ID of the child token that is expected to be located at the specified index of the given parent
     *  token's children array
     * @param isPending A boolean value signifying whether the child token is being transferred from the pending child
     *  tokens array (`true`) or from the active child tokens array (`false`)
     * @param data Additional data with no specified format, sent in the addChild call
     */
    function _beforeTransferChild(
        uint256 tokenId,
        uint256 childIndex,
        address childAddress,
        uint256 childId,
        bool isPending,
        bytes memory data
    ) internal virtual {}

    /**
     * @notice Hook that is called after a child is transferred from a given child token array of a given token.
     * @dev The Child struct consists of the following values:
     *  [
     *      tokenId,
     *      contractAddress
     *  ]
     * @dev To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     * @param tokenId ID of the token that has transferred a child token
     * @param childIndex Index of the child token that was transferred from the given parent token's children array
     * @param childAddress Address of the collection smart contract of the child token that was expected to be located
     *  at the specified index of the given parent token's children array
     * @param childId ID of the child token that was expected to be located at the specified index of the given parent
     *  token's children array
     * @param isPending A boolean value signifying whether the child token was transferred from the pending child tokens
     *  array (`true`) or from the active child tokens array (`false`)
     * @param data Additional data with no specified format, sent in the addChild call
     */
    function _afterTransferChild(
        uint256 tokenId,
        uint256 childIndex,
        address childAddress,
        uint256 childId,
        bool isPending,
        bytes memory data
    ) internal virtual {}

    /**
     * @notice Hook that is called before a pending child tokens array of a given token is cleared.
     * @dev To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     * @param tokenId ID of the token that will reject all of the pending child tokens
     */
    function _beforeRejectAllChildren(uint256 tokenId) internal virtual {}

    /**
     * @notice Hook that is called after a pending child tokens array of a given token is cleared.
     * @dev To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     * @param tokenId ID of the token that has rejected all of the pending child tokens
     */
    function _afterRejectAllChildren(uint256 tokenId) internal virtual {}

    // HELPERS

    /**
     * @notice Used to remove a specified child token form an array using its index within said array.
     * @dev The caller must ensure that the length of the array is valid compared to the index passed.
     * @dev The Child struct consists of the following values:
     *  [
     *      tokenId,
     *      contractAddress
     *  ]
     * @param array An array od Child struct containing info about the child tokens in a given child tokens array
     * @param index An index of the child token to remove in the accompanying array
     */
    function _removeChildByIndex(Child[] storage array, uint256 index) private {
        array[index] = array[array.length - 1];
        array.pop();
    }
}

// File: @openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;


/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// File: @rmrk-team/evm-contracts/contracts/implementations/abstract/RMRKAbstractNestable.sol



pragma solidity ^0.8.21;




/**
 * @title RMRKAbstractNestable
 * @author RMRK team
 * @notice Abstract implementation of RMRK nestable module.
 */
abstract contract RMRKAbstractNestable is RMRKImplementationBase, RMRKNestable {
    /**
     * @inheritdoc IERC165
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override returns (bool) {
        return
            super.supportsInterface(interfaceId) ||
            interfaceId == type(IERC2981).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            interfaceId == RMRK_INTERFACE;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);
        if (to == address(0)) {
            unchecked {
                _totalSupply -= 1;
            }
        }
    }
}

// File: NPCustoms.sol

pragma solidity ^0.8.21;

contract NonPlayableCustoms is RMRKAbstractNestable, RMRKTokenURIEnumerated {
    uint256 private _pricePerMint;
    address private _erc20TokenAddress;

    constructor(
      string memory collectionMetadata,
      uint256 maxSupply,
      address royaltyRecipient,
      uint16 royaltyPercentageBps,
      string memory baseTokenURI,
      uint256 pricePerMint_,
      address erc20TokenAddress_
    )
        RMRKImplementationBase(
            "Non-Playable Customs",
            "NPCustom",
            collectionMetadata,
            maxSupply,
            royaltyRecipient,
            royaltyPercentageBps
        )
      RMRKTokenURIEnumerated(baseTokenURI)
    {
      _pricePerMint = pricePerMint_;
      _erc20TokenAddress = erc20TokenAddress_;
    }

     // Methods
    // Suggested Mint Functions
    /**
     * @notice Used to mint the desired number of tokens to the specified address.
     * @dev The "data" value of the "_safeMint" method is set to an empty value.
     * @dev Can only be called while the open sale is open.
     * @param to Address to which to mint the token
     * @param numToMint Number of tokens to mint
     * @return The ID of the first token to be minted in the current minting cycle
     */
    function mint(
        address to,
        uint256 numToMint
    ) public returns (uint256) {
        (uint256 nextToken, uint256 totalSupplyOffset) = _prepareMint(
            numToMint
        );
        _chargeMints(numToMint);

        for (uint256 i = nextToken; i < totalSupplyOffset; ) {
            _safeMint(to, i, "");
            unchecked {
                ++i;
            }
        }

        return nextToken;
    }
        
    /**
     * @notice Used to mint a desired number of child tokens to a given parent token.
     * @dev The "data" value of the "_safeMint" method is set to an empty value.
     * @dev Can only be called while the open sale is open.
     * @param to Address of the collection smart contract of the token into which to mint the child token
     * @param numToMint Number of tokens to mint
     * @param destinationId ID of the token into which to mint the new child token
     * @return The ID of the first token to be minted in the current minting cycle
     */
    function nestMint(
        address to,
        uint256 numToMint,
        uint256 destinationId
    ) public returns (uint256) {
        (uint256 nextToken, uint256 totalSupplyOffset) = _prepareMint(
            numToMint
        );
        _chargeMints(numToMint);

        for (uint256 i = nextToken; i < totalSupplyOffset; ) {
            _nestMint(to, i, destinationId, "");
            unchecked {
                ++i;
            }
        }

        return nextToken;
    }
    
        /**
         * @notice Used to charge the minter for the amount of tokens they desire to mint.
         * @param numToMint The amount of tokens to charge the caller for
         */
        function _chargeMints(uint256 numToMint) internal {
            uint256 price = numToMint * _pricePerMint;
            IERC20(_erc20TokenAddress).transferFrom(
                msg.sender,
                address(0x000000000000000000000000000000000000dEaD),
                price
            );
        }
    
        /**
         * @notice Used to retrieve the address of the ERC20 token this smart contract supports.
         * @return Address of the ERC20 token's smart contract
         */
        function NPCTokenAddress() public view virtual returns (address) {
            return _erc20TokenAddress;
        }
    
        /**
         * @notice Used to retrieve the price per mint.
         * @return The price per mint of a single token expressed in the lowest denomination of a native currency
         */
        function pricePerMint() public view returns (uint256) {
            return _pricePerMint;
        }
}