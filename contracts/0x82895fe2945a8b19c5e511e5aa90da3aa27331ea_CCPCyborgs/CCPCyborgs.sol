/**
 *Submitted for verification at Etherscan.io on 2023-09-13
*/

// SPDX-License-Identifier: MIT
// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/cryptography/MerkleProof.sol


// OpenZeppelin Contracts (last updated v4.9.2) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.20;

/**
 * @dev These functions deal with verification of Merkle Tree proofs.
 *
 * The tree and the proofs can be generated using our
 * https://github.com/OpenZeppelin/merkle-tree[JavaScript library].
 * You will find a quickstart guide in the readme.
 *
 * WARNING: You should avoid using leaf values that are 64 bytes long prior to
 * hashing, or use a hash function other than keccak256 for hashing leaves.
 * This is because the concatenation of a sorted pair of internal nodes in
 * the merkle tree could be reinterpreted as a leaf value.
 * OpenZeppelin's JavaScript library generates merkle trees that are safe
 * against this attack out of the box.
 */
library MerkleProof {
    /**
     *@dev The multiproof provided is not valid.
     */
    error MerkleProofInvalidMultiproof();

    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(bytes32[] memory proof, bytes32 root, bytes32 leaf) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Calldata version of {verify}
     */
    function verifyCalldata(bytes32[] calldata proof, bytes32 root, bytes32 leaf) internal pure returns (bool) {
        return processProofCalldata(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merkle tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Calldata version of {processProof}
     */
    function processProofCalldata(bytes32[] calldata proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Returns true if the `leaves` can be simultaneously proven to be a part of a merkle tree defined by
     * `root`, according to `proof` and `proofFlags` as described in {processMultiProof}.
     *
     * CAUTION: Not all merkle trees admit multiproofs. See {processMultiProof} for details.
     */
    function multiProofVerify(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProof(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev Calldata version of {multiProofVerify}
     *
     * CAUTION: Not all merkle trees admit multiproofs. See {processMultiProof} for details.
     */
    function multiProofVerifyCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProofCalldata(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev Returns the root of a tree reconstructed from `leaves` and sibling nodes in `proof`. The reconstruction
     * proceeds by incrementally reconstructing all inner nodes by combining a leaf/inner node with either another
     * leaf/inner node or a proof sibling node, depending on whether each `proofFlags` item is true or false
     * respectively.
     *
     * CAUTION: Not all merkle trees admit multiproofs. To use multiproofs, it is sufficient to ensure that: 1) the tree
     * is complete (but not necessarily perfect), 2) the leaves to be proven are in the opposite order they are in the
     * tree (i.e., as seen from right to left starting at the deepest layer and continuing at the next layer).
     */
    function processMultiProof(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuilds the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 proofLen = proof.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        if (leavesLen + proofLen - 1 != totalHashes) {
            revert MerkleProofInvalidMultiproof();
        }

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value from the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i]
                ? (leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++])
                : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            if (proofPos != proofLen) {
                revert MerkleProofInvalidMultiproof();
            }
            unchecked {
                return hashes[totalHashes - 1];
            }
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    /**
     * @dev Calldata version of {processMultiProof}.
     *
     * CAUTION: Not all merkle trees admit multiproofs. See {processMultiProof} for details.
     */
    function processMultiProofCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuilds the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 proofLen = proof.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        if (leavesLen + proofLen - 1 != totalHashes) {
            revert MerkleProofInvalidMultiproof();
        }

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value from the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i]
                ? (leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++])
                : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            if (proofPos != proofLen) {
                revert MerkleProofInvalidMultiproof();
            }
            unchecked {
                return hashes[totalHashes - 1];
            }
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    function _hashPair(bytes32 a, bytes32 b) private pure returns (bytes32) {
        return a < b ? _efficientHash(a, b) : _efficientHash(b, a);
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/math/SignedMath.sol


// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/SignedMath.sol)

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

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/interfaces/draft-IERC6093.sol


pragma solidity ^0.8.20;

/**
 * @dev Standard ERC20 Errors
 * Interface of the https://eips.ethereum.org/EIPS/eip-6093[ERC-6093] custom errors for ERC20 tokens.
 */
interface IERC20Errors {
    /**
     * @dev Indicates an error related to the current `balance` of a `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     * @param balance Current balance for the interacting account.
     * @param needed Minimum amount required to perform a transfer.
     */
    error ERC20InsufficientBalance(address sender, uint256 balance, uint256 needed);

    /**
     * @dev Indicates a failure with the token `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     */
    error ERC20InvalidSender(address sender);

    /**
     * @dev Indicates a failure with the token `receiver`. Used in transfers.
     * @param receiver Address to which tokens are being transferred.
     */
    error ERC20InvalidReceiver(address receiver);

    /**
     * @dev Indicates a failure with the `spender`’s `allowance`. Used in transfers.
     * @param spender Address that may be allowed to operate on tokens without being their owner.
     * @param allowance Amount of tokens a `spender` is allowed to operate with.
     * @param needed Minimum amount required to perform a transfer.
     */
    error ERC20InsufficientAllowance(address spender, uint256 allowance, uint256 needed);

    /**
     * @dev Indicates a failure with the `approver` of a token to be approved. Used in approvals.
     * @param approver Address initiating an approval operation.
     */
    error ERC20InvalidApprover(address approver);

    /**
     * @dev Indicates a failure with the `spender` to be approved. Used in approvals.
     * @param spender Address that may be allowed to operate on tokens without being their owner.
     */
    error ERC20InvalidSpender(address spender);
}

/**
 * @dev Standard ERC721 Errors
 * Interface of the https://eips.ethereum.org/EIPS/eip-6093[ERC-6093] custom errors for ERC721 tokens.
 */
interface IERC721Errors {
    /**
     * @dev Indicates that an address can't be an owner. For example, `address(0)` is a forbidden owner in EIP-20.
     * Used in balance queries.
     * @param owner Address of the current owner of a token.
     */
    error ERC721InvalidOwner(address owner);

    /**
     * @dev Indicates a `tokenId` whose `owner` is the zero address.
     * @param tokenId Identifier number of a token.
     */
    error ERC721NonexistentToken(uint256 tokenId);

    /**
     * @dev Indicates an error related to the ownership over a particular token. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     * @param tokenId Identifier number of a token.
     * @param owner Address of the current owner of a token.
     */
    error ERC721IncorrectOwner(address sender, uint256 tokenId, address owner);

    /**
     * @dev Indicates a failure with the token `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     */
    error ERC721InvalidSender(address sender);

    /**
     * @dev Indicates a failure with the token `receiver`. Used in transfers.
     * @param receiver Address to which tokens are being transferred.
     */
    error ERC721InvalidReceiver(address receiver);

    /**
     * @dev Indicates a failure with the `operator`’s approval. Used in transfers.
     * @param operator Address that may be allowed to operate on tokens without being their owner.
     * @param tokenId Identifier number of a token.
     */
    error ERC721InsufficientApproval(address operator, uint256 tokenId);

    /**
     * @dev Indicates a failure with the `approver` of a token to be approved. Used in approvals.
     * @param approver Address initiating an approval operation.
     */
    error ERC721InvalidApprover(address approver);

    /**
     * @dev Indicates a failure with the `operator` to be approved. Used in approvals.
     * @param operator Address that may be allowed to operate on tokens without being their owner.
     */
    error ERC721InvalidOperator(address operator);
}

/**
 * @dev Standard ERC1155 Errors
 * Interface of the https://eips.ethereum.org/EIPS/eip-6093[ERC-6093] custom errors for ERC1155 tokens.
 */
interface IERC1155Errors {
    /**
     * @dev Indicates an error related to the current `balance` of a `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     * @param balance Current balance for the interacting account.
     * @param needed Minimum amount required to perform a transfer.
     * @param tokenId Identifier number of a token.
     */
    error ERC1155InsufficientBalance(address sender, uint256 balance, uint256 needed, uint256 tokenId);

    /**
     * @dev Indicates a failure with the token `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     */
    error ERC1155InvalidSender(address sender);

    /**
     * @dev Indicates a failure with the token `receiver`. Used in transfers.
     * @param receiver Address to which tokens are being transferred.
     */
    error ERC1155InvalidReceiver(address receiver);

    /**
     * @dev Indicates a failure with the `operator`’s approval. Used in transfers.
     * @param operator Address that may be allowed to operate on tokens without being their owner.
     * @param owner Address of the current owner of a token.
     */
    error ERC1155MissingApprovalForAll(address operator, address owner);

    /**
     * @dev Indicates a failure with the `approver` of a token to be approved. Used in approvals.
     * @param approver Address initiating an approval operation.
     */
    error ERC1155InvalidApprover(address approver);

    /**
     * @dev Indicates a failure with the `operator` to be approved. Used in approvals.
     * @param operator Address that may be allowed to operate on tokens without being their owner.
     */
    error ERC1155InvalidOperator(address operator);

    /**
     * @dev Indicates an array length mismatch between ids and values in a safeBatchTransferFrom operation.
     * Used in batch transfers.
     * @param idsLength Length of the array of token identifiers
     * @param valuesLength Length of the array of token amounts
     */
    error ERC1155InvalidArrayLength(uint256 idsLength, uint256 valuesLength);
}

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/math/Math.sol


// OpenZeppelin Contracts (last updated v4.9.0) (utils/math/Math.sol)

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
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
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

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

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

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Strings.sol


// OpenZeppelin Contracts (last updated v4.9.0) (utils/Strings.sol)

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
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
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

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/StorageSlot.sol


// OpenZeppelin Contracts (last updated v4.9.0) (utils/StorageSlot.sol)
// This file was procedurally generated from scripts/generate/templates/StorageSlot.js.

pragma solidity ^0.8.20;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```solidity
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(newImplementation.code.length > 0);
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 */
library StorageSlot {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    struct StringSlot {
        string value;
    }

    struct BytesSlot {
        bytes value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `StringSlot` with member `value` located at `slot`.
     */
    function getStringSlot(bytes32 slot) internal pure returns (StringSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `StringSlot` representation of the string storage pointer `store`.
     */
    function getStringSlot(string storage store) internal pure returns (StringSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := store.slot
        }
    }

    /**
     * @dev Returns an `BytesSlot` with member `value` located at `slot`.
     */
    function getBytesSlot(bytes32 slot) internal pure returns (BytesSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BytesSlot` representation of the bytes storage pointer `store`.
     */
    function getBytesSlot(bytes storage store) internal pure returns (BytesSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := store.slot
        }
    }
}

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Arrays.sol


// OpenZeppelin Contracts (last updated v4.9.0) (utils/Arrays.sol)

pragma solidity ^0.8.20;



/**
 * @dev Collection of functions related to array types.
 */
library Arrays {
    using StorageSlot for bytes32;

    /**
     * @dev Searches a sorted `array` and returns the first index that contains
     * a value greater or equal to `element`. If no such index exists (i.e. all
     * values in the array are strictly less than `element`), the array length is
     * returned. Time complexity O(log n).
     *
     * `array` is expected to be sorted in ascending order, and to contain no
     * repeated elements.
     */
    function findUpperBound(uint256[] storage array, uint256 element) internal view returns (uint256) {
        uint256 low = 0;
        uint256 high = array.length;

        if (high == 0) {
            return 0;
        }

        while (low < high) {
            uint256 mid = Math.average(low, high);

            // Note that mid will always be strictly less than high (i.e. it will be a valid array index)
            // because Math.average rounds towards zero (it does integer division with truncation).
            if (unsafeAccess(array, mid).value > element) {
                high = mid;
            } else {
                low = mid + 1;
            }
        }

        // At this point `low` is the exclusive upper bound. We will return the inclusive upper bound.
        if (low > 0 && unsafeAccess(array, low - 1).value == element) {
            return low - 1;
        } else {
            return low;
        }
    }

    /**
     * @dev Access an array in an "unsafe" way. Skips solidity "index-out-of-range" check.
     *
     * WARNING: Only use if you are certain `pos` is lower than the array length.
     */
    function unsafeAccess(address[] storage arr, uint256 pos) internal pure returns (StorageSlot.AddressSlot storage) {
        bytes32 slot;
        // We use assembly to calculate the storage slot of the element at index `pos` of the dynamic array `arr`
        // following https://docs.soliditylang.org/en/v0.8.20/internals/layout_in_storage.html#mappings-and-dynamic-arrays.

        /// @solidity memory-safe-assembly
        assembly {
            mstore(0, arr.slot)
            slot := add(keccak256(0, 0x20), pos)
        }
        return slot.getAddressSlot();
    }

    /**
     * @dev Access an array in an "unsafe" way. Skips solidity "index-out-of-range" check.
     *
     * WARNING: Only use if you are certain `pos` is lower than the array length.
     */
    function unsafeAccess(bytes32[] storage arr, uint256 pos) internal pure returns (StorageSlot.Bytes32Slot storage) {
        bytes32 slot;
        // We use assembly to calculate the storage slot of the element at index `pos` of the dynamic array `arr`
        // following https://docs.soliditylang.org/en/v0.8.20/internals/layout_in_storage.html#mappings-and-dynamic-arrays.

        /// @solidity memory-safe-assembly
        assembly {
            mstore(0, arr.slot)
            slot := add(keccak256(0, 0x20), pos)
        }
        return slot.getBytes32Slot();
    }

    /**
     * @dev Access an array in an "unsafe" way. Skips solidity "index-out-of-range" check.
     *
     * WARNING: Only use if you are certain `pos` is lower than the array length.
     */
    function unsafeAccess(uint256[] storage arr, uint256 pos) internal pure returns (StorageSlot.Uint256Slot storage) {
        bytes32 slot;
        // We use assembly to calculate the storage slot of the element at index `pos` of the dynamic array `arr`
        // following https://docs.soliditylang.org/en/v0.8.20/internals/layout_in_storage.html#mappings-and-dynamic-arrays.

        /// @solidity memory-safe-assembly
        assembly {
            mstore(0, arr.slot)
            slot := add(keccak256(0, 0x20), pos)
        }
        return slot.getUint256Slot();
    }

    /**
     * @dev Access an array in an "unsafe" way. Skips solidity "index-out-of-range" check.
     *
     * WARNING: Only use if you are certain `pos` is lower than the array length.
     */
    function unsafeMemoryAccess(uint256[] memory arr, uint256 pos) internal pure returns (uint256 res) {
        assembly {
            res := mload(add(add(arr, 0x20), mul(pos, 0x20)))
        }
    }

    /**
     * @dev Access an array in an "unsafe" way. Skips solidity "index-out-of-range" check.
     *
     * WARNING: Only use if you are certain `pos` is lower than the array length.
     */
    function unsafeMemoryAccess(address[] memory arr, uint256 pos) internal pure returns (address res) {
        assembly {
            res := mload(add(add(arr, 0x20), mul(pos, 0x20)))
        }
    }
}

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Context.sol


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.20;

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

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

pragma solidity ^0.8.20;


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * The initial owner is set to the address provided by the deployer. This can
 * later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    /**
     * @dev The caller account is not authorized to perform an operation.
     */
    error OwnableUnauthorizedAccount(address account);

    /**
     * @dev The owner is not a valid owner account. (eg. `address(0)`)
     */
    error OwnableInvalidOwner(address owner);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the address provided by the deployer as the initial owner.
     */
    constructor(address initialOwner) {
        if (initialOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(initialOwner);
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        if (owner() != _msgSender()) {
            revert OwnableUnauthorizedAccount(_msgSender());
        }
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        if (newOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: contracts/Admins.sol


pragma solidity ^0.8.20;



/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) and a project leader that can grant exclusive access to
 * specific functions.
 */
abstract contract Admins is Ownable {
    address public projectLeader;
    address[] public admins;

    /**
     * @dev The caller account is not authorized to perform an operation.
     */
    error AdminsUnauthorizedAccount(address account);

    event ProjectLeaderTransferred(address indexed previousLead, address indexed newLead);

    /**
     * @dev Initializes the contract setting the address provided by the deployer as the initial owner.
     */
    constructor(address initialOwner) Ownable(initialOwner) {
        projectLeader = initialOwner;
    }

     /**
    @dev Throws if called by any account other than the owner or admin.
    */
    modifier onlyAdmins() {
        _checkAdmins();
        _;
    }

    /**
    @dev Internal function to check if the sender is an admin.
    */
    function _checkAdmins() internal view virtual {
        if (!checkIfAdmin()) {
            revert AdminsUnauthorizedAccount(_msgSender());
        }
    }

    /**
    @dev Checks if the sender is an admin.
    @return bool indicating whether the sender is an admin or not.
    */
    function checkIfAdmin() public view virtual returns(bool) {
        if (_msgSender() == owner() || _msgSender() == projectLeader){
            return true;
        }
        if(admins.length > 0){
            for (uint256 i = 0; i < admins.length; i++) {
                if(_msgSender() == admins[i]){
                    return true;
                }
            }
        }
        // Not an Admin
        return false;
    }

    /**
    @dev Owner and Project Leader can set the addresses as approved Admins.
    Example: ["0xADDRESS1", "0xADDRESS2", "0xADDRESS3"]
    */
    function setAdmins(address[] calldata _users) public virtual onlyAdmins {
        if (_msgSender() != owner() || _msgSender() != projectLeader) {
            revert AdminsUnauthorizedAccount(_msgSender());
        }
        delete admins;
        admins = _users;
    }

    /**
    @dev Owner or Project Leader can set the address as new Project Leader.
    */
    function setProjectLeader(address _user) public virtual onlyAdmins {
        if (_msgSender() != owner() || _msgSender() != projectLeader) {
            revert AdminsUnauthorizedAccount(_msgSender());
        }
        address oldPL = projectLeader;
        projectLeader = _user;
        emit ProjectLeaderTransferred(oldPL, _user);
    }
}

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/introspection/IERC165.sol


// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.20;

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

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/IERC721.sol


// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.20;


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
     * - The `operator` cannot be the address zero.
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

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/introspection/ERC165.sol


// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.20;


/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC1155/IERC1155Receiver.sol


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.20;


/**
 * @dev Interface that must be implemented by smart contracts in order to receive
 * ERC-1155 token transfers.
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC1155/IERC1155.sol


// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.20;


/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` amount of tokens of type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the value of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(
        address[] calldata accounts,
        uint256[] calldata ids
    ) external view returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers a `value` amount of tokens of type `id` from `from` to `to`.
     *
     * WARNING: This function can potentially allow a reentrancy attack when transferring tokens
     * to an untrusted contract, when invoking {onERC1155Received} on the receiver.
     * Ensure to follow the checks-effects-interactions pattern and consider employing
     * reentrancy guards when interacting with untrusted contracts.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `value` amount.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(address from, address to, uint256 id, uint256 value, bytes calldata data) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     *
     * WARNING: This function can potentially allow a reentrancy attack when transferring tokens
     * to an untrusted contract, when invoking {onERC1155BatchReceived} on the receiver.
     * Ensure to follow the checks-effects-interactions pattern and consider employing
     * reentrancy guards when interacting with untrusted contracts.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `values` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external;
}

// File: contracts/EasyLibrary.sol


pragma solidity ^0.8.20;





library EasyLibrary {
    error SkewedArrays();

    /**
    Batch contains a set amount of token IDs and details for minting and metadata uri structure.
    */
    struct Batch {
        uint[3] bRangeNext; //0 = start, 1 = end, 2 = nextToken to try mint
        string[2] bURI; //metadata uri 0 = prefix, 1 = suffix
        
        bool bRevealed; //revealed state
        bool bPaused; //pause state
        bool bBindOnMint; //bind on mint state, true = tokens cannot be moved after mint
        bool bMintInOrder; //state if tokens will be minted in numeric order

        bool bRollSwapAllow; //state if tokens can have it's roll swapped
        bool bRollInUse; //state if tokens will have a random roll when minted
        uint[2] bRollRange; //excluded Min & included Max of random roll
        uint bRollCost; //price for swapping roll
        
        uint bCost; //cost to mint each token
        uint bLimit; //max amount a wallet can mint, 0 = no limit
        uint bSupply; //supply of each token within the batch, 0 = no limit

        uint bTriggerPoint; //point to trigger next cost
        uint bNextCost; //cost is set to this after trigger point is met
        uint bMintStartDate; //date in unix timestamp to open mint
        
        uint[] bRequirementTokens; //tokens required to be held for minting
        uint[] bRequirementAmounts; //amount required for each token required
        address[] bRequirementAddresses; //address for the requirements
        bool[] bRequirementContractType; //true = ERC1155 , false = ERC721
    }

    /**
    Tier is a whitelist but active during public mint.
    - tLimit is the limited amount that tier is allowed
        a minter is then moved into the next tier when the limit is met
    - tCost is the cost for that tier
    - tRoot is the Merkle Root of the tier list
    */
    struct Tier {
        uint256 tLimit;
        uint256 tCost;
        bytes32 tRoot;
    }

    /**
    @dev Returns a random number between excluded rollLimitMin and included rollLimitMax for a given batch _fromBatch.
    @return A string representing the randomly selected roll within the specified range.
    */
    function randomRoll(uint256 seed, uint256 rollCounter, uint256 rollLimitMax, uint256 rollLimitMin) internal view returns (string memory) {
        uint256 random = uint256(keccak256(abi.encodePacked(
            seed,
            rollCounter,
            block.timestamp,
            msg.sender
        ))) % (rollLimitMax);

        if (random < rollLimitMin) {
            return Strings.toString(rollLimitMax - (random + 1));
        } else {
            return Strings.toString(random + 1);
        }
    }

    function validateRoll(uint256 _roll, bool rollSwapAllow, uint256 rollLimitMin, uint256 rollLimitMax, uint256 _balance, uint256 rollCost) internal view {
        require(rollSwapAllow, "!RR");
        require(_roll > rollLimitMin && _roll <= rollLimitMax, "!R");
        require(_balance > 0, "!O");
        require(msg.value >= (rollCost), "$?");
    }

    function validateTier(bytes32[] calldata proof, bytes32 leaf, Tier[] storage tiers) public view returns (bool, uint8) {
        if (tiers.length != 0) {
            for (uint8 i = 0; i < tiers.length; i++) {
                if (MerkleProof.verify(proof, tiers[i].tRoot, leaf)) {
                    return (true, i);
                }
            }
        }
        
        return (false, 0);
    }

    function hasSufficientTokens(address[] memory _tokenContract, address _account, uint256[] memory _tokens, uint256[] memory _amounts, bool[] memory _cType) internal view returns (bool) {
        if(_tokens.length != _amounts.length) {
            revert SkewedArrays();
        }
        
        for (uint256 i = 0; i < _tokens.length; i++) {
            if(_cType[i]) {
                IERC1155 tokenContract = IERC1155(_tokenContract[i]);
                uint256 _userTokenBalance = tokenContract.balanceOf(_account, _tokens[i]);
                if (_userTokenBalance < _amounts[i]) {
                    return false;
                }
            } else {
                IERC721 tokenContract = IERC721(_tokenContract[i]);
                address _tokenOwner = tokenContract.ownerOf(_tokens[i]);
                if (msg.sender != _tokenOwner) {
                    return false;
                }
            }
        }
        
        return true;
    }
}
// File: contracts/EasyInit.sol


pragma solidity ^0.8.20;



abstract contract EasyInit is Admins {
    string public name;
    string public symbol;
    uint256 public collectionEndID;

    constructor(address _newOwner) Admins(_newOwner){}

    /**
    @dev Returns the total number of tokens within the collection.
    */
    function totalSupply() public view virtual returns(uint256) {
        return collectionEndID;
    }

    /**
    @dev Allows admin to update the collectionEndID which is used to determine the end of the initial collection of NFTs.
    @param _newcollectionEndID The new collectionEndID to set.
    */
    function updateCollectionEndID(uint _newcollectionEndID) external virtual onlyAdmins {
        collectionEndID = _newcollectionEndID;
    }
}

// File: contracts/EasyBatcher.sol


pragma solidity ^0.8.20;



abstract contract EasyBatcher is EasyInit {
    using EasyLibrary for *;
    EasyLibrary.Batch[] public batchData;

    error DateAlreadyPast();
    error BatchOutOfRange();
    error MinMaxFlipped();

    constructor(){}

    function batchExists(uint _batchID) internal virtual {
        if (_batchID >= batchData.length) {
            revert BatchOutOfRange();
        }
    }

    /**
    @notice Creates a new batch of tokens with the specified parameters and adds it to the batch data.
    @param _newBatch The Batch struct containing the configuration details for the new batch.
    @dev This function can only be called by administrators.
    */
    function createBatch(EasyLibrary.Batch calldata _newBatch) public virtual onlyAdmins {
        //create a batch and push it to EasyLibrary.Batch[] public batchData;
        batchData.push(_newBatch);
    }

    /**
    @dev Admin can set the state of an OPTION for a batch.
    @param _option The OPTION to set the state of:
    0 = Set the PAUSED state of a batch.
    1 = Set the REVEALED state.
    2 = Set the USING ROLLS state allowing Mints to pick a roll randomly within a set range.
    3 = Set the MINT IN ORDER state.     
    4 = Set the BIND on mint state. Note: Bound tokens cannot be moved once minted.
    //5 = Set the PRESALE state.
    6 = Set ROLL SWAP ALLOW state.
    @param _state The new state of the option:
    true = revealed, on
    false = hidden, off
    @param _fromBatch The batch ID to update the state for.
    */
    function setStateOf(uint _option, bool _state, uint _fromBatch) public virtual onlyAdmins {
        if(_option == 0){
            batchData[_fromBatch].bPaused = _state;
        } else if(_option == 1){
            batchData[_fromBatch].bRevealed = _state;
        } else if(_option == 2){
            batchData[_fromBatch].bRollInUse = _state;
        } else if(_option == 3){
            batchData[_fromBatch].bMintInOrder = _state;
        } else if(_option == 4){
            batchData[_fromBatch].bBindOnMint = _state;
        // } else if(_option == 5){
        //     presaleBatch[_fromBatch] = _state;
        } else if(_option == 6){
            batchData[_fromBatch].bRollSwapAllow = _state;
        }
    }

    /**
    @dev Allows an admin to set a start date for minting tokens for a specific batch.
    Tokens can only be minted after this date has passed.
    @param _batch The ID of the batch to set the mint date for.
    @param _unixDate The Unix timestamp for the start date of minting.
    @notice The Unix timestamp must be in the future, otherwise the function will revert.
    */
    function setMintDate(uint256 _batch, uint _unixDate) public virtual onlyAdmins {
        batchExists(_batch);
        if (_unixDate <= block.timestamp) {
            revert DateAlreadyPast();
        }
        batchData[_batch].bMintStartDate = _unixDate;
    }

    /**
    @dev Sets the batch range and ID of the next token to be minted.
    @param _bRangeNext uint array [start_ID, end_ID, nextIDToMint].
    @param _fromBatch uint batch ID of the batch to edit.
    Requirements:
    Only accessible by admins.
    */
    function setBatchRangeNext(uint[3] memory _bRangeNext, uint _fromBatch) external virtual onlyAdmins {
        batchData[_fromBatch].bRangeNext = _bRangeNext;
    }

    /**
    @dev Admin can set the new public or presale cost for a specific batch in WEI. The cost is denominated in wei,
    where 1 ETH = 10^18 WEI. To convert ETH to WEI and vice versa, use a tool such as https://etherscan.io/unitconverter.
    @param _isRollCost bool indicating if setting a roll or batch cost.
    @param _newCost uint256 indicating the new cost for the batch in WEI.
    @param _fromBatch uint indicating the ID of the batch to which the new cost applies.
    Note:
    This also sets the batchNextCost to the new cost so if a setCostNextOnTrigger was set it will need to be reset again.
    Requirements:
    Only accessible by admins.
    */
    function setCost(bool _isRollCost, uint256 _newCost, uint _fromBatch) public virtual onlyAdmins {
        if (!_isRollCost) {
            batchData[_fromBatch].bCost = _newCost;
            batchData[_fromBatch].bNextCost = _newCost;
        } else {
            batchData[_fromBatch].bRollCost = _newCost;
        }
    }

    /**
    @dev Sets the cost for the next mint after a specific token is minted in a batch.
    Only accessible by admins.
    */
    function setCostNextOnTrigger(uint256 _nextCost, uint _triggerPointID, uint _fromBatch) public virtual onlyAdmins {
        batchData[_fromBatch].bTriggerPoint = _triggerPointID;
        batchData[_fromBatch].bNextCost = _nextCost;
    }

    /**
    @dev Allows the contract admin to set the requirement tokens and their corresponding amounts for a specific batch ID.
    @param _batchID The ID of the batch for which the requirement tokens and amounts will be set.
    @param _requiredIDS An array of token IDs that are required to be owned in order to aquire tokens from a batch.
    @param _amounts An array of amounts indicating how many of each token ID in `_requiredIDS` are required.
    @param _tAddress is the token address for each ID specified in _requiredIDS.
    */
    function setRequirementTokens(uint _batchID, uint[] calldata _requiredIDS, uint[] calldata _amounts, address[] calldata _tAddress,  bool[] calldata _tContractType) external virtual onlyAdmins {
        batchExists(_batchID);
        batchData[_batchID].bRequirementTokens = _requiredIDS;
        batchData[_batchID].bRequirementAmounts = _amounts;
        batchData[_batchID].bRequirementAddresses = _tAddress;
        batchData[_batchID].bRequirementContractType = _tContractType;
    }

    /**
    @dev Sets the minimum and maximum values for the roll limit for a given batch _fromBatch.
    @param _min The minimum value of the roll limit (excluded).
    @param _max The maximum value of the roll limit (included).
    @param _fromBatch The ID of the batch to set the roll limit for.
    */
    function rollLimitSet(uint _min, uint _max, uint _fromBatch) external virtual onlyAdmins {
        if(_min > _max) {
            revert MinMaxFlipped();
        }
        batchData[_fromBatch].bRollRange = [_min, _max];
    }

    /**
    @dev Allows admin to set the supplies or mint limit for a batch.
    @param _isSupplies The flag is supplies or mint limit.
    @param _value The new value to set.
    @param _fromBatch The index of the batch to set the value for.
    */
    function setSuppliesOrLimit(bool _isSupplies, uint256 _value, uint256 _fromBatch) public virtual onlyAdmins {
        if(!_isSupplies) {
            batchData[_fromBatch].bLimit = _value;
        } else {
            batchData[_fromBatch].bSupply = _value;
        }
    }

    function getFixedArrayFromBatch(uint _option, uint _batchID) external view returns (string memory) {
        if (_option == 0) {
            return string(abi.encodePacked("[", Strings.toString(batchData[_batchID].bRangeNext[0]), ",", Strings.toString(batchData[_batchID].bRangeNext[1]), ",", Strings.toString(batchData[_batchID].bRangeNext[2]), "]"));
        }
        else if (_option == 1) {
            return string(abi.encodePacked("[", batchData[_batchID].bURI[0], ",", batchData[_batchID].bURI[1], "]"));
        } 
        else if (_option == 8) {
            return string(abi.encodePacked("[", Strings.toString(batchData[_batchID].bRollRange[0]), ",", Strings.toString(batchData[_batchID].bRollRange[1]), "]"));
        } 
        
        return "";
    }

    function getArrayFromBatch(uint _option, uint _batchID) external view returns (uint[] memory) {
        if (_option == 16) {
            return batchData[_batchID].bRequirementTokens;
        }
        else if (_option == 17) {
            return batchData[_batchID].bRequirementAmounts;
        }

        return new uint[](0);
    }

    function getAddressArrayFromBatch(uint _option, uint _batchID) external view returns (address[] memory) {
        if (_option == 18) {
            return batchData[_batchID].bRequirementAddresses;
        }

        return new address[](0);
    }

    function getBoolArrayFromBatch(uint _option, uint _batchID) external view returns (bool[] memory) {
        if (_option == 19) {
            return batchData[_batchID].bRequirementContractType;
        }

        return new bool[](0);
    }
}

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC1155/extensions/IERC1155MetadataURI.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/IERC1155MetadataURI.sol)

pragma solidity ^0.8.20;


/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 */
interface IERC1155MetadataURI is IERC1155 {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC1155/ERC1155.sol


// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC1155/ERC1155.sol)

pragma solidity ^0.8.20;








/**
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 */
abstract contract ERC1155 is Context, ERC165, IERC1155, IERC1155MetadataURI, IERC1155Errors {
    using Arrays for uint256[];
    using Arrays for address[];

    mapping(uint256 id => mapping(address account => uint256)) private _balances;

    mapping(address account => mapping(address operator => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

    /**
     * @dev See {_setURI}.
     */
    constructor(string memory uri_) {
        _setURI(uri_);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     * This implementation returns the same URI for *all* token types. It relies
     * on the token type ID substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * Clients calling this function must replace the `\{id\}` substring with the
     * actual token type ID.
     */
    function uri(uint256 /* id */) public view virtual returns (string memory) {
        return _uri;
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     */
    function balanceOf(address account, uint256 id) public view virtual returns (uint256) {
        return _balances[id][account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(
        address[] memory accounts,
        uint256[] memory ids
    ) public view virtual returns (uint256[] memory) {
        if (accounts.length != ids.length) {
            revert ERC1155InvalidArrayLength(ids.length, accounts.length);
        }

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts.unsafeMemoryAccess(i), ids.unsafeMemoryAccess(i));
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator) public view virtual returns (bool) {
        return _operatorApprovals[account][operator];
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 id, uint256 value, bytes memory data) public virtual {
        address sender = _msgSender();
        if (from != sender && !isApprovedForAll(from, sender)) {
            revert ERC1155MissingApprovalForAll(sender, from);
        }
        _safeTransferFrom(from, to, id, value, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory values,
        bytes memory data
    ) public virtual {
        address sender = _msgSender();
        if (from != sender && !isApprovedForAll(from, sender)) {
            revert ERC1155MissingApprovalForAll(sender, from);
        }
        _safeBatchTransferFrom(from, to, ids, values, data);
    }

    /**
     * @dev Transfers a `value` amount of tokens of type `id` from `from` to `to`. Will mint (or burn) if `from` (or `to`) is the zero address.
     *
     * Emits a {TransferSingle} event if the arrays contain one element, and {TransferBatch} otherwise.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement either {IERC1155Receiver-onERC1155Received}
     *   or {IERC1155Receiver-onERC1155BatchReceived} and return the acceptance magic value.
     * - `ids` and `values` must have the same length.
     *
     * NOTE: The ERC-1155 acceptance check is not performed in this function. See {_updateWithAcceptanceCheck} instead.
     */
    function _update(address from, address to, uint256[] memory ids, uint256[] memory values) internal virtual {
        if (ids.length != values.length) {
            revert ERC1155InvalidArrayLength(ids.length, values.length);
        }

        address operator = _msgSender();

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids.unsafeMemoryAccess(i);
            uint256 value = values.unsafeMemoryAccess(i);

            if (from != address(0)) {
                uint256 fromBalance = _balances[id][from];
                if (fromBalance < value) {
                    revert ERC1155InsufficientBalance(from, fromBalance, value, id);
                }
                unchecked {
                    // Overflow not possible: value <= fromBalance
                    _balances[id][from] = fromBalance - value;
                }
            }

            if (to != address(0)) {
                _balances[id][to] += value;
            }
        }

        if (ids.length == 1) {
            uint256 id = ids.unsafeMemoryAccess(0);
            uint256 value = values.unsafeMemoryAccess(0);
            emit TransferSingle(operator, from, to, id, value);
        } else {
            emit TransferBatch(operator, from, to, ids, values);
        }
    }

    /**
     * @dev Version of {_update} that performs the token acceptance check by calling {IERC1155Receiver-onERC1155Received}
     * or {IERC1155Receiver-onERC1155BatchReceived} on the receiver address if it contains code (eg. is a smart contract
     * at the moment of execution).
     *
     * IMPORTANT: Overriding this function is discouraged because it poses a reentrancy risk from the receiver. So any
     * update to the contract state after this function would break the check-effect-interaction pattern. Consider
     * overriding {_update} instead.
     */
    function _updateWithAcceptanceCheck(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory values,
        bytes memory data
    ) internal virtual {
        _update(from, to, ids, values);
        if (to != address(0)) {
            address operator = _msgSender();
            if (ids.length == 1) {
                uint256 id = ids.unsafeMemoryAccess(0);
                uint256 value = values.unsafeMemoryAccess(0);
                _doSafeTransferAcceptanceCheck(operator, from, to, id, value, data);
            } else {
                _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, values, data);
            }
        }
    }

    /**
     * @dev Transfers a `value` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `from` must have a balance of tokens of type `id` of at least `value` amount.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _safeTransferFrom(address from, address to, uint256 id, uint256 value, bytes memory data) internal {
        if (to == address(0)) {
            revert ERC1155InvalidReceiver(address(0));
        }
        if (from == address(0)) {
            revert ERC1155InvalidSender(address(0));
        }
        (uint256[] memory ids, uint256[] memory values) = _asSingletonArrays(id, value);
        _updateWithAcceptanceCheck(from, to, ids, values, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     * - `ids` and `values` must have the same length.
     */
    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory values,
        bytes memory data
    ) internal {
        if (to == address(0)) {
            revert ERC1155InvalidReceiver(address(0));
        }
        if (from == address(0)) {
            revert ERC1155InvalidSender(address(0));
        }
        _updateWithAcceptanceCheck(from, to, ids, values, data);
    }

    /**
     * @dev Sets a new URI for all token types, by relying on the token type ID
     * substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * By this mechanism, any occurrence of the `\{id\}` substring in either the
     * URI or any of the values in the JSON file at said URI will be replaced by
     * clients with the token type ID.
     *
     * For example, the `https://token-cdn-domain/\{id\}.json` URI would be
     * interpreted by clients as
     * `https://token-cdn-domain/000000000000000000000000000000000000000000000000000000000004cce0.json`
     * for token type ID 0x4cce0.
     *
     * See {uri}.
     *
     * Because these URIs cannot be meaningfully represented by the {URI} event,
     * this function emits no events.
     */
    function _setURI(string memory newuri) internal virtual {
        _uri = newuri;
    }

    /**
     * @dev Creates a `value` amount of tokens of type `id`, and assigns them to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(address to, uint256 id, uint256 value, bytes memory data) internal {
        if (to == address(0)) {
            revert ERC1155InvalidReceiver(address(0));
        }
        (uint256[] memory ids, uint256[] memory values) = _asSingletonArrays(id, value);
        _updateWithAcceptanceCheck(address(0), to, ids, values, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `values` must have the same length.
     * - `to` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _mintBatch(address to, uint256[] memory ids, uint256[] memory values, bytes memory data) internal {
        if (to == address(0)) {
            revert ERC1155InvalidReceiver(address(0));
        }
        _updateWithAcceptanceCheck(address(0), to, ids, values, data);
    }

    /**
     * @dev Destroys a `value` amount of tokens of type `id` from `from`
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `from` must have at least `value` amount of tokens of type `id`.
     */
    function _burn(address from, uint256 id, uint256 value) internal {
        if (from == address(0)) {
            revert ERC1155InvalidSender(address(0));
        }
        (uint256[] memory ids, uint256[] memory values) = _asSingletonArrays(id, value);
        _updateWithAcceptanceCheck(from, address(0), ids, values, "");
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `from` must have at least `value` amount of tokens of type `id`.
     * - `ids` and `values` must have the same length.
     */
    function _burnBatch(address from, uint256[] memory ids, uint256[] memory values) internal {
        if (from == address(0)) {
            revert ERC1155InvalidSender(address(0));
        }
        _updateWithAcceptanceCheck(from, address(0), ids, values, "");
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the zero address.
     */
    function _setApprovalForAll(address owner, address operator, bool approved) internal virtual {
        if (operator == address(0)) {
            revert ERC1155InvalidOperator(address(0));
        }
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Performs an acceptance check by calling {IERC1155-onERC1155Received} on the `to` address
     * if it contains code at the moment of execution.
     */
    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 value,
        bytes memory data
    ) private {
        if (to.code.length > 0) {
            try IERC1155Receiver(to).onERC1155Received(operator, from, id, value, data) returns (bytes4 response) {
                if (response != IERC1155Receiver.onERC1155Received.selector) {
                    // Tokens rejected
                    revert ERC1155InvalidReceiver(to);
                }
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    // non-ERC1155Receiver implementer
                    revert ERC1155InvalidReceiver(to);
                } else {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        }
    }

    /**
     * @dev Performs a batch acceptance check by calling {IERC1155-onERC1155BatchReceived} on the `to` address
     * if it contains code at the moment of execution.
     */
    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory values,
        bytes memory data
    ) private {
        if (to.code.length > 0) {
            try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, values, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155Receiver.onERC1155BatchReceived.selector) {
                    // Tokens rejected
                    revert ERC1155InvalidReceiver(to);
                }
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    // non-ERC1155Receiver implementer
                    revert ERC1155InvalidReceiver(to);
                } else {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        }
    }

    /**
     * @dev Creates an array in memory with only one value for each of the elements provided.
     */
    function _asSingletonArrays(
        uint256 element1,
        uint256 element2
    ) private pure returns (uint256[] memory array1, uint256[] memory array2) {
        /// @solidity memory-safe-assembly
        assembly {
            // Load the free memory pointer
            array1 := mload(0x40)
            // Set array length to 1
            mstore(array1, 1)
            // Store the single element at the next word after the length (where content starts)
            mstore(add(array1, 0x20), element1)

            // Repeat for next array locating it right after the first array
            array2 := add(array1, 0x40)
            mstore(array2, 1)
            mstore(add(array2, 0x20), element2)

            // Update the free memory pointer by pointing after the second array
            mstore(0x40, add(array2, 0x40))
        }
    }
}

// File: contracts/EasyMintLogic.sol


pragma solidity ^0.8.20;




abstract contract EasyMintLogic is ERC1155, EasyBatcher {
    using EasyLibrary for *;
    uint256 public maxMintAmount;
    uint256 public randomCounter;

    bool public paused = true;

    mapping(uint256 => uint256) public currentSupply;
    mapping(uint256 => bool) public createdToken;

    mapping(address => mapping(uint256 => uint256)) public walletMinted;
    mapping(uint256 => string) public roll;

    bool tiersInUse;
    bool onlyTiers;
    EasyLibrary.Tier[] public tiers;
    string public tierURI;
    mapping(address => mapping(uint256 => uint256)) public tierMinted;

    error SkewedArrays();
    error InvalidMintType();
    error IncorrectBatch();
    error InvalidAmount();
    error InvalidID();
    error FailedMintCheck();
    error Paused();
    error NotMintDate();
    error Limited();
    error InsufficientFunds();
    error OutOfStock();
    error NotListed();

    constructor() ERC1155(""){}

    function checkMintType(uint _fromBatch, bool _beState) internal view virtual {
        if ((!_beState && batchData[_fromBatch].bMintInOrder) || (_beState && !batchData[_fromBatch].bMintInOrder)) {
            revert InvalidMintType();
        }
    }

    function checkAmounts(uint _minAmount, uint _maxAmount) internal view virtual {
        if (_minAmount > _maxAmount || _minAmount <= 0) {
            revert InvalidAmount();
        }
    }

     /**
    @dev Admin can set the PAUSE state for all or just a batch.
    @param _pauseAll Whether to pause all batches.
    @param _fromBatch The ID of the batch to pause.
    @param _state Whether to set the batch or all batches as paused or unpaused.
    true = closed to Admin Only
    false = open for Presale or Public
    */
    function pause(bool _pauseAll, uint _fromBatch, bool _state) public virtual onlyAdmins {
        if(_pauseAll){
            paused = _state;
        }
        else{
            setStateOf(0, _state, _fromBatch);
        }
    }

    function setTierUse(bool _inUse, bool _onlyUse) public virtual onlyAdmins {
        tiersInUse = _inUse;
        onlyTiers = _onlyUse;
    }

    /**
    @dev Returns the cost for minting a token from the specified batch ID.
    If the caller is not an Admin, the function will return the presale cost if the batch is a presale batch,
    otherwise it will return the regular batch cost. If the caller is an Admin, the function will return 0.
    */
    function _cost(uint _batchID, bool _onTierList, uint8 _tID) public view virtual returns(uint256){
        if (!checkIfAdmin()) {
            if(_onTierList){
                return tiers[_tID].tCost;
            }
            
            return batchData[_batchID].bCost;
        }
        return 0;
    }

    function checkOut(uint _amount, uint _batchID, bytes32[] calldata proof) private {
        if (!checkIfAdmin()) {
            if(paused || batchData[_batchID].bPaused) {
                revert Paused();
            }

            if (batchData[_batchID].bMintStartDate > 0) {
                if(block.timestamp < batchData[_batchID].bMintStartDate) {
                    revert NotMintDate();
                }
            }

            if(batchData[_batchID].bLimit != 0){
                if(walletMinted[msg.sender][_batchID] + _amount > batchData[_batchID].bLimit) {
                    revert Limited();
                }
                walletMinted[msg.sender][_batchID] += _amount;
            }

            (bool _onTierList, uint8 _tID) = isValidTier(proof, keccak256(abi.encodePacked(msg.sender)));
            if(_onTierList){
                if (tiers[_tID].tLimit != 0) {
                    if (tierMinted[msg.sender][_tID] + _amount <= tiers[_tID].tLimit) {
                        tierMinted[msg.sender][_tID] += _amount;
                    } else if (_tID < tiers.length - 1) {
                        _tID++;
                    }
                }
            } else {
                if(onlyTiers){
                    revert NotListed();
                }
            }
            
            if(msg.value < (_amount * _cost(_batchID, _onTierList, _tID))) {
                revert InsufficientFunds();
            }
        }
    }

    function checkOutScan(uint _id, uint _fromBatch) private{
        if (!exists(_id)) {
            createdToken[_id] = true;
            if(batchData[_fromBatch].bMintInOrder){
                currentSupply[_id] = 1;
            }
        }

        if(batchData[_fromBatch].bRollInUse){
            roll[_id] = randomRoll(_fromBatch);
        }

        if(batchData[_fromBatch].bCost != batchData[_fromBatch].bNextCost && batchData[_fromBatch].bRangeNext[2] >= batchData[_fromBatch].bTriggerPoint){
            batchData[_fromBatch].bCost = batchData[_fromBatch].bNextCost;
        }
        randomCounter++;
    }

    /**
    @dev Allows Admins, Whitelisters, and Public to mint NFTs in order from a collection batch.
    Admins can call this function even while the contract is paused.
    @param _to The address to mint the NFTs to.
    @param _numberOfTokensToMint The number of tokens to mint from the batch in order.
    @param _fromBatch The batch to mint the NFTs from.
    @param proof An array of Merkle tree proofs to validate the mint.
    */
    function _mintInOrder(address _to, uint _numberOfTokensToMint, uint _fromBatch, bytes32[] calldata proof) public virtual payable {
        checkMintType(_fromBatch, true);
        if(exists(batchData[_fromBatch].bRangeNext[1])) {
            revert OutOfStock();
        }
        if (_fromBatch >= batchData.length) {
            revert BatchOutOfRange();
        }
        checkAmounts(_numberOfTokensToMint + batchData[_fromBatch].bRangeNext[2] - 1, batchData[_fromBatch].bRangeNext[1]);

        checkOut(_numberOfTokensToMint, _fromBatch, proof);
        
        _mintBatchTo(_to, _numberOfTokensToMint, _fromBatch);
    }

    function _mintBatchTo(address _to, uint _numberOfTokensToMint, uint _fromBatch)private {
        uint256[] memory _ids = new uint256[](_numberOfTokensToMint);
        uint256[] memory _amounts = new uint256[](_numberOfTokensToMint);
        for (uint256 i = 0; i < _numberOfTokensToMint; i++) {
            uint256 _id = batchData[_fromBatch].bRangeNext[2];
            if(!canMintChecker(_id, 1, _fromBatch)) {
                revert FailedMintCheck();
            }
            
            checkOutScan(_id, _fromBatch);

            _ids[i] = batchData[_fromBatch].bRangeNext[2];
            _amounts[i] = 1;
            batchData[_fromBatch].bRangeNext[2]++;
        }
        
        _mintBatch(_to, _ids, _amounts, "");
    }

    /**
    @dev Allows Owner, Whitelisters, and Public to mint a single NFT with the given _id, _amount, and _fromBatch parameters for the specified _to address.
    @param _to The address to mint the NFT to.
    @param _id The ID of the NFT to mint.
    @param _amount The amount of NFTs to mint.
    @param _fromBatch The batch end ID that the NFT belongs to.
    @param proof The Merkle proof verifying the ownership of the tokens being minted.
    Requirements:
    - mintInOrder[_fromBatch] must be false.
    - _id must be within the batch specified by _fromBatch.
    - The total number of NFTs being minted across all batches cannot exceed maxMintAmount.
    - If the caller is not an admin, the contract must not be paused and the batch being minted from must not be paused.
    - The caller must have a valid Merkle proof for the tokens being minted.
    - The amount of tokens being minted must satisfy the canMintChecker function.
    - The ID being minted must not have reached its max supply.
    */
    function mint(address _to, uint _id, uint _amount, uint _fromBatch, bytes32[] calldata proof) public virtual payable {
        checkMintType(_fromBatch, false);
        if(!canMintChecker(_id, _amount, _fromBatch)) {
            revert FailedMintCheck();
        }

        checkOut(_amount, _fromBatch, proof);

        checkOutScan(_id, _fromBatch);
        currentSupply[_id] += _amount;
        
        _mint(_to, _id, _amount, "");
    }

    function canMintChecker(uint _id, uint _amount, uint _fromBatch) private view returns(bool){
        if(_id < batchData[_fromBatch].bRangeNext[0] || _id > batchData[_fromBatch].bRangeNext[1]) {
            revert IncorrectBatch();
        }
        checkAmounts(_amount, maxMintAmount);
        if(_id > collectionEndID) {
            revert InvalidID();
        }

        // checks if the id exceeded it's max supply limit that each id in the batch is assigned
        if(batchData[_fromBatch].bSupply != 0 && currentSupply[_id] + _amount > batchData[_fromBatch].bSupply){
            // CANNOT MINT 
            return false;
        }

        // checks if the batch (other than the original) that the id resides in needs requirement token(s)
        if(batchData[_fromBatch].bRequirementTokens.length > 0){
            if(EasyLibrary.hasSufficientTokens(batchData[_fromBatch].bRequirementAddresses, msg.sender, batchData[_fromBatch].bRequirementTokens, batchData[_fromBatch].bRequirementAmounts, batchData[_fromBatch].bRequirementContractType)){
                //CANNOT MINT: DOES NOT HAVE REQUIREMENT TOKEN(S) AMOUNTS
                return false;
            }
        }

        // CAN MINT
        return true;
    }

    /**
    @dev Allows Owner, Whitelisters, and Public to mint multiple NFTs at once, given a list of token IDs, their corresponding amounts,
    and the batch from which they are being minted. Checks if the caller has the required permissions and if the maximum allowed mint
    amount and maximum allowed batch mint amount are not exceeded. Also verifies that the specified token IDs are in the given batch,
    and that the caller has passed a valid proof of a transaction to checkOut.
    */
    function mintBatch(address _to, uint[] memory _ids, uint[] memory _amounts, uint _fromBatch, bytes32[] calldata proof) public virtual payable {
        checkMintType(_fromBatch, false);
        checkAmounts(_ids.length, maxMintAmount);
        if(_ids.length != _amounts.length) {
            revert SkewedArrays();
        }
        if(!canMintBatchChecker(_ids, _amounts, _fromBatch)) {
            revert FailedMintCheck();
        }

        uint256 _totalBatchAmount;
        for (uint256 i = 0; i < _amounts.length; i++) {
            _totalBatchAmount += _amounts[i];
        }
        if(_totalBatchAmount <= maxMintAmount) {
            revert Limited();
        }

        checkOut(_totalBatchAmount, _fromBatch, proof);

        for (uint256 k = 0; k < _ids.length; k++) {
            uint256 _id = _ids[k];
            checkOutScan(_id, _fromBatch);
            currentSupply[_ids[k]] += _amounts[k];
        }

        _mintBatch(_to, _ids, _amounts, "");
    }

    function canMintBatchChecker(uint[] memory _ids, uint[] memory _amounts, uint _fromBatch)private view returns(bool){
        for (uint256 i = 0; i < _ids.length; i++) {
            uint256 _id = _ids[i];
            uint256 _amount = _amounts[i];
            if(!canMintChecker(_id, _amount, _fromBatch)){
                // CANNOT MINT
                return false;
            }
        }

        return true;
    }

    /**
    @dev Allows User to DESTROY multiple tokens they own.
    */
    function burnBatch(uint[] memory _ids, uint[] memory _amounts) external virtual{
        _burnBatch(msg.sender, _ids, _amounts);
    }

    function randomRoll(uint _fromBatch) internal view virtual returns (string memory){
        return EasyLibrary.randomRoll(
            uint256(keccak256(abi.encodePacked(
                block.timestamp,
                block.prevrandao,
                msg.sender,
                randomCounter,
                roll[randomCounter - 1])
            )),
            randomCounter,
            batchData[_fromBatch].bRollRange[1],
            batchData[_fromBatch].bRollRange[0]
        );
    }

    /**
    @dev Sets the roll for a given token.
    @param _id The token ID.
    @param _roll The value of the roll.
    @param _fromBatch The ID of the batch to set the roll limit for.
    */
    function rollSet(uint256 _id, uint _roll, uint _fromBatch) public virtual payable {
        if (!checkIfAdmin()) {
            EasyLibrary.validateRoll(_roll, batchData[_fromBatch].bRollSwapAllow, batchData[_fromBatch].bRollRange[0], batchData[_fromBatch].bRollRange[1], balanceOf(msg.sender, _id), batchData[_fromBatch].bRollCost);
        }
        roll[_id] = Strings.toString(_roll);
    }

    /**
    @dev Returns the total number of tokens with a given ID that have been minted.
    @param _id The ID of the token.
    @return total number of tokens with the given ID.
    */
    function totalSupplyOfID(uint256 _id) public view virtual returns(uint256) {
        return currentSupply[_id];
    }

    /**
    @dev Returns true if a token with the given ID exists, otherwise returns false.
    @param _id The ID of the token.
    @return bool indicating whether the token with the given ID exists.
    */
    function exists(uint256 _id) public view virtual returns(bool) {
        return createdToken[_id];
    }

    /**
    @dev Returns the maximum supply of a token with the given ID.
    @param _batchID The ID of the batch.
    @return maximum supply of any token from batch. If it is 0, the supply is limitless.
    */
    function checkMaxSupply(uint256 _batchID) public view virtual returns(uint256) {
        return batchData[_batchID].bSupply;
    }

    /**
    @dev Allows admin to set the maximum amount of NFTs a user can mint in a single session.
    @param _newmaxMintAmount The new maximum amount of NFTs a user can mint in a single session.
    */
    function setMaxMintAmount(uint256 _newmaxMintAmount) public virtual onlyAdmins {
        maxMintAmount = _newmaxMintAmount;
    }

    /**
    * @dev Validates what tier a user is on for the Tierlist.
    */
    function isValidTier(bytes32[] calldata proof, bytes32 leaf) public view virtual returns (bool, uint8) {
        if (tiersInUse) {
            return EasyLibrary.validateTier(proof, leaf, tiers);
        }
        return (false, 0);
    }

    /**
    @dev Sets a new tier with the provided parameters or updates an existing tier.
    @param _create If true, creates a new tier with the provided parameters. If false, updates an existing tier.
    @param _tID The ID of the tier to be updated. Only applicable if _create is false.
    @param _tLimit The mint limit of the new tier or updated tier.
    @param _tCost The cost of the new tier or updated tier.
    @param _tRoot The Merkle root of the new tier or updated tier.
    Requirements:
    - Only admin addresses can call this function.
    - If _create is false, the ID provided must correspond to an existing tier.
    */
    function setTier(bool _create, uint8 _tID, uint256 _tLimit, uint256 _tCost, bytes32 _tRoot) external virtual onlyAdmins {
        // Define a new Tier struct with the provided cost and Merkle root.
        EasyLibrary.Tier memory newTier = EasyLibrary.Tier(
            _tLimit,
            _tCost,
            _tRoot
        );
        
        if(_create){
            // If _create is true, add the new tier to the end of the tiers array.
            tiers.push(newTier);
        }
        else{
            // If _create is false, update the existing tier at the specified ID.
            if(tiers.length <= 0 || _tID >= tiers.length) {
                revert InvalidID();
            }
            tiers[_tID] = newTier;
        }
    }
}

// File: contracts/CCPCyborgs.sol


pragma solidity ^0.8.20;




/// @author developer's website 🐸 https://www.halfsupershop.com/ 🐸
contract CCPCyborgs is EasyMintLogic {
    using EasyLibrary for *;
    string private hiddenURI;
    mapping(uint => string) private tokenToURI;

    address payable public payments;

    mapping(uint256 => bool) public flagged; //flagged tokens cannot be moved
    mapping(address => bool) public restricted; //restricted addresses cannot move tokens

    error Flagged();
    error Restricted();
    /* 
    address(0) = 0x0000000000000000000000000000000000000000
    */

    constructor() EasyInit(msg.sender){
        name = "Crypto Cloud Punks Cyborgs";
        symbol = "CCPCY";
    }

    /**
    @dev Sets the URI for a token or batch of tokens.
    @param _hidden Flag to determine if the URI should be set as the hidden URI.
    @param _tier Flag to determine if the URI should be set as the tier URI.
    @param _isBatch Flag to determine if a batch of tokens is being modified.
    @param _id ID of the token or batch of tokens being modified.
    @param _uriPS[] The new URI to be set 0 = Prefix, 1 = Suffix.
    */
    function setURI(bool _hidden, bool _tier, bool _isBatch, uint _id, string[2] memory _uriPS) external onlyAdmins {
        if (_hidden) {
            hiddenURI = _uriPS[0];
            return;
        }

        if (_tier) {
            tierURI = _uriPS[0];
            return;
        }

        if (!_isBatch) {
            tokenToURI[_id] = _uriPS[0];
            emit URI(_uriPS[0], _id);
        }
        else{
            //modify Batch URI
            batchData[_id].bURI = _uriPS;
        }
    }

    /**
    @dev Returns the URI for a given token ID. If the token is a collection,
    the URI may be batched. If the token batch has roll enabled, it will have
    a random roll id. If the token is not found, the URI defaults to a hidden URI.
    @param _id uint256 ID of the token to query the URI of
    @return string representing the URI for the given token ID
    */
    function uri(uint256 _id) override public view returns (string memory) {
        // Check if token is created
        if (!createdToken[_id] || _id > collectionEndID) {
            // Not found, default to hidden
            return hiddenURI;
        }

        // Check if URI is set for the token
        if (bytes(tokenToURI[_id]).length > 0) {
            return tokenToURI[_id];
        }

        // Iterate through batch IDs
        for (uint256 i = 0; i < batchData.length; i++) {
            if (_id >= batchData[i].bRangeNext[0] && _id <= batchData[i].bRangeNext[1]) {
                if (!batchData[i].bRevealed) {
                    return hiddenURI;
                }

                // Check if the token has a roll
                if (bytes(roll[_id]).length > 0) {
                    return string(abi.encodePacked(batchData[i].bURI[0], roll[_id], "/", Strings.toString(_id), batchData[i].bURI[1]));
                }

                // Token doesn't have a roll
                return string(abi.encodePacked(batchData[i].bURI[0], Strings.toString(_id), batchData[i].bURI[1]));
            }
        }

        // Token is beyond the last batch, return hidden URI
        return hiddenURI;
    }

    /**
    @dev Allows admin to set the payout address for the contract.
    @param _address The new payout address to set.
    Note: address can be a wallet or a payment splitter contract
    */
    function setPayoutAddress(address _address) external onlyOwner{
        payments = payable(_address);
    }

    /**
    @dev Admin can withdraw the contract's balance to the specified payout address.
    The `payments` address must be set before calling this function.
    The function will revert if `payments` address is not set or the transaction fails.
    */
    function withdraw() public onlyAdmins {
        require(payments != address(0), "Payout address not set");

        uint256 balance = address(this).balance;
        require(balance > 0, "No funds to withdraw");

        // Splitter
        (bool success, ) = payable(payments).call{ value: balance }("");
        require(success, "Withdrawal failed");
    }

    /**
    @dev Auto send funds to the payout address.
    Triggers only if funds were sent directly to this address.
    */
    receive() external payable {
        require(payments != address(0), "Payment address not set");
        uint256 payout = msg.value;
        payments.transfer(payout);
    }

    /**
    * @dev Owner or Project Leader can set the restricted state of an address.
    * Note: Restricted addresses are banned from moving tokens.
    */
    function restrictAddress(address _user, bool _state) external {
        require(msg.sender == owner() || msg.sender == projectLeader, "NOoPL");
        restricted[_user] = _state;
    }

    /**
    * @dev Owner or Project Leader can set the flag state of a token ID.
    * Note: Flagged tokens are locked and untransferable.
    */
    function flagID(uint256 _id, bool _state) external {
        require(msg.sender == owner() || msg.sender == projectLeader, "NOoPL");
        flagged[_id] = _state;
    }

    /**
    * @dev Check if an ID is in a bind on mint batch.
    */
    function bindOnMint(uint _id) public view returns(bool){
        uint256 _batchID;
        if (batchData.length > 0) {
            for (uint256 i = 0; i < batchData.length; i++) {
                if (_id >= batchData[i].bRangeNext[0] && _id <= batchData[i].bRangeNext[1]) {
                    _batchID = i;
                }
            }
            return batchData[_batchID].bBindOnMint;
        }
        return false;
    }

    /**
    * @dev Hook that is called for any token transfer. 
    * This includes minting and burning, as well as batched variants.
    */
    function _update(address from, address to, uint256[] memory ids, uint256[] memory amounts) internal virtual override {
        // ... before action here ...
        if (restricted[from] || restricted[to]) {
            revert Restricted();
        }

        for (uint256 i = 0; i < ids.length; i++) {
            if (flagged[ids[i]]) {
                revert Flagged(); //reverts if a token has been flagged
            }
        }
        
        super._update(from, to, ids, amounts); // Call parent hook

        // ... after action here ...
        for (uint256 i = 0; i < ids.length; i++) {
            if (bindOnMint(ids[i])) {
                flagged[ids[i]] = true;
            }

            if (to == address(0)) {
                //burned tokens
                uint256 _id = ids[i];
                currentSupply[_id] -= amounts[i];
            }
        }   
    }
}