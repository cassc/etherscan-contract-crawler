/**
 *Submitted for verification at Etherscan.io on 2023-07-07
*/

// SPDX-License-Identifier: MIT

// Sources flattened with hardhat v2.9.3 https://hardhat.org

// File @openzeppelin/contracts/token/ERC20/[email protected]


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
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
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}


// File @openzeppelin/contracts/utils/introspection/[email protected]


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


// File @openzeppelin/contracts/token/ERC721/[email protected]


// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

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
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

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
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

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
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

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
    function setApprovalForAll(address operator, bool _approved) external;

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


// File @openzeppelin/contracts/utils/math/[email protected]


// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

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
        // ΓåÆ `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // ΓåÆ `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
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
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
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
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
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
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
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
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}


// File @openzeppelin/contracts/utils/[email protected]


// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

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
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
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


// File @openzeppelin/contracts/utils/cryptography/[email protected]


// OpenZeppelin Contracts (last updated v4.8.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV // Deprecated in v4.8
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ├╖ 2 + 1, and for v in (302): v Γêê {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}


// File contracts/utils/AccessControl.sol


pragma solidity 0.8.18;

/**
 * @title Access Control List
 *
 * @notice Access control smart contract provides an API to check
 *      if specific operation is permitted globally and/or
 *      if particular user has a permission to execute it.
 *
 * @notice It deals with two main entities: features and roles.
 *
 * @notice Features are designed to be used to enable/disable specific
 *      functions (public functions) of the smart contract for everyone.
 * @notice User roles are designed to restrict access to specific
 *      functions (restricted functions) of the smart contract to some users.
 *
 * @notice Terms "role", "permissions" and "set of permissions" have equal meaning
 *      in the documentation text and may be used interchangeably.
 * @notice Terms "permission", "single permission" implies only one permission bit set.
 *
 * @notice Access manager is a special role which allows to grant/revoke other roles.
 *      Access managers can only grant/revoke permissions which they have themselves.
 *      As an example, access manager with no other roles set can only grant/revoke its own
 *      access manager permission and nothing else.
 *
 * @notice Access manager permission should be treated carefully, as a super admin permission:
 *      Access manager with even no other permission can interfere with another account by
 *      granting own access manager permission to it and effectively creating more powerful
 *      permission set than its own.
 *
 * @dev Both current and OpenZeppelin AccessControl implementations feature a similar API
 *      to check/know "who is allowed to do this thing".
 * @dev Zeppelin implementation is more flexible:
 *      - it allows setting unlimited number of roles, while current is limited to 256 different roles
 *      - it allows setting an admin for each role, while current allows having only one global admin
 * @dev Current implementation is more lightweight:
 *      - it uses only 1 bit per role, while Zeppelin uses 256 bits
 *      - it allows setting up to 256 roles at once, in a single transaction, while Zeppelin allows
 *        setting only one role in a single transaction
 *
 * @dev This smart contract is designed to be inherited by other
 *      smart contracts which require access control management capabilities.
 *
 * @dev Access manager permission has a bit 255 set.
 *      This bit must not be used by inheriting contracts for any other permissions/features.
 */
contract AccessControl {
	/**
	 * @notice Access manager is responsible for assigning the roles to users,
	 *      enabling/disabling global features of the smart contract
	 * @notice Access manager can add, remove and update user roles,
	 *      remove and update global features
	 *
	 * @dev Role ROLE_ACCESS_MANAGER allows modifying user roles and global features
	 * @dev Role ROLE_ACCESS_MANAGER has single bit at position 255 enabled
	 */
	uint256 public constant ROLE_ACCESS_MANAGER = 0x8000000000000000000000000000000000000000000000000000000000000000;

	/**
	 * @dev Bitmask representing all the possible permissions (super admin role)
	 * @dev Has all the bits are enabled (2^256 - 1 value)
	 */
	uint256 private constant FULL_PRIVILEGES_MASK = type(uint256).max; // before 0.8.0: uint256(-1) overflows to 0xFFFF...

	/**
	 * @notice Privileged addresses with defined roles/permissions
	 * @notice In the context of ERC20/ERC721 tokens these can be permissions to
	 *      allow minting or burning tokens, transferring on behalf and so on
	 *
	 * @dev Maps user address to the permissions bitmask (role), where each bit
	 *      represents a permission
	 * @dev Bitmask 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
	 *      represents all possible permissions
	 * @dev 'This' address mapping represents global features of the smart contract
	 */
	mapping(address => uint256) public userRoles;

	/**
	 * @dev Fired in updateRole() and updateFeatures()
	 *
	 * @param _by operator which called the function
	 * @param _to address which was granted/revoked permissions
	 * @param _requested permissions requested
	 * @param _actual permissions effectively set
	 */
	event RoleUpdated(address indexed _by, address indexed _to, uint256 _requested, uint256 _actual);

	/**
	 * @notice Creates an access control instance,
	 *      setting contract creator to have full privileges
	 */
	constructor() {
		// contract creator has full privileges
		userRoles[msg.sender] = FULL_PRIVILEGES_MASK;
	}

	/**
	 * @notice Retrieves globally set of features enabled
	 *
	 * @dev Effectively reads userRoles role for the contract itself
	 *
	 * @return 256-bit bitmask of the features enabled
	 */
	function features() public view returns(uint256) {
		// features are stored in 'this' address  mapping of `userRoles` structure
		return userRoles[address(this)];
	}

	/**
	 * @notice Updates set of the globally enabled features (`features`),
	 *      taking into account sender's permissions
	 *
	 * @dev Requires transaction sender to have `ROLE_ACCESS_MANAGER` permission
	 * @dev Function is left for backward compatibility with older versions
	 *
	 * @param _mask bitmask representing a set of features to enable/disable
	 */
	function updateFeatures(uint256 _mask) public {
		// delegate call to `updateRole`
		updateRole(address(this), _mask);
	}

	/**
	 * @notice Updates set of permissions (role) for a given user,
	 *      taking into account sender's permissions.
	 *
	 * @dev Setting role to zero is equivalent to removing an all permissions
	 * @dev Setting role to `FULL_PRIVILEGES_MASK` is equivalent to
	 *      copying senders' permissions (role) to the user
	 * @dev Requires transaction sender to have `ROLE_ACCESS_MANAGER` permission
	 *
	 * @param operator address of a user to alter permissions for or zero
	 *      to alter global features of the smart contract
	 * @param role bitmask representing a set of permissions to
	 *      enable/disable for a user specified
	 */
	function updateRole(address operator, uint256 role) public {
		// caller must have a permission to update user roles
		require(isSenderInRole(ROLE_ACCESS_MANAGER), "access denied");

		// evaluate the role and reassign it
		userRoles[operator] = evaluateBy(msg.sender, userRoles[operator], role);

		// fire an event
		emit RoleUpdated(msg.sender, operator, role, userRoles[operator]);
	}

	/**
	 * @notice Determines the permission bitmask an operator can set on the
	 *      target permission set
	 * @notice Used to calculate the permission bitmask to be set when requested
	 *     in `updateRole` and `updateFeatures` functions
	 *
	 * @dev Calculated based on:
	 *      1) operator's own permission set read from userRoles[operator]
	 *      2) target permission set - what is already set on the target
	 *      3) desired permission set - what do we want set target to
	 *
	 * @dev Corner cases:
	 *      1) Operator is super admin and its permission set is `FULL_PRIVILEGES_MASK`:
	 *        `desired` bitset is returned regardless of the `target` permission set value
	 *        (what operator sets is what they get)
	 *      2) Operator with no permissions (zero bitset):
	 *        `target` bitset is returned regardless of the `desired` value
	 *        (operator has no authority and cannot modify anything)
	 *
	 * @dev Example:
	 *      Consider an operator with the permissions bitmask     00001111
	 *      is about to modify the target permission set          01010101
	 *      Operator wants to set that permission set to          00110011
	 *      Based on their role, an operator has the permissions
	 *      to update only lowest 4 bits on the target, meaning that
	 *      high 4 bits of the target set in this example is left
	 *      unchanged and low 4 bits get changed as desired:      01010011
	 *
	 * @param operator address of the contract operator which is about to set the permissions
	 * @param target input set of permissions to operator is going to modify
	 * @param desired desired set of permissions operator would like to set
	 * @return resulting set of permissions given operator will set
	 */
	function evaluateBy(address operator, uint256 target, uint256 desired) public view returns(uint256) {
		// read operator's permissions
		uint256 p = userRoles[operator];

		// taking into account operator's permissions,
		// 1) enable the permissions desired on the `target`
		target |= p & desired;
		// 2) disable the permissions desired on the `target`
		target &= FULL_PRIVILEGES_MASK ^ (p & (FULL_PRIVILEGES_MASK ^ desired));

		// return calculated result
		return target;
	}

	/**
	 * @notice Checks if requested set of features is enabled globally on the contract
	 *
	 * @param required set of features to check against
	 * @return true if all the features requested are enabled, false otherwise
	 */
	function isFeatureEnabled(uint256 required) public view returns(bool) {
		// delegate call to `__hasRole`, passing `features` property
		return __hasRole(features(), required);
	}

	/**
	 * @notice Checks if transaction sender `msg.sender` has all the permissions required
	 *
	 * @param required set of permissions (role) to check against
	 * @return true if all the permissions requested are enabled, false otherwise
	 */
	function isSenderInRole(uint256 required) public view returns(bool) {
		// delegate call to `isOperatorInRole`, passing transaction sender
		return isOperatorInRole(msg.sender, required);
	}

	/**
	 * @notice Checks if operator has all the permissions (role) required
	 *
	 * @param operator address of the user to check role for
	 * @param required set of permissions (role) to check
	 * @return true if all the permissions requested are enabled, false otherwise
	 */
	function isOperatorInRole(address operator, uint256 required) public view returns(bool) {
		// delegate call to `__hasRole`, passing operator's permissions (role)
		return __hasRole(userRoles[operator], required);
	}

	/**
	 * @dev Checks if role `actual` contains all the permissions required `required`
	 *
	 * @param actual existent role
	 * @param required required role
	 * @return true if actual has required role (all permissions), false otherwise
	 */
	function __hasRole(uint256 actual, uint256 required) internal pure returns(bool) {
		// check the bitmask for the role required and return the result
		return actual & required == required;
	}
}


// File contracts/interfaces/IERC2981.sol


pragma solidity 0.8.18;

interface IERC2981 {
    /// ERC165 bytes to add to interface array - set in parent contract
    /// implementing this standard
    ///
    /// bytes4(keccak256("royaltyInfo(uint256,uint256)")) == 0x2a55205a
    /// bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;
    /// _registerInterface(_INTERFACE_ID_ERC2981);

    /// @notice Called with the sale price to determine how much royalty
    //          is owed and to whom.
    /// @param _tokenId - the NFT asset queried for royalty information
    /// @param _salePrice - the sale price of the NFT asset specified by _tokenId
    /// @return receiver - address of who should be sent the royalty payment
    /// @return royaltyAmount - the royalty payment amount for _salePrice
    function royaltyInfo(
        uint256 _tokenId,
        uint256 _salePrice
    ) external view returns (
        address receiver,
        uint256 royaltyAmount
    );
}


// File contracts/protocol/MemeMarketplace.sol


pragma solidity 0.8.18;
/**
 * @title MemeCrafter Marketplace
 *
 * @notice Meme Marketplace is an extension smart contract responsible for buy / sell MemeNFTs
 *
 * @notice It supports following mechanisms:
 *      - Fix price listing
 *      - English auction
 *      - Dutch auction
 * 
 * @dev Target user must allow smart contract to transfer the tokens, this should be prechecked
 *      as part of the validation processes
 */
contract MemeMarketplace is AccessControl {
    /**
	 * @dev Meme NFT smart contract to buy / sell tokens of
	 */
    address public immutable memeNFT;

    /**
	 * @dev Treasury wallet address
	 */
    address public treasury;

    /**
     * @dev Enumeration for sale type
     */
    enum SaleType { NOT_FOR_SALE, FIX, ENGLISH, DUTCH }

    /**
     * @dev `Sale` keeps listing information of memeNFT
     */
    struct Sale {
        uint256 startPrice; // Sale price(Fix), start price (Dutch) and base price (English) 
        uint256 endPrice;   // Sale price(Fix), end price (Dutch) and base price (English)
        address token;      // Sale token
        bool forSale;       // Listing status
        uint32 startTime;   // Unix timestamp, sale starts
        uint32 endTime;     // Unix timestamp, sale ends
        SaleType saleType;  // Listing type
    }

    /**
     * @dev `Bid` keeps bidding information, including bidder address and bid amount 
     */
    struct Bid {
        address from;       // Bidder address
        uint256 amount;     // Bid amount
    }

    /**
	 * @notice Sale inforamtion for all tokens listed for sale
	 *
	 * @dev Maps memeNFT tokenId => sale information
	 */
    mapping(uint256 => Sale) public saleData;

    /**
	 * @notice Bid inforamtion for all tokens listed for sale type english auction
	 *
	 * @dev Maps memeNFT tokenId => bid information
	 */
    mapping(uint256 => Bid[]) public auctionBids;

    /**
     * @notice Whitelist information for all tokens
     * 
     * @dev Maps token address => isWhitelisted
     */
    mapping(address => bool) public isWhitelisted;

    /**
	 * @dev A record of used nonces for EIP-712 transactions
	 *
	 * @dev A record of used nonces for signing/validating signatures
	 *      in `buy` and `acceptBid` for every trade
	 *
	 * @dev Maps authorizer address => nonce => true/false (used unused)
	 */
	mapping(address => mapping(bytes32 => bool)) private usedNonces;

	/**
	 * @notice EIP-712 contract's domain separator,
	 *      see https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator
	 */
	bytes32 public immutable DOMAIN_SEPARATOR;

	/**
	 * @notice EIP-712 contract's domain typeHash,
	 *      see https://eips.ethereum.org/EIPS/eip-712#rationale-for-typehash
	 *
	 * @dev Note: we do not include version into the domain typehash/separator,
	 *      it is implied version is concatenated to the name field, like "MemeMarketplace"
	 */
	// keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)")
	bytes32 public constant DOMAIN_TYPEHASH = 0x8cad95687ba82c2ce50e74f7b754645e5117c3a5bec8151c0726d5857980a866;

    /**
	 * @notice EIP-712 BUY struct typeHash,
	 *      see https://eips.ethereum.org/EIPS/eip-712#rationale-for-typehash
	 */
	// keccak256("Buy(uint256 tokenId,uint256 fee,uint256 validAfter,uint256 validBefore,bytes32 nonce)")
	bytes32 public constant BUY_TYPEHASH = 0x6cb56121701961eef0ab3d1a8a8212908886ef509575b1b7ed291601d736da1e;

    /**
	 * @notice EIP-712 AcceptBid struct typeHash,
	 *      see https://eips.ethereum.org/EIPS/eip-712#rationale-for-typehash
	 */
    // keccak256("AcceptBid(uint256 tokenId,uint256 bidIndex,uint256 fee,uint256 validAfter,uint256 validBefore,bytes32 nonce)")
	bytes32 public constant ACCEPT_BID_TYPEHASH = 0x1717913a8a64c8f6bdf4ffe8c221f33d3eecd1526c0f3bac324f04dbbc0b6cdf;

	/**
	 * @notice EIP-712 CancelAuthorization struct typeHash,
	 *      see https://eips.ethereum.org/EIPS/eip-712#rationale-for-typehash
	 */
	// keccak256("CancelAuthorization(address authorizer,bytes32 nonce)")
	bytes32 public constant CANCEL_AUTHORIZATION_TYPEHASH = 0x158b0a9edf7a828aad02f63cd515c68ef2f50ba807396f6d12842833a1597429;
    	
    /**
	 * @notice Fee manager is responsible for charging (marketplace fee)
	 *      in sale token for every trade execute on platform
     * 
	 * @dev Role ROLE_FEE_MANAGER allows tranferring tokens
	 *      (executing `buy` and `acceptBid` function)
	 */
    uint32 public constant ROLE_FEE_MANAGER = 0x0001_0000;

    /**
	 * @notice Treasury manager is responsible for updating `treasury` variable,
	 *      pointing to the treasury wallet address
	 *
	 * @dev Role ROLE_TREASURY_MANAGER allows `updateTreasury` execution,
	 *     and `treasury` modification
	 */
	uint32 public constant ROLE_TREASURY_MANAGER = 0x0002_0000;

    /**
	 * @notice Token manager is responsible for updating `isWhitelisted` variable,
	 *      pointing to the whitelist status of given token
	 *
	 * @dev Role ROLE_TOKEN_MANAGER allows `updateToken` execution,
	 *     and `isWhitelisted` modification
	 */
    uint32 public constant ROLE_TOKEN_MANAGER = 0x0004_0000;

    /**
	 * @dev Fired in list() and listBatch() when memeNFTs is / are listed  
	 *
	 * @param by an address of memeNFT owner
	 * @param tokenId tokenId of listed memeNFT
     * @param startPrice sale price(Fix), start price (Dutch) and base price (English)
     * @param endPrice sale price(Fix), end price (Dutch) and base price (English)
     * @param token sale token address
     * @param startTime unix timestamp, sale starts
     * @param endTime unix timestamp, sale ends
     * @param saleType listing type
     */
    event Listed(
        address indexed by,
        uint256 indexed tokenId,
        uint256 startPrice,
        uint256 endPrice,
        address token,
        uint32 startTime,
        uint32 endTime,
        SaleType saleType
    );

    /**
	 * @dev Fired in revokesale() when memeNFT is delisted  
	 *
	 * @param by an address of memeNFT owner
	 * @param tokenId tokenId of memeNFT to be delisted
     */
    event Delisted(
        address indexed by,
        uint256 indexed tokenId
    );

    /**
	 * @dev Fired in editPrice() when memeNFT relisted at new fix price 
	 *
	 * @param by an address of memeNFT owner
	 * @param tokenId tokenId of relisted memeNFT
     * @param oldPrice fix sale price before relisting
     * @param newPrice fix sale price after relisting
	 */
    event Relisted(
        address indexed by,
        uint256 indexed tokenId,
        uint256 oldPrice,
        uint256 newPrice
    );

    /**
	 * @dev Fired in buy(), acceptBid() when memeNFT bought / sold 
	 *
     * @param buyer an address of buyer
     * @param seller an address of seller
	 * @param tokenId tokenId of traded memeNFT 
     * @param price price paid by buyer
     * @param marketplaceFee fees charged by marketplace
     * @param token sale token address
     * @param saleType listing type
	 */
    event Bought(
        address indexed buyer,
        address indexed seller,
        uint256 indexed tokenId,
        uint256 price,
        uint256 marketplaceFee,
        address token,
        SaleType saleType
    );

    /**
	 * @dev Fired in bidOnAuction() when bid is placed
	 *      for english auction successfully
	 *
	 * @param from an address of bidder
	 * @param tokenId tokenId of bidded memeNFT
	 * @param amount defines bid amount to be paid
	 */
    event BidUpdate(
        address indexed from,
        uint256 indexed tokenId,
        uint256 amount
    );

    /**
	 * @dev Fired in updateTreasury()
	 *
	 * @param by an address which executed the operation
	 * @param oldVal old treasury address
	 * @param newVal new treasury address
	 */
	event TreasuryChanged(address indexed by, address oldVal, address newVal);

    /**
     * @dev Fired in updateToken()
     * 
     * @param by an address which executed the operation
     * @param token address of token
     * @param isWhitelisted whitelisting status  
     */
    event TokenUpdated(address indexed by, address token, bool isWhitelisted);

    /**
	 * @dev Fired whenever the nonce gets used (ex.: `buy`, `acceptBid`)
	 *
	 * @param authorizer an address which has used the nonce
	 * @param nonce the nonce used
	 */
	event AuthorizationUsed(address indexed authorizer, bytes32 indexed nonce);

	/**
	 * @dev Fired whenever the nonce gets cancelled (ex.: `cancelAuthorization`)
	 *
	 * @dev Both `AuthorizationUsed` and `AuthorizationCanceled` imply the nonce
	 *      cannot be longer used, the only difference is that `AuthorizationCanceled`
	 *      implies no smart contract state change made (except the nonce marked as cancelled)
	 *
	 * @param authorizer an address which has cancelled the nonce
	 * @param nonce the nonce cancelled
	 */
	event AuthorizationCanceled(address indexed authorizer, bytes32 indexed nonce);

    /**
	 * Deploys the extension contract bound to the target NFT ERC721 smart contract
     * 
     * @param meme_ address of the deployed memeNFT smart contract instance
     * @param treasury_ address of treasury wallet
     */
    constructor(address meme_, address treasury_) {
        // Build the EIP-712 contract domain separator, see https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator
		// Note: we specify contract version in its name
		DOMAIN_SEPARATOR = keccak256(abi.encode(DOMAIN_TYPEHASH, keccak256(bytes("MemeMarketplace")), block.chainid, address(this)));

        // Verify inputs are set
		require(meme_ != address(0), "Target contract is not set");
        require(treasury_ != address(0), "Treasury address is not set");

        // Setup smart contract internal state
        memeNFT = meme_;
        treasury = treasury_;
    }

    // ===== Start: MemeCrafter NFT Marketplace (view functions) =====

    /**
     * @dev Returns existing sale price of given memeNFT
     * 
     * @param tokenId_ tokenId of memeNFT to get price for
     */
    function getCurrentPrice(uint256 tokenId_) public view returns (uint256) {
        // Compute sale duration
        uint32 duration = saleData[tokenId_].endTime - saleData[tokenId_].startTime;

        // Compute time escaped from sale start
        uint256 secondsPassed = block.timestamp - saleData[tokenId_].startTime;

        // Checks if duration is over
        if (secondsPassed >= duration) {
            // Return end price
            return saleData[tokenId_].endPrice;
        } else {
            // Compute total price change based on duration
            int256 totalPriceChange = int256(saleData[tokenId_].endPrice) - int256(saleData[tokenId_].startPrice);

            // Compute current price change based on seconds passed
            int256 currentPriceChange = totalPriceChange * int256(secondsPassed) / int32(duration);

            // Compute current price
            int256 currentPrice = int256(saleData[tokenId_].startPrice) + currentPriceChange;

            // Return the current price
            return uint256(currentPrice);
        }
    }

    /** 
     * @dev returns number of bids received for given memeNFT listed for english auction
     * 
     * @param tokenId_ unsigned integer defines tokenId 
     */
    function getBidCount(uint256 tokenId_) public view returns (uint256) {
        return auctionBids[tokenId_].length;
    }

    /**
     * @dev Returns bids information for given memeNFT listed for english auction
     * 
     * @param tokenId_ unsigned integer defines tokenId
     */
    function getBids(uint256 tokenId_) public view returns (Bid[] memory) {
        return auctionBids[tokenId_];
    }

    /**
	 * @notice Returns the state of an authorization, more specifically
	 *      if the specified nonce was already used by the address specified
	 *
	 * @dev Nonces are expected to be client-side randomly generated 32-byte data
	 *      unique to the authorizer's address
	 *
	 * @param authorizer_ Authorizer's address
	 * @param nonce_ Nonce of the authorization
	 * @return true if the nonce is used
	 */
	function authorizationState(
		address authorizer_,
		bytes32 nonce_
	) public view returns (bool) {
		// simply return the value from the mapping
		return usedNonces[authorizer_][nonce_];
	}

    // ===== End: MemeCrafter NFT Marketplace (view functions) =====

    // ===== Start: MemeCrafter NFT Marketplace (mutative functions) =====

    /**
	 * @dev Restricted access function to modify treasury wallet address
	 *
	 * @param treasury_ new treasury address to be set
	 */
	function updateTreasury(address treasury_) external {
		// verify the access permission
		require(isSenderInRole(ROLE_TREASURY_MANAGER), "access denied");

		// emit an event
		emit TreasuryChanged(msg.sender, treasury, treasury_);

		// update new treasury address 
		treasury = treasury_;
	}

    /**
     * @dev Restricted access function to modify token whitelist status
     * 
     * @param token_ address of token
     * @param isWhitelisted_ whitelisting status
     */
    function updateToken(address token_, bool isWhitelisted_) external {
        // verify the access permission
		require(isSenderInRole(ROLE_TOKEN_MANAGER), "access denied");
        
        // update whitelist status
        isWhitelisted[token_] = isWhitelisted_;

        // emit an event
        emit TokenUpdated(msg.sender, token_, isWhitelisted_);
    }

    /**
     * @dev Allows to list memeNFT for sale
     * 
     * @param tokenId_ tokenId of memeNFT to list
     * @param startPrice_ sale price(Fix), start price (Dutch) and base price (English)
     * @param endPrice_ sale price(Fix), end price (Dutch) and base price (English)
     * @param token_ sale token address
     * @param startTime_ unix timestamp, sale starts
     * @param endTime_ unix timestamp, sale ends
     * @param saleType_ listing type
     */
    function list(
        uint256 tokenId_,
        uint256 startPrice_,
        uint256 endPrice_,
        address token_,
        uint32 startTime_,
        uint32 endTime_,
        SaleType saleType_
    ) public {
        require(_isOwnerAndApproved(tokenId_), "Access denied");

        require(!saleData[tokenId_].forSale, "Active sale");

        require(startTime_ >= block.timestamp && endTime_ > startTime_, "Invalid time");

        require(endPrice_ != 0, "Zero price");

        require(isWhitelisted[token_], "Invalid token");
        
        // Validate input prices
        if(saleType_ == SaleType.DUTCH) {
            require(startPrice_ > endPrice_, "Invalid price");
        } else {
            require(startPrice_ == endPrice_, "Invalid price");
        }

        // Record sale data
        saleData[tokenId_] = Sale(startPrice_, endPrice_, token_, true, startTime_, endTime_, saleType_);

        // Emit an event
        emit Listed(msg.sender, tokenId_, startPrice_, endPrice_, token_, startTime_, endTime_, saleType_);
    }

    /**
     * @dev Ends ongoing sale for given memeNFT
     *
     * @param tokenId_ tokenId of memeNFT to revoke sale for
     */
    function revokesale(uint256 tokenId_) 
        public
    {
        require(msg.sender == IERC721(memeNFT).ownerOf(tokenId_), "Not an owner");

        require(saleData[tokenId_].forSale, "sale is not active");

        // Remove listing data for given tokenId
        delete saleData[tokenId_];

        // Clear Bidding information in case of English auction
        delete auctionBids[tokenId_];
        
        // Emit an event
        emit Delisted(msg.sender, tokenId_);
    }

    /**
     * @dev Allows to revoke ongoing sale and list memeNFT for new sale
     * 
     * @param tokenId_ tokenId of memeNFT to revoke and list
     * @param startPrice_ sale price(Fix), start price (Dutch) and base price (English)
     * @param endPrice_ sale price(Fix), end price (Dutch) and base price (English)
     * @param token_ sale token address
     * @param startTime_ unix timestamp, sale starts
     * @param endTime_ unix timestamp, sale ends
     * @param saleType_ listing type
     */
    function revokeAndList(
        uint256 tokenId_,
        uint256 startPrice_,
        uint256 endPrice_,
        address token_,
        uint32 startTime_,
        uint32 endTime_,
        SaleType saleType_
    ) external {
        // Revoke ongoing sale
        revokesale(tokenId_);
        
        // List given memeNFT for new sale
        list(tokenId_, startPrice_, endPrice_, token_, startTime_, endTime_, saleType_);
    }

    /**
     * @dev Edit sale price of given memeNFT listed for fix price sale
     *
     * @param tokenId_ tokenId of memeNFT
     * @param newPrice_ new price to be set for sale
     */
    function editPrice(uint256 tokenId_, uint256 newPrice_) external {
        require(_isOwnerAndApproved(tokenId_), "Access denied");

        require(
            _isActive(tokenId_) && saleData[tokenId_].saleType == SaleType.FIX,
            "Fix price sale is not active"
        );
        
        // Get old price
        uint256 _oldPrice = saleData[tokenId_].startPrice;
        
        // Record new price
        saleData[tokenId_].startPrice = newPrice_;
        saleData[tokenId_].endPrice = newPrice_;

        // Emit an event
        emit Relisted(msg.sender, tokenId_, _oldPrice, newPrice_);
    }    

    /**
     * @dev Allows to buy given memeNFT listed for fix or dutch auction sale
     * 
     * @notice On success, memeNFT is transfered to buyer and seller gets the defined amount in sale token
     *
     * @param tokenId_ tokenId of memeNFT to buy
     * @param fee_ sale token amount to be paid as marketplace fee
     * @param validAfter_ signature valid after time (unix timestamp)
	 * @param validBefore_ signature valid before time (unix timestamp)
	 * @param nonce_ unique random nonce
	 * @param v the recovery byte of the signature
	 * @param r half of the ECDSA signature pair
	 * @param s half of the ECDSA signature pair
     */
    function buy(
        uint256 tokenId_,
        uint256 fee_,
		uint256 validAfter_,
		uint256 validBefore_,
		bytes32 nonce_,
		uint8 v,
		bytes32 r,
		bytes32 s
    ) external {
        require(
            _isActive(tokenId_) && saleData[tokenId_].saleType != SaleType.ENGLISH,
            "Sale is not active"
        );

        // Get address of seller
        address _seller = IERC721(memeNFT).ownerOf(tokenId_);

        // Get sale price of given NFT
        uint256 _price = getCurrentPrice(tokenId_);

        // Derive signer of the EIP712 BUY message
		address signer = __deriveSigner(
			abi.encode(BUY_TYPEHASH, tokenId_, fee_, validAfter_, validBefore_, nonce_),
			v,
			r,
			s
		);

        // Validate access permissions and message integrity
        __validate(signer, validAfter_, validBefore_, nonce_);

        // Chekout given tokenId
        __checkout(tokenId_, _price, fee_, msg.sender, _seller);
    }

    /** 
     * @dev Registers a bid
     *
     * @param tokenId_ tokenId of auctioned memeNFT 
     * @param bidPrice_ bid amount in sale token  
     */
    function bidOnAuction(
        uint256 tokenId_,
        uint256 bidPrice_
    ) external {
        require(
            _isActive(tokenId_) && saleData[tokenId_].saleType == SaleType.ENGLISH,
            "Auction is not active"
        );

        // Get last bid amount
        uint256 _lastBid = (getBidCount(tokenId_) == 0) ?
                            saleData[tokenId_].startPrice - 1 :
                            auctionBids[tokenId_][getBidCount(tokenId_) - 1].amount;

        require(
            bidPrice_ > _lastBid &&
            IERC20(saleData[tokenId_].token).allowance(msg.sender, address(this)) >= bidPrice_,
            "Bid price is less than last bid price / base price"
        );

        // Wrap bid information
        Bid memory newBid = Bid(msg.sender, bidPrice_);

        // Record bid information
        auctionBids[tokenId_].push(newBid);
        
        // Emit an event
        emit BidUpdate(msg.sender, tokenId_, bidPrice_);
    }

    /**
     * @dev Accepts bid for given memeNFT 
     *
     * @notice On success, memeNFT is transfered to bidder and seller gets the defined amount in sale token
     * 
     * @param tokenId_ tokenId of auctioned memeNFT to accept bid for
     * @param bidIndex_ bid index to accept for finalize auction
     * @param fee_ sale token amount to be paid as marketplace fee
     * @param validAfter_ signature valid after time (unix timestamp)
	 * @param validBefore_ signature valid before time (unix timestamp)
	 * @param nonce_ unique random nonce
	 * @param v the recovery byte of the signature
	 * @param r half of the ECDSA signature pair
	 * @param s half of the ECDSA signature pair
     */
    function acceptBid(
        uint256 tokenId_,
        uint256 bidIndex_,
        uint256 fee_,
		uint256 validAfter_,
		uint256 validBefore_,
		bytes32 nonce_,
		uint8 v,
		bytes32 r,
		bytes32 s
    ) external {
        require(
            saleData[tokenId_].forSale && saleData[tokenId_].saleType == SaleType.ENGLISH,
            "Not listed for english auction"
        );

        require(msg.sender == IERC721(memeNFT).ownerOf(tokenId_), "Not an owner");

        // Get address of bidder
        address _bidder = auctionBids[tokenId_][bidIndex_].from;

        // Get bid amount of given index
        uint256 _price = auctionBids[tokenId_][bidIndex_].amount;

        // Derive signer of the EIP712 AcceptBid message
		address signer = __deriveSigner(
			abi.encode(ACCEPT_BID_TYPEHASH, tokenId_, bidIndex_, fee_, validAfter_, validBefore_, nonce_),
			v,
			r,
			s
		);

        // Validate access permissions and message integrity
        __validate(signer, validAfter_, validBefore_, nonce_);

        // Chekout given tokenId
        __checkout(tokenId_, _price, fee_, _bidder, msg.sender);

        // Clear Bidding information for given memeNFT
        delete auctionBids[tokenId_];
    }

    /**
	 * @notice Cancels the authorization (using EIP-712 signature)
	 *
	 * @param authorizer_ transaction authorizer
	 * @param nonce_ unique random nonce to cancel (mark as used)
	 * @param v the recovery byte of the signature
	 * @param r half of the ECDSA signature pair
	 * @param s half of the ECDSA signature pair
	 */
	function cancelAuthorization(
		address authorizer_,
		bytes32 nonce_,
		uint8 v,
		bytes32 r,
		bytes32 s
	) external {
		// derive signer of the EIP712 CancelAuthorization message
		address signer = __deriveSigner(abi.encode(CANCEL_AUTHORIZATION_TYPEHASH, authorizer_, nonce_), v, r, s);

		// perform message integrity and security validations
		require(signer == authorizer_, "invalid signature");

		// cancel the nonce supplied (verify, mark as used, emit event)
		__useNonce(authorizer_, nonce_, true);
	}

	/**
	 * @notice Cancels the authorization
	 *
	 * @param _nonce unique random nonce to cancel (mark as used)
	 */
	function cancelAuthorization(bytes32 _nonce) external {
		// cancel the nonce supplied (verify, mark as used, emit event)
		__useNonce(msg.sender, _nonce, true);
	}

    // ===== End: MemeCrafter NFT Marketplace (mutative functions) =====

    // ===== Start: MemeCrafter NFT Marketplace (private functions) =====

    /**
     * @dev Auxiliary internally used function to validate signature
     * 
     * @param signer_ address of EIP 712 message signer
     * @param validAfter_ signature valid after time (unix timestamp)
     * @param validBefore_ signature valid before time (unix timestamp)
     * @param nonce_ unique random nonce
     */
    function __validate(
        address signer_,
        uint256 validAfter_,
        uint256 validBefore_,
        bytes32 nonce_
    ) private {
        // Verify the access permission
		require(isOperatorInRole(signer_, ROLE_FEE_MANAGER), "Access denied");

		// Perform message integrity and security validations
		require(block.timestamp > validAfter_, "Signature not yet valid");
		require(block.timestamp < validBefore_, "Signature expired");

		// Use the nonce supplied (verify, mark as used, emit event)
		__useNonce(signer_, nonce_, false);
    }

    /**
     * @dev Auxiliary internally used function to checkout memeNFT
     * 
     * @param tokenId_ tokenId of memeNFT to checkout
     * @param price_ price to be paid in sale token
     * @param fee_  fee to be paid in sale token
     * @param buyer_ address of buyer
     * @param seller_ address of seller
     */
    function __checkout(
        uint256 tokenId_,
        uint256 price_,
        uint256 fee_,
        address buyer_,
        address seller_
    ) private {
        // Get royalty info from memeNFT smart contract
        (address _creator, uint256 _royaltyFee) = IERC2981(memeNFT).royaltyInfo(tokenId_, price_);

        // Transfer sale amount after deducting royalty amount to the seller     
        IERC20(saleData[tokenId_].token).transferFrom(
            buyer_,
            seller_,
            price_ - _royaltyFee
        );

        // Transfer marketplace fee to treasury
        IERC20(saleData[tokenId_].token).transferFrom(buyer_, treasury, fee_);
        
        // Transfer royalty to creator of memeNFT
        IERC20(saleData[tokenId_].token).transferFrom(buyer_, _creator, _royaltyFee);

        // Emit an event
        emit Bought(buyer_, seller_, tokenId_, price_, fee_, saleData[tokenId_].token, saleData[tokenId_].saleType);

        // Remove listing information for given memeNFT
        delete saleData[tokenId_]; 

        // Transfer memeNFT to buyer
        IERC721(memeNFT).transferFrom(seller_, buyer_, tokenId_);
    }

    /**
     * @dev Returns sale status of given memeNFT
     * 
     * @param tokenId_ tokenId of memeNFT to check status for
     */
    function _isActive(uint256 tokenId_) private view returns(bool) {
        return saleData[tokenId_].forSale &&
                block.timestamp >= saleData[tokenId_].startTime &&
                block.timestamp <= saleData[tokenId_].endTime; 
    }

    /**
     * @dev Returns authorization status for given memeNFT
     * 
     * @param tokenId_ tokenId of memeNFT to check status for
     */
    function _isOwnerAndApproved(uint256 tokenId_) private view returns(bool) {
        return (msg.sender == IERC721(memeNFT).ownerOf(tokenId_) &&
            (address(this) == IERC721(memeNFT).getApproved(tokenId_)));
    }

	/**
	 * @dev Auxiliary function to verify structured EIP712 message signature and derive its signer
	 *
	 * @param abiEncodedTypehash abi.encode of the message typehash together with all its parameters
	 * @param v the recovery byte of the signature
	 * @param r half of the ECDSA signature pair
	 * @param s half of the ECDSA signature pair
	 */
	function __deriveSigner(bytes memory abiEncodedTypehash, uint8 v, bytes32 r, bytes32 s) private view returns(address) {
		// build the EIP-712 hashStruct of the message
		bytes32 hashStruct = keccak256(abiEncodedTypehash);

		// calculate the EIP-712 digest "\x19\x01" ΓÇû domainSeparator ΓÇû hashStruct(message)
		bytes32 digest = keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, hashStruct));

		// recover the address which signed the message with v, r, s
		address signer = ECDSA.recover(digest, v, r, s);

		// return the signer address derived from the signature
		return signer;
	}

	/**
	 * @dev Auxiliary function to use/cancel the nonce supplied for a given authorizer:
	 *      1. Verifies the nonce was not used before
	 *      2. Marks the nonce as used
	 *      3. Emits an event that the nonce was used/cancelled
	 *
	 * @dev Set `_cancellation` to false (default) to use nonce,
	 *      set `_cancellation` to true to cancel nonce
	 *
	 * @dev It is expected that the nonce supplied is a randomly
	 *      generated uint256 generated by the client
	 *
	 * @param authorizer_ an address to use/cancel nonce for
	 * @param nonce_ random nonce to use
	 * @param cancellation_ true to emit `AuthorizationCancelled`, false to emit `AuthorizationUsed` event
	 */
	function __useNonce(address authorizer_, bytes32 nonce_, bool cancellation_) private {
		// verify nonce was not used before
		require(!usedNonces[authorizer_][nonce_], "invalid nonce");

		// update the nonce state to "used" for that particular signer to avoid replay attack
		usedNonces[authorizer_][nonce_] = true;

		// depending on the usage type (use/cancel)
		if(cancellation_) {
			// emit an event regarding the nonce cancelled
			emit AuthorizationCanceled(authorizer_, nonce_);
		}
		else {
			// emit an event regarding the nonce used
			emit AuthorizationUsed(authorizer_, nonce_);
		}
	}

    // ===== End: MemeCrafter NFT Marketplace (private functions) =====
}