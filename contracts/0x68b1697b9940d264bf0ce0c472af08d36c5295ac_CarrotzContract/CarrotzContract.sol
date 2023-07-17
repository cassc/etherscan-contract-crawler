/**
 *Submitted for verification at Etherscan.io on 2023-06-27
*/

// File: ContractEnkardia/ContractEnkardia/lib/Constants.sol


pragma solidity ^0.8.13;

address constant CANONICAL_OPERATOR_FILTER_REGISTRY_ADDRESS = 0x000000000000AAeB6D7670E522A718067333cd4E;
address constant CANONICAL_CORI_SUBSCRIPTION = 0x3cc6CddA760b79bAfa08dF41ECFA224f810dCeB6;
// File: ContractEnkardia/ContractEnkardia/IOperatorFilterRegistry.sol


pragma solidity ^0.8;

interface IOperatorFilterRegistry {
    /**
     * @notice Returns true if operator is not filtered for a given token, either by address or codeHash. Also returns
     *         true if supplied registrant address is not registered.
     */
    function isOperatorAllowed(address registrant, address operator) external view returns (bool);

    /**
     * @notice Registers an address with the registry. May be called by address itself or by EIP-173 owner.
     */
    function register(address registrant) external;

    /**
     * @notice Registers an address with the registry and "subscribes" to another address's filtered operators and codeHashes.
     */
    function registerAndSubscribe(address registrant, address subscription) external;

    /**
     * @notice Registers an address with the registry and copies the filtered operators and codeHashes from another
     *         address without subscribing.
     */
    function registerAndCopyEntries(address registrant, address registrantToCopy) external;

    /**
     * @notice Unregisters an address with the registry and removes its subscription. May be called by address itself or by EIP-173 owner.
     *         Note that this does not remove any filtered addresses or codeHashes.
     *         Also note that any subscriptions to this registrant will still be active and follow the existing filtered addresses and codehashes.
     */
    function unregister(address addr) external;

    /**
     * @notice Update an operator address for a registered address - when filtered is true, the operator is filtered.
     */
    function updateOperator(address registrant, address operator, bool filtered) external;

    /**
     * @notice Update multiple operators for a registered address - when filtered is true, the operators will be filtered. Reverts on duplicates.
     */
    function updateOperators(address registrant, address[] calldata operators, bool filtered) external;

    /**
     * @notice Update a codeHash for a registered address - when filtered is true, the codeHash is filtered.
     */
    function updateCodeHash(address registrant, bytes32 codehash, bool filtered) external;

    /**
     * @notice Update multiple codeHashes for a registered address - when filtered is true, the codeHashes will be filtered. Reverts on duplicates.
     */
    function updateCodeHashes(address registrant, bytes32[] calldata codeHashes, bool filtered) external;

    /**
     * @notice Subscribe an address to another registrant's filtered operators and codeHashes. Will remove previous
     *         subscription if present.
     *         Note that accounts with subscriptions may go on to subscribe to other accounts - in this case,
     *         subscriptions will not be forwarded. Instead the former subscription's existing entries will still be
     *         used.
     */
    function subscribe(address registrant, address registrantToSubscribe) external;

    /**
     * @notice Unsubscribe an address from its current subscribed registrant, and optionally copy its filtered operators and codeHashes.
     */
    function unsubscribe(address registrant, bool copyExistingEntries) external;

    /**
     * @notice Get the subscription address of a given registrant, if any.
     */
    function subscriptionOf(address addr) external returns (address registrant);

    /**
     * @notice Get the set of addresses subscribed to a given registrant.
     *         Note that order is not guaranteed as updates are made.
     */
    function subscribers(address registrant) external returns (address[] memory);

    /**
     * @notice Get the subscriber at a given index in the set of addresses subscribed to a given registrant.
     *         Note that order is not guaranteed as updates are made.
     */
    function subscriberAt(address registrant, uint256 index) external returns (address);

    /**
     * @notice Copy filtered operators and codeHashes from a different registrantToCopy to addr.
     */
    function copyEntriesOf(address registrant, address registrantToCopy) external;

    /**
     * @notice Returns true if operator is filtered by a given address or its subscription.
     */
    function isOperatorFiltered(address registrant, address operator) external returns (bool);

    /**
     * @notice Returns true if the hash of an address's code is filtered by a given address or its subscription.
     */
    function isCodeHashOfFiltered(address registrant, address operatorWithCode) external returns (bool);

    /**
     * @notice Returns true if a codeHash is filtered by a given address or its subscription.
     */
    function isCodeHashFiltered(address registrant, bytes32 codeHash) external returns (bool);

    /**
     * @notice Returns a list of filtered operators for a given address or its subscription.
     */
    function filteredOperators(address addr) external returns (address[] memory);

    /**
     * @notice Returns the set of filtered codeHashes for a given address or its subscription.
     *         Note that order is not guaranteed as updates are made.
     */
    function filteredCodeHashes(address addr) external returns (bytes32[] memory);

    /**
     * @notice Returns the filtered operator at the given index of the set of filtered operators for a given address or
     *         its subscription.
     *         Note that order is not guaranteed as updates are made.
     */
    function filteredOperatorAt(address registrant, uint256 index) external returns (address);

    /**
     * @notice Returns the filtered codeHash at the given index of the list of filtered codeHashes for a given address or
     *         its subscription.
     *         Note that order is not guaranteed as updates are made.
     */
    function filteredCodeHashAt(address registrant, uint256 index) external returns (bytes32);

    /**
     * @notice Returns true if an address has registered
     */
    function isRegistered(address addr) external returns (bool);

    /**
     * @dev Convenience method to compute the code hash of an arbitrary contract
     */
    function codeHashOf(address addr) external returns (bytes32);
}

// File: ContractEnkardia/ContractEnkardia/OperatorFilterer.sol


pragma solidity ^0.8;


/**
 * @title  OperatorFilterer
 * @notice Abstract contract whose constructor automatically registers and optionally subscribes to or copies another
 *         registrant's entries in the OperatorFilterRegistry.
 * @dev    This smart contract is meant to be inherited by token contracts so they can use the following:
 *         - `onlyAllowedOperator` modifier for `transferFrom` and `safeTransferFrom` methods.
 *         - `onlyAllowedOperatorApproval` modifier for `approve` and `setApprovalForAll` methods.
 *         Please note that if your token contract does not provide an owner with EIP-173, it must provide
 *         administration methods on the contract itself to interact with the registry otherwise the subscription
 *         will be locked to the options set during construction.
 */

abstract contract OperatorFilterer {
    /// @dev Emitted when an operator is not allowed.
    error OperatorNotAllowed(address operator);

    IOperatorFilterRegistry public constant OPERATOR_FILTER_REGISTRY =
        IOperatorFilterRegistry(CANONICAL_OPERATOR_FILTER_REGISTRY_ADDRESS);

    /// @dev The constructor that is called when the contract is being deployed.
    constructor(address subscriptionOrRegistrantToCopy, bool subscribe) {
        // If an inheriting token contract is deployed to a network without the registry deployed, the modifier
        // will not revert, but the contract will need to be registered with the registry once it is deployed in
        // order for the modifier to filter addresses.
        if (address(OPERATOR_FILTER_REGISTRY).code.length > 0) {
            if (subscribe) {
                OPERATOR_FILTER_REGISTRY.registerAndSubscribe(address(this), subscriptionOrRegistrantToCopy);
            } else {
                if (subscriptionOrRegistrantToCopy != address(0)) {
                    OPERATOR_FILTER_REGISTRY.registerAndCopyEntries(address(this), subscriptionOrRegistrantToCopy);
                } else {
                    OPERATOR_FILTER_REGISTRY.register(address(this));
                }
            }
        }
    }

    /**
     * @dev A helper function to check if an operator is allowed.
     */
    modifier onlyAllowedOperator(address from) virtual {
        // Allow spending tokens from addresses with balance
        // Note that this still allows listings and marketplaces with escrow to transfer tokens if transferred
        // from an EOA.
        if (from != msg.sender) {
            _checkFilterOperator(msg.sender);
        }
        _;
    }

    /**
     * @dev A helper function to check if an operator approval is allowed.
     */
    modifier onlyAllowedOperatorApproval(address operator) virtual {
        _checkFilterOperator(operator);
        _;
    }

    /**
     * @dev A helper function to check if an operator is allowed.
     */
    function _checkFilterOperator(address operator) internal view virtual {
        // Check registry code length to facilitate testing in environments without a deployed registry.
        if (address(OPERATOR_FILTER_REGISTRY).code.length > 0) {
            // under normal circumstances, this function will revert rather than return false, but inheriting contracts
            // may specify their own OperatorFilterRegistry implementations, which may behave differently
            if (!OPERATOR_FILTER_REGISTRY.isOperatorAllowed(address(this), operator)) {
                revert OperatorNotAllowed(operator);
            }
        }
    }
}

// File: ContractEnkardia/ContractEnkardia/DefaultOperatorFilterer.sol


pragma solidity ^0.8;


/**
 * @title  DefaultOperatorFilterer
 * @notice Inherits from OperatorFilterer and automatically subscribes to the default OpenSea subscription.
 * @dev    Please note that if your token contract does not provide an owner with EIP-173, it must provide
 *         administration methods on the contract itself to interact with the registry otherwise the subscription
 *         will be locked to the options set during construction.
 */

abstract contract DefaultOperatorFilterer is OperatorFilterer {
    /// @dev The constructor that is called when the contract is being deployed.
    constructor() OperatorFilterer(CANONICAL_CORI_SUBSCRIPTION, true) {}
}

// File: @openzeppelin/contracts/utils/math/SafeMath.sol


// OpenZeppelin Contracts (last updated v4.9.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
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
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
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
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// File: @openzeppelin/contracts/utils/math/SignedMath.sol


// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/SignedMath.sol)

pragma solidity ^0.8.0;

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

// File: @openzeppelin/contracts/utils/Strings.sol


// OpenZeppelin Contracts (last updated v4.9.0) (utils/Strings.sol)

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
     * @dev Converts a `int256` to its ASCII `string` decimal representation.
     */
    function toString(int256 value) internal pure returns (string memory) {
        return string(abi.encodePacked(value < 0 ? "-" : "", toString(SignedMath.abs(value))));
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

    /**
     * @dev Returns true if the two strings are equal.
     */
    function equal(string memory a, string memory b) internal pure returns (bool) {
        return keccak256(bytes(a)) == keccak256(bytes(b));
    }
}

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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
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
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
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

// File: @openzeppelin/contracts/utils/introspection/ERC165.sol


// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;


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
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
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

// File: @openzeppelin/contracts/token/common/ERC2981.sol


// OpenZeppelin Contracts (last updated v4.9.0) (token/common/ERC2981.sol)

pragma solidity ^0.8.0;



/**
 * @dev Implementation of the NFT Royalty Standard, a standardized way to retrieve royalty payment information.
 *
 * Royalty information can be specified globally for all token ids via {_setDefaultRoyalty}, and/or individually for
 * specific token ids via {_setTokenRoyalty}. The latter takes precedence over the first.
 *
 * Royalty is specified as a fraction of sale price. {_feeDenominator} is overridable but defaults to 10000, meaning the
 * fee is specified in basis points by default.
 *
 * IMPORTANT: ERC-2981 only specifies a way to signal royalty information and does not enforce its payment. See
 * https://eips.ethereum.org/EIPS/eip-2981#optional-royalty-payments[Rationale] in the EIP. Marketplaces are expected to
 * voluntarily pay royalties together with sales, but note that this standard is not yet widely supported.
 *
 * _Available since v4.5._
 */
abstract contract ERC2981 is IERC2981, ERC165 {
    struct RoyaltyInfo {
        address receiver;
        uint96 royaltyFraction;
    }

    RoyaltyInfo private _defaultRoyaltyInfo;
    mapping(uint256 => RoyaltyInfo) private _tokenRoyaltyInfo;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC165) returns (bool) {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @inheritdoc IERC2981
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice) public view virtual override returns (address, uint256) {
        RoyaltyInfo memory royalty = _tokenRoyaltyInfo[tokenId];

        if (royalty.receiver == address(0)) {
            royalty = _defaultRoyaltyInfo;
        }

        uint256 royaltyAmount = (salePrice * royalty.royaltyFraction) / _feeDenominator();

        return (royalty.receiver, royaltyAmount);
    }

    /**
     * @dev The denominator with which to interpret the fee set in {_setTokenRoyalty} and {_setDefaultRoyalty} as a
     * fraction of the sale price. Defaults to 10000 so fees are expressed in basis points, but may be customized by an
     * override.
     */
    function _feeDenominator() internal pure virtual returns (uint96) {
        return 10000;
    }

    /**
     * @dev Sets the royalty information that all ids in this contract will default to.
     *
     * Requirements:
     *
     * - `receiver` cannot be the zero address.
     * - `feeNumerator` cannot be greater than the fee denominator.
     */
    function _setDefaultRoyalty(address receiver, uint96 feeNumerator) internal virtual {
        require(feeNumerator <= _feeDenominator(), "ERC2981: royalty fee will exceed salePrice");
        require(receiver != address(0), "ERC2981: invalid receiver");

        _defaultRoyaltyInfo = RoyaltyInfo(receiver, feeNumerator);
    }

    /**
     * @dev Removes default royalty information.
     */
    function _deleteDefaultRoyalty() internal virtual {
        delete _defaultRoyaltyInfo;
    }

    /**
     * @dev Sets the royalty information for a specific token id, overriding the global default.
     *
     * Requirements:
     *
     * - `receiver` cannot be the zero address.
     * - `feeNumerator` cannot be greater than the fee denominator.
     */
    function _setTokenRoyalty(uint256 tokenId, address receiver, uint96 feeNumerator) internal virtual {
        require(feeNumerator <= _feeDenominator(), "ERC2981: royalty fee will exceed salePrice");
        require(receiver != address(0), "ERC2981: Invalid parameters");

        _tokenRoyaltyInfo[tokenId] = RoyaltyInfo(receiver, feeNumerator);
    }

    /**
     * @dev Resets royalty information for the token id back to the global default.
     */
    function _resetTokenRoyalty(uint256 tokenId) internal virtual {
        delete _tokenRoyaltyInfo[tokenId];
    }
}

// File: ContractEnkardia/ERC721A/contracts/IERC721A.sol


// ERC721A Contracts v4.2.3
// Creator: Chiru Labs

pragma solidity ^0.8.4;

/**
 * @dev Interface of ERC721A.
 */
interface IERC721A {
    /**
     * The caller must own the token or be an approved operator.
     */
    error ApprovalCallerNotOwnerNorApproved();

    /**
     * The token does not exist.
     */
    error ApprovalQueryForNonexistentToken();

    /**
     * Cannot query the balance for the zero address.
     */
    error BalanceQueryForZeroAddress();

    /**
     * Cannot mint to the zero address.
     */
    error MintToZeroAddress();

    /**
     * The quantity of tokens minted must be more than zero.
     */
    error MintZeroQuantity();

    /**
     * The token does not exist.
     */
    error OwnerQueryForNonexistentToken();

    /**
     * The caller must own the token or be an approved operator.
     */
    error TransferCallerNotOwnerNorApproved();

    /**
     * The token must be owned by `from`.
     */
    error TransferFromIncorrectOwner();

    /**
     * Cannot safely transfer to a contract that does not implement the
     * ERC721Receiver interface.
     */
    error TransferToNonERC721ReceiverImplementer();

    /**
     * Cannot transfer to the zero address.
     */
    error TransferToZeroAddress();

    /**
     * The token does not exist.
     */
    error URIQueryForNonexistentToken();

    /**
     * The `quantity` minted with ERC2309 exceeds the safety limit.
     */
    error MintERC2309QuantityExceedsLimit();

    /**
     * The `extraData` cannot be set on an unintialized ownership slot.
     */
    error OwnershipNotInitializedForExtraData();

    // =============================================================
    //                            STRUCTS
    // =============================================================

    struct TokenOwnership {
        // The address of the owner.
        address addr;
        // Stores the start time of ownership with minimal overhead for tokenomics.
        uint64 startTimestamp;
        // Whether the token has been burned.
        bool burned;
        // Arbitrary data similar to `startTimestamp` that can be set via {_extraData}.
        uint24 extraData;
    }

    // =============================================================
    //                         TOKEN COUNTERS
    // =============================================================

    /**
     * @dev Returns the total number of tokens in existence.
     * Burned tokens will reduce the count.
     * To get the total number of tokens minted, please see {_totalMinted}.
     */
    function totalSupply() external view returns (uint256);

    // =============================================================
    //                            IERC165
    // =============================================================

    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * [EIP section](https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified)
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);

    // =============================================================
    //                            IERC721
    // =============================================================

    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables
     * (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in `owner`'s account.
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
     * @dev Safely transfers `tokenId` token from `from` to `to`,
     * checking first that contract recipients are aware of the ERC721 protocol
     * to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move
     * this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement
     * {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external payable;

    /**
     * @dev Equivalent to `safeTransferFrom(from, to, tokenId, '')`.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external payable;

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom}
     * whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token
     * by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external payable;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the
     * zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external payable;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom}
     * for any token owned by the caller.
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
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    // =============================================================
    //                        IERC721Metadata
    // =============================================================

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

    // =============================================================
    //                           IERC2309
    // =============================================================

    /**
     * @dev Emitted when tokens in `fromTokenId` to `toTokenId`
     * (inclusive) is transferred from `from` to `to`, as defined in the
     * [ERC2309](https://eips.ethereum.org/EIPS/eip-2309) standard.
     *
     * See {_mintERC2309} for more details.
     */
    event ConsecutiveTransfer(uint256 indexed fromTokenId, uint256 toTokenId, address indexed from, address indexed to);
}

// File: ContractEnkardia/ERC721A/contracts/ERC721A.sol


// ERC721A Contracts v4.2.3
// Creator: Chiru Labs

pragma solidity ^0.8.4;


/**
 * @dev Interface of ERC721 token receiver.
 */
interface ERC721A__IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

/**
 * @title ERC721A
 *
 * @dev Implementation of the [ERC721](https://eips.ethereum.org/EIPS/eip-721)
 * Non-Fungible Token Standard, including the Metadata extension.
 * Optimized for lower gas during batch mints.
 *
 * Token IDs are minted in sequential order (e.g. 0, 1, 2, 3, ...)
 * starting from `_startTokenId()`.
 *
 * Assumptions:
 *
 * - An owner cannot have more than 2**64 - 1 (max value of uint64) of supply.
 * - The maximum token ID cannot exceed 2**256 - 1 (max value of uint256).
 */
contract ERC721A is IERC721A {
    // Bypass for a `--via-ir` bug (https://github.com/chiru-labs/ERC721A/pull/364).
    struct TokenApprovalRef {
        address value;
    }

    // =============================================================
    //                           CONSTANTS
    // =============================================================

    // Mask of an entry in packed address data.
    uint256 private constant _BITMASK_ADDRESS_DATA_ENTRY = (1 << 64) - 1;

    // The bit position of `numberMinted` in packed address data.
    uint256 private constant _BITPOS_NUMBER_MINTED = 64;

    // The bit position of `numberBurned` in packed address data.
    uint256 private constant _BITPOS_NUMBER_BURNED = 128;

    // The bit position of `aux` in packed address data.
    uint256 private constant _BITPOS_AUX = 192;

    // Mask of all 256 bits in packed address data except the 64 bits for `aux`.
    uint256 private constant _BITMASK_AUX_COMPLEMENT = (1 << 192) - 1;

    // The bit position of `startTimestamp` in packed ownership.
    uint256 private constant _BITPOS_START_TIMESTAMP = 160;

    // The bit mask of the `burned` bit in packed ownership.
    uint256 private constant _BITMASK_BURNED = 1 << 224;

    // The bit position of the `nextInitialized` bit in packed ownership.
    uint256 private constant _BITPOS_NEXT_INITIALIZED = 225;

    // The bit mask of the `nextInitialized` bit in packed ownership.
    uint256 private constant _BITMASK_NEXT_INITIALIZED = 1 << 225;

    // The bit position of `extraData` in packed ownership.
    uint256 private constant _BITPOS_EXTRA_DATA = 232;

    // Mask of all 256 bits in a packed ownership except the 24 bits for `extraData`.
    uint256 private constant _BITMASK_EXTRA_DATA_COMPLEMENT = (1 << 232) - 1;

    // The mask of the lower 160 bits for addresses.
    uint256 private constant _BITMASK_ADDRESS = (1 << 160) - 1;

    // The maximum `quantity` that can be minted with {_mintERC2309}.
    // This limit is to prevent overflows on the address data entries.
    // For a limit of 5000, a total of 3.689e15 calls to {_mintERC2309}
    // is required to cause an overflow, which is unrealistic.
    uint256 private constant _MAX_MINT_ERC2309_QUANTITY_LIMIT = 5000;

    // The `Transfer` event signature is given by:
    // `keccak256(bytes("Transfer(address,address,uint256)"))`.
    bytes32 private constant _TRANSFER_EVENT_SIGNATURE =
        0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef;

    // =============================================================
    //                            STORAGE
    // =============================================================

    // The next token ID to be minted.
    uint256 private _currentIndex;

    // The number of tokens burned.
    uint256 private _burnCounter;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to ownership details
    // An empty struct value does not necessarily mean the token is unowned.
    // See {_packedOwnershipOf} implementation for details.
    //
    // Bits Layout:
    // - [0..159]   `addr`
    // - [160..223] `startTimestamp`
    // - [224]      `burned`
    // - [225]      `nextInitialized`
    // - [232..255] `extraData`
    mapping(uint256 => uint256) private _packedOwnerships;

    // Mapping owner address to address data.
    //
    // Bits Layout:
    // - [0..63]    `balance`
    // - [64..127]  `numberMinted`
    // - [128..191] `numberBurned`
    // - [192..255] `aux`
    mapping(address => uint256) private _packedAddressData;

    // Mapping from token ID to approved address.
    mapping(uint256 => TokenApprovalRef) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // =============================================================
    //                          CONSTRUCTOR
    // =============================================================

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        _currentIndex = _startTokenId();
    }

    // =============================================================
    //                   TOKEN COUNTING OPERATIONS
    // =============================================================

    /**
     * @dev Returns the starting token ID.
     * To change the starting token ID, please override this function.
     */
    function _startTokenId() internal view virtual returns (uint256) {
        return 0;
    }

    /**
     * @dev Returns the next token ID to be minted.
     */
    function _nextTokenId() internal view virtual returns (uint256) {
        return _currentIndex;
    }

    /**
     * @dev Returns the total number of tokens in existence.
     * Burned tokens will reduce the count.
     * To get the total number of tokens minted, please see {_totalMinted}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        // Counter underflow is impossible as _burnCounter cannot be incremented
        // more than `_currentIndex - _startTokenId()` times.
        unchecked {
            return _currentIndex - _burnCounter - _startTokenId();
        }
    }

    /**
     * @dev Returns the total amount of tokens minted in the contract.
     */
    function _totalMinted() internal view virtual returns (uint256) {
        // Counter underflow is impossible as `_currentIndex` does not decrement,
        // and it is initialized to `_startTokenId()`.
        unchecked {
            return _currentIndex - _startTokenId();
        }
    }

    /**
     * @dev Returns the total number of tokens burned.
     */
    function _totalBurned() internal view virtual returns (uint256) {
        return _burnCounter;
    }

    // =============================================================
    //                    ADDRESS DATA OPERATIONS
    // =============================================================

    /**
     * @dev Returns the number of tokens in `owner`'s account.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        if (owner == address(0)) _revert(BalanceQueryForZeroAddress.selector);
        return _packedAddressData[owner] & _BITMASK_ADDRESS_DATA_ENTRY;
    }

    /**
     * Returns the number of tokens minted by `owner`.
     */
    function _numberMinted(address owner) internal view returns (uint256) {
        return (_packedAddressData[owner] >> _BITPOS_NUMBER_MINTED) & _BITMASK_ADDRESS_DATA_ENTRY;
    }

    /**
     * Returns the number of tokens burned by or on behalf of `owner`.
     */
    function _numberBurned(address owner) internal view returns (uint256) {
        return (_packedAddressData[owner] >> _BITPOS_NUMBER_BURNED) & _BITMASK_ADDRESS_DATA_ENTRY;
    }

    /**
     * Returns the auxiliary data for `owner`. (e.g. number of whitelist mint slots used).
     */
    function _getAux(address owner) internal view returns (uint64) {
        return uint64(_packedAddressData[owner] >> _BITPOS_AUX);
    }

    /**
     * Sets the auxiliary data for `owner`. (e.g. number of whitelist mint slots used).
     * If there are multiple variables, please pack them into a uint64.
     */
    function _setAux(address owner, uint64 aux) internal virtual {
        uint256 packed = _packedAddressData[owner];
        uint256 auxCasted;
        // Cast `aux` with assembly to avoid redundant masking.
        assembly {
            auxCasted := aux
        }
        packed = (packed & _BITMASK_AUX_COMPLEMENT) | (auxCasted << _BITPOS_AUX);
        _packedAddressData[owner] = packed;
    }

    // =============================================================
    //                            IERC165
    // =============================================================

    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * [EIP section](https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified)
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30000 gas.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        // The interface IDs are constants representing the first 4 bytes
        // of the XOR of all function selectors in the interface.
        // See: [ERC165](https://eips.ethereum.org/EIPS/eip-165)
        // (e.g. `bytes4(i.functionA.selector ^ i.functionB.selector ^ ...)`)
        return
            interfaceId == 0x01ffc9a7 || // ERC165 interface ID for ERC165.
            interfaceId == 0x80ac58cd || // ERC165 interface ID for ERC721.
            interfaceId == 0x5b5e139f; // ERC165 interface ID for ERC721Metadata.
    }

    // =============================================================
    //                        IERC721Metadata
    // =============================================================

    /**
     * @dev Returns the token collection name.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) _revert(URIQueryForNonexistentToken.selector);

        string memory baseURI = _baseURI();
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, _toString(tokenId))) : '';
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, it can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return '';
    }

    // =============================================================
    //                     OWNERSHIPS OPERATIONS
    // =============================================================

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        return address(uint160(_packedOwnershipOf(tokenId)));
    }

    /**
     * @dev Gas spent here starts off proportional to the maximum mint batch size.
     * It gradually moves to O(1) as tokens get transferred around over time.
     */
    function _ownershipOf(uint256 tokenId) internal view virtual returns (TokenOwnership memory) {
        return _unpackedOwnership(_packedOwnershipOf(tokenId));
    }

    /**
     * @dev Returns the unpacked `TokenOwnership` struct at `index`.
     */
    function _ownershipAt(uint256 index) internal view virtual returns (TokenOwnership memory) {
        return _unpackedOwnership(_packedOwnerships[index]);
    }

    /**
     * @dev Returns whether the ownership slot at `index` is initialized.
     * An uninitialized slot does not necessarily mean that the slot has no owner.
     */
    function _ownershipIsInitialized(uint256 index) internal view virtual returns (bool) {
        return _packedOwnerships[index] != 0;
    }

    /**
     * @dev Initializes the ownership slot minted at `index` for efficiency purposes.
     */
    function _initializeOwnershipAt(uint256 index) internal virtual {
        if (_packedOwnerships[index] == 0) {
            _packedOwnerships[index] = _packedOwnershipOf(index);
        }
    }

    /**
     * Returns the packed ownership data of `tokenId`.
     */
    function _packedOwnershipOf(uint256 tokenId) private view returns (uint256 packed) {
        if (_startTokenId() <= tokenId) {
            packed = _packedOwnerships[tokenId];
            // If the data at the starting slot does not exist, start the scan.
            if (packed == 0) {
                if (tokenId >= _currentIndex) _revert(OwnerQueryForNonexistentToken.selector);
                // Invariant:
                // There will always be an initialized ownership slot
                // (i.e. `ownership.addr != address(0) && ownership.burned == false`)
                // before an unintialized ownership slot
                // (i.e. `ownership.addr == address(0) && ownership.burned == false`)
                // Hence, `tokenId` will not underflow.
                //
                // We can directly compare the packed value.
                // If the address is zero, packed will be zero.
                for (;;) {
                    unchecked {
                        packed = _packedOwnerships[--tokenId];
                    }
                    if (packed == 0) continue;
                    if (packed & _BITMASK_BURNED == 0) return packed;
                    // Otherwise, the token is burned, and we must revert.
                    // This handles the case of batch burned tokens, where only the burned bit
                    // of the starting slot is set, and remaining slots are left uninitialized.
                    _revert(OwnerQueryForNonexistentToken.selector);
                }
            }
            // Otherwise, the data exists and we can skip the scan.
            // This is possible because we have already achieved the target condition.
            // This saves 2143 gas on transfers of initialized tokens.
            // If the token is not burned, return `packed`. Otherwise, revert.
            if (packed & _BITMASK_BURNED == 0) return packed;
        }
        _revert(OwnerQueryForNonexistentToken.selector);
    }

    /**
     * @dev Returns the unpacked `TokenOwnership` struct from `packed`.
     */
    function _unpackedOwnership(uint256 packed) private pure returns (TokenOwnership memory ownership) {
        ownership.addr = address(uint160(packed));
        ownership.startTimestamp = uint64(packed >> _BITPOS_START_TIMESTAMP);
        ownership.burned = packed & _BITMASK_BURNED != 0;
        ownership.extraData = uint24(packed >> _BITPOS_EXTRA_DATA);
    }

    /**
     * @dev Packs ownership data into a single uint256.
     */
    function _packOwnershipData(address owner, uint256 flags) private view returns (uint256 result) {
        assembly {
            // Mask `owner` to the lower 160 bits, in case the upper bits somehow aren't clean.
            owner := and(owner, _BITMASK_ADDRESS)
            // `owner | (block.timestamp << _BITPOS_START_TIMESTAMP) | flags`.
            result := or(owner, or(shl(_BITPOS_START_TIMESTAMP, timestamp()), flags))
        }
    }

    /**
     * @dev Returns the `nextInitialized` flag set if `quantity` equals 1.
     */
    function _nextInitializedFlag(uint256 quantity) private pure returns (uint256 result) {
        // For branchless setting of the `nextInitialized` flag.
        assembly {
            // `(quantity == 1) << _BITPOS_NEXT_INITIALIZED`.
            result := shl(_BITPOS_NEXT_INITIALIZED, eq(quantity, 1))
        }
    }

    // =============================================================
    //                      APPROVAL OPERATIONS
    // =============================================================

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account. See {ERC721A-_approve}.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     */
    function approve(address to, uint256 tokenId) public payable virtual override {
        _approve(to, tokenId, true);
    }

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        if (!_exists(tokenId)) _revert(ApprovalQueryForNonexistentToken.selector);

        return _tokenApprovals[tokenId].value;
    }

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom}
     * for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _operatorApprovals[_msgSenderERC721A()][operator] = approved;
        emit ApprovalForAll(_msgSenderERC721A(), operator, approved);
    }

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted. See {_mint}.
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool result) {
        if (_startTokenId() <= tokenId) {
            if (tokenId < _currentIndex) {
                uint256 packed;
                while ((packed = _packedOwnerships[tokenId]) == 0) --tokenId;
                result = packed & _BITMASK_BURNED == 0;
            }
        }
    }

    /**
     * @dev Returns whether `msgSender` is equal to `approvedAddress` or `owner`.
     */
    function _isSenderApprovedOrOwner(
        address approvedAddress,
        address owner,
        address msgSender
    ) private pure returns (bool result) {
        assembly {
            // Mask `owner` to the lower 160 bits, in case the upper bits somehow aren't clean.
            owner := and(owner, _BITMASK_ADDRESS)
            // Mask `msgSender` to the lower 160 bits, in case the upper bits somehow aren't clean.
            msgSender := and(msgSender, _BITMASK_ADDRESS)
            // `msgSender == owner || msgSender == approvedAddress`.
            result := or(eq(msgSender, owner), eq(msgSender, approvedAddress))
        }
    }

    /**
     * @dev Returns the storage slot and value for the approved address of `tokenId`.
     */
    function _getApprovedSlotAndAddress(uint256 tokenId)
        private
        view
        returns (uint256 approvedAddressSlot, address approvedAddress)
    {
        TokenApprovalRef storage tokenApproval = _tokenApprovals[tokenId];
        // The following is equivalent to `approvedAddress = _tokenApprovals[tokenId].value`.
        assembly {
            approvedAddressSlot := tokenApproval.slot
            approvedAddress := sload(approvedAddressSlot)
        }
    }

    // =============================================================
    //                      TRANSFER OPERATIONS
    // =============================================================

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token
     * by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable virtual override {
        uint256 prevOwnershipPacked = _packedOwnershipOf(tokenId);

        // Mask `from` to the lower 160 bits, in case the upper bits somehow aren't clean.
        from = address(uint160(uint256(uint160(from)) & _BITMASK_ADDRESS));

        if (address(uint160(prevOwnershipPacked)) != from) _revert(TransferFromIncorrectOwner.selector);

        (uint256 approvedAddressSlot, address approvedAddress) = _getApprovedSlotAndAddress(tokenId);

        // The nested ifs save around 20+ gas over a compound boolean condition.
        if (!_isSenderApprovedOrOwner(approvedAddress, from, _msgSenderERC721A()))
            if (!isApprovedForAll(from, _msgSenderERC721A())) _revert(TransferCallerNotOwnerNorApproved.selector);

        _beforeTokenTransfers(from, to, tokenId, 1);

        // Clear approvals from the previous owner.
        assembly {
            if approvedAddress {
                // This is equivalent to `delete _tokenApprovals[tokenId]`.
                sstore(approvedAddressSlot, 0)
            }
        }

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        // Counter overflow is incredibly unrealistic as `tokenId` would have to be 2**256.
        unchecked {
            // We can directly increment and decrement the balances.
            --_packedAddressData[from]; // Updates: `balance -= 1`.
            ++_packedAddressData[to]; // Updates: `balance += 1`.

            // Updates:
            // - `address` to the next owner.
            // - `startTimestamp` to the timestamp of transfering.
            // - `burned` to `false`.
            // - `nextInitialized` to `true`.
            _packedOwnerships[tokenId] = _packOwnershipData(
                to,
                _BITMASK_NEXT_INITIALIZED | _nextExtraData(from, to, prevOwnershipPacked)
            );

            // If the next slot may not have been initialized (i.e. `nextInitialized == false`) .
            if (prevOwnershipPacked & _BITMASK_NEXT_INITIALIZED == 0) {
                uint256 nextTokenId = tokenId + 1;
                // If the next slot's address is zero and not burned (i.e. packed value is zero).
                if (_packedOwnerships[nextTokenId] == 0) {
                    // If the next slot is within bounds.
                    if (nextTokenId != _currentIndex) {
                        // Initialize the next slot to maintain correctness for `ownerOf(tokenId + 1)`.
                        _packedOwnerships[nextTokenId] = prevOwnershipPacked;
                    }
                }
            }
        }

        // Mask `to` to the lower 160 bits, in case the upper bits somehow aren't clean.
        uint256 toMasked = uint256(uint160(to)) & _BITMASK_ADDRESS;
        assembly {
            // Emit the `Transfer` event.
            log4(
                0, // Start of data (0, since no data).
                0, // End of data (0, since no data).
                _TRANSFER_EVENT_SIGNATURE, // Signature.
                from, // `from`.
                toMasked, // `to`.
                tokenId // `tokenId`.
            )
        }
        if (toMasked == 0) _revert(TransferToZeroAddress.selector);

        _afterTokenTransfers(from, to, tokenId, 1);
    }

    /**
     * @dev Equivalent to `safeTransferFrom(from, to, tokenId, '')`.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable virtual override {
        safeTransferFrom(from, to, tokenId, '');
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token
     * by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement
     * {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public payable virtual override {
        transferFrom(from, to, tokenId);
        if (to.code.length != 0)
            if (!_checkContractOnERC721Received(from, to, tokenId, _data)) {
                _revert(TransferToNonERC721ReceiverImplementer.selector);
            }
    }

    /**
     * @dev Hook that is called before a set of serially-ordered token IDs
     * are about to be transferred. This includes minting.
     * And also called before burning one token.
     *
     * `startTokenId` - the first token ID to be transferred.
     * `quantity` - the amount to be transferred.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, `from`'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, `tokenId` will be burned by `from`.
     * - `from` and `to` are never both zero.
     */
    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual {}

    /**
     * @dev Hook that is called after a set of serially-ordered token IDs
     * have been transferred. This includes minting.
     * And also called after one token has been burned.
     *
     * `startTokenId` - the first token ID to be transferred.
     * `quantity` - the amount to be transferred.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, `from`'s `tokenId` has been
     * transferred to `to`.
     * - When `from` is zero, `tokenId` has been minted for `to`.
     * - When `to` is zero, `tokenId` has been burned by `from`.
     * - `from` and `to` are never both zero.
     */
    function _afterTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual {}

    /**
     * @dev Private function to invoke {IERC721Receiver-onERC721Received} on a target contract.
     *
     * `from` - Previous owner of the given token ID.
     * `to` - Target address that will receive the token.
     * `tokenId` - Token ID to be transferred.
     * `_data` - Optional data to send along with the call.
     *
     * Returns whether the call correctly returned the expected magic value.
     */
    function _checkContractOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        try ERC721A__IERC721Receiver(to).onERC721Received(_msgSenderERC721A(), from, tokenId, _data) returns (
            bytes4 retval
        ) {
            return retval == ERC721A__IERC721Receiver(to).onERC721Received.selector;
        } catch (bytes memory reason) {
            if (reason.length == 0) {
                _revert(TransferToNonERC721ReceiverImplementer.selector);
            }
            assembly {
                revert(add(32, reason), mload(reason))
            }
        }
    }

    // =============================================================
    //                        MINT OPERATIONS
    // =============================================================

    /**
     * @dev Mints `quantity` tokens and transfers them to `to`.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `quantity` must be greater than 0.
     *
     * Emits a {Transfer} event for each mint.
     */
    function _mint(address to, uint256 quantity) internal virtual {
        uint256 startTokenId = _currentIndex;
        if (quantity == 0) _revert(MintZeroQuantity.selector);

        _beforeTokenTransfers(address(0), to, startTokenId, quantity);

        // Overflows are incredibly unrealistic.
        // `balance` and `numberMinted` have a maximum limit of 2**64.
        // `tokenId` has a maximum limit of 2**256.
        unchecked {
            // Updates:
            // - `address` to the owner.
            // - `startTimestamp` to the timestamp of minting.
            // - `burned` to `false`.
            // - `nextInitialized` to `quantity == 1`.
            _packedOwnerships[startTokenId] = _packOwnershipData(
                to,
                _nextInitializedFlag(quantity) | _nextExtraData(address(0), to, 0)
            );

            // Updates:
            // - `balance += quantity`.
            // - `numberMinted += quantity`.
            //
            // We can directly add to the `balance` and `numberMinted`.
            _packedAddressData[to] += quantity * ((1 << _BITPOS_NUMBER_MINTED) | 1);

            // Mask `to` to the lower 160 bits, in case the upper bits somehow aren't clean.
            uint256 toMasked = uint256(uint160(to)) & _BITMASK_ADDRESS;

            if (toMasked == 0) _revert(MintToZeroAddress.selector);

            uint256 end = startTokenId + quantity;
            uint256 tokenId = startTokenId;

            do {
                assembly {
                    // Emit the `Transfer` event.
                    log4(
                        0, // Start of data (0, since no data).
                        0, // End of data (0, since no data).
                        _TRANSFER_EVENT_SIGNATURE, // Signature.
                        0, // `address(0)`.
                        toMasked, // `to`.
                        tokenId // `tokenId`.
                    )
                }
                // The `!=` check ensures that large values of `quantity`
                // that overflows uint256 will make the loop run out of gas.
            } while (++tokenId != end);

            _currentIndex = end;
        }
        _afterTokenTransfers(address(0), to, startTokenId, quantity);
    }

    /**
     * @dev Mints `quantity` tokens and transfers them to `to`.
     *
     * This function is intended for efficient minting only during contract creation.
     *
     * It emits only one {ConsecutiveTransfer} as defined in
     * [ERC2309](https://eips.ethereum.org/EIPS/eip-2309),
     * instead of a sequence of {Transfer} event(s).
     *
     * Calling this function outside of contract creation WILL make your contract
     * non-compliant with the ERC721 standard.
     * For full ERC721 compliance, substituting ERC721 {Transfer} event(s) with the ERC2309
     * {ConsecutiveTransfer} event is only permissible during contract creation.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `quantity` must be greater than 0.
     *
     * Emits a {ConsecutiveTransfer} event.
     */
    function _mintERC2309(address to, uint256 quantity) internal virtual {
        uint256 startTokenId = _currentIndex;
        if (to == address(0)) _revert(MintToZeroAddress.selector);
        if (quantity == 0) _revert(MintZeroQuantity.selector);
        if (quantity > _MAX_MINT_ERC2309_QUANTITY_LIMIT) _revert(MintERC2309QuantityExceedsLimit.selector);

        _beforeTokenTransfers(address(0), to, startTokenId, quantity);

        // Overflows are unrealistic due to the above check for `quantity` to be below the limit.
        unchecked {
            // Updates:
            // - `balance += quantity`.
            // - `numberMinted += quantity`.
            //
            // We can directly add to the `balance` and `numberMinted`.
            _packedAddressData[to] += quantity * ((1 << _BITPOS_NUMBER_MINTED) | 1);

            // Updates:
            // - `address` to the owner.
            // - `startTimestamp` to the timestamp of minting.
            // - `burned` to `false`.
            // - `nextInitialized` to `quantity == 1`.
            _packedOwnerships[startTokenId] = _packOwnershipData(
                to,
                _nextInitializedFlag(quantity) | _nextExtraData(address(0), to, 0)
            );

            emit ConsecutiveTransfer(startTokenId, startTokenId + quantity - 1, address(0), to);

            _currentIndex = startTokenId + quantity;
        }
        _afterTokenTransfers(address(0), to, startTokenId, quantity);
    }

    /**
     * @dev Safely mints `quantity` tokens and transfers them to `to`.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement
     * {IERC721Receiver-onERC721Received}, which is called for each safe transfer.
     * - `quantity` must be greater than 0.
     *
     * See {_mint}.
     *
     * Emits a {Transfer} event for each mint.
     */
    function _safeMint(
        address to,
        uint256 quantity,
        bytes memory _data
    ) internal virtual {
        _mint(to, quantity);

        unchecked {
            if (to.code.length != 0) {
                uint256 end = _currentIndex;
                uint256 index = end - quantity;
                do {
                    if (!_checkContractOnERC721Received(address(0), to, index++, _data)) {
                        _revert(TransferToNonERC721ReceiverImplementer.selector);
                    }
                } while (index < end);
                // Reentrancy protection.
                if (_currentIndex != end) _revert(bytes4(0));
            }
        }
    }

    /**
     * @dev Equivalent to `_safeMint(to, quantity, '')`.
     */
    function _safeMint(address to, uint256 quantity) internal virtual {
        _safeMint(to, quantity, '');
    }

    // =============================================================
    //                       APPROVAL OPERATIONS
    // =============================================================

    /**
     * @dev Equivalent to `_approve(to, tokenId, false)`.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _approve(to, tokenId, false);
    }

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the
     * zero address clears previous approvals.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function _approve(
        address to,
        uint256 tokenId,
        bool approvalCheck
    ) internal virtual {
        address owner = ownerOf(tokenId);

        if (approvalCheck && _msgSenderERC721A() != owner)
            if (!isApprovedForAll(owner, _msgSenderERC721A())) {
                _revert(ApprovalCallerNotOwnerNorApproved.selector);
            }

        _tokenApprovals[tokenId].value = to;
        emit Approval(owner, to, tokenId);
    }

    // =============================================================
    //                        BURN OPERATIONS
    // =============================================================

    /**
     * @dev Equivalent to `_burn(tokenId, false)`.
     */
    function _burn(uint256 tokenId) internal virtual {
        _burn(tokenId, false);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId, bool approvalCheck) internal virtual {
        uint256 prevOwnershipPacked = _packedOwnershipOf(tokenId);

        address from = address(uint160(prevOwnershipPacked));

        (uint256 approvedAddressSlot, address approvedAddress) = _getApprovedSlotAndAddress(tokenId);

        if (approvalCheck) {
            // The nested ifs save around 20+ gas over a compound boolean condition.
            if (!_isSenderApprovedOrOwner(approvedAddress, from, _msgSenderERC721A()))
                if (!isApprovedForAll(from, _msgSenderERC721A())) _revert(TransferCallerNotOwnerNorApproved.selector);
        }

        _beforeTokenTransfers(from, address(0), tokenId, 1);

        // Clear approvals from the previous owner.
        assembly {
            if approvedAddress {
                // This is equivalent to `delete _tokenApprovals[tokenId]`.
                sstore(approvedAddressSlot, 0)
            }
        }

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        // Counter overflow is incredibly unrealistic as `tokenId` would have to be 2**256.
        unchecked {
            // Updates:
            // - `balance -= 1`.
            // - `numberBurned += 1`.
            //
            // We can directly decrement the balance, and increment the number burned.
            // This is equivalent to `packed -= 1; packed += 1 << _BITPOS_NUMBER_BURNED;`.
            _packedAddressData[from] += (1 << _BITPOS_NUMBER_BURNED) - 1;

            // Updates:
            // - `address` to the last owner.
            // - `startTimestamp` to the timestamp of burning.
            // - `burned` to `true`.
            // - `nextInitialized` to `true`.
            _packedOwnerships[tokenId] = _packOwnershipData(
                from,
                (_BITMASK_BURNED | _BITMASK_NEXT_INITIALIZED) | _nextExtraData(from, address(0), prevOwnershipPacked)
            );

            // If the next slot may not have been initialized (i.e. `nextInitialized == false`) .
            if (prevOwnershipPacked & _BITMASK_NEXT_INITIALIZED == 0) {
                uint256 nextTokenId = tokenId + 1;
                // If the next slot's address is zero and not burned (i.e. packed value is zero).
                if (_packedOwnerships[nextTokenId] == 0) {
                    // If the next slot is within bounds.
                    if (nextTokenId != _currentIndex) {
                        // Initialize the next slot to maintain correctness for `ownerOf(tokenId + 1)`.
                        _packedOwnerships[nextTokenId] = prevOwnershipPacked;
                    }
                }
            }
        }

        emit Transfer(from, address(0), tokenId);
        _afterTokenTransfers(from, address(0), tokenId, 1);

        // Overflow not possible, as _burnCounter cannot be exceed _currentIndex times.
        unchecked {
            _burnCounter++;
        }
    }

    // =============================================================
    //                     EXTRA DATA OPERATIONS
    // =============================================================

    /**
     * @dev Directly sets the extra data for the ownership data `index`.
     */
    function _setExtraDataAt(uint256 index, uint24 extraData) internal virtual {
        uint256 packed = _packedOwnerships[index];
        if (packed == 0) _revert(OwnershipNotInitializedForExtraData.selector);
        uint256 extraDataCasted;
        // Cast `extraData` with assembly to avoid redundant masking.
        assembly {
            extraDataCasted := extraData
        }
        packed = (packed & _BITMASK_EXTRA_DATA_COMPLEMENT) | (extraDataCasted << _BITPOS_EXTRA_DATA);
        _packedOwnerships[index] = packed;
    }

    /**
     * @dev Called during each token transfer to set the 24bit `extraData` field.
     * Intended to be overridden by the cosumer contract.
     *
     * `previousExtraData` - the value of `extraData` before transfer.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, `from`'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, `tokenId` will be burned by `from`.
     * - `from` and `to` are never both zero.
     */
    function _extraData(
        address from,
        address to,
        uint24 previousExtraData
    ) internal view virtual returns (uint24) {}

    /**
     * @dev Returns the next extra data for the packed ownership data.
     * The returned result is shifted into position.
     */
    function _nextExtraData(
        address from,
        address to,
        uint256 prevOwnershipPacked
    ) private view returns (uint256) {
        uint24 extraData = uint24(prevOwnershipPacked >> _BITPOS_EXTRA_DATA);
        return uint256(_extraData(from, to, extraData)) << _BITPOS_EXTRA_DATA;
    }

    // =============================================================
    //                       OTHER OPERATIONS
    // =============================================================

    /**
     * @dev Returns the message sender (defaults to `msg.sender`).
     *
     * If you are writing GSN compatible contracts, you need to override this function.
     */
    function _msgSenderERC721A() internal view virtual returns (address) {
        return msg.sender;
    }

    /**
     * @dev Converts a uint256 to its ASCII string decimal representation.
     */
    function _toString(uint256 value) internal pure virtual returns (string memory str) {
        assembly {
            // The maximum value of a uint256 contains 78 digits (1 byte per digit), but
            // we allocate 0xa0 bytes to keep the free memory pointer 32-byte word aligned.
            // We will need 1 word for the trailing zeros padding, 1 word for the length,
            // and 3 words for a maximum of 78 digits. Total: 5 * 0x20 = 0xa0.
            let m := add(mload(0x40), 0xa0)
            // Update the free memory pointer to allocate.
            mstore(0x40, m)
            // Assign the `str` to the end.
            str := sub(m, 0x20)
            // Zeroize the slot after the string.
            mstore(str, 0)

            // Cache the end of the memory to calculate the length later.
            let end := str

            // We write the string from rightmost digit to leftmost digit.
            // The following is essentially a do-while loop that also handles the zero case.
            // prettier-ignore
            for { let temp := value } 1 {} {
                str := sub(str, 1)
                // Write the character to the pointer.
                // The ASCII index of the '0' character is 48.
                mstore8(str, add(48, mod(temp, 10)))
                // Keep dividing `temp` until zero.
                temp := div(temp, 10)
                // prettier-ignore
                if iszero(temp) { break }
            }

            let length := sub(end, str)
            // Move the pointer 32 bytes leftwards to make room for the length.
            str := sub(str, 0x20)
            // Store the length.
            mstore(str, length)
        }
    }

    /**
     * @dev For more efficient reverts.
     */
    function _revert(bytes4 errorSelector) internal pure {
        assembly {
            mstore(0x00, errorSelector)
            revert(0x00, 0x04)
        }
    }
}

// File: ContractEnkardia/ContractEnkardia/Carrotz.sol


pragma solidity ^0.8;







contract CarrotzContract is ERC721A, ERC2981, DefaultOperatorFilterer, Ownable {
    using SafeMath for uint256;
    using Strings for uint256;

    // Constants
    uint256 public constant MAX_MINT_WHITELIST = 10;
    uint256 public constant MAX_MINT_PUBLIC = 20;
    uint256 public constant FREE_MINT_WHITELIST = 1;
    uint256 public constant FREE_MINT_PUBLIC = 2;
    uint256 public constant MINT_PRICE_WHITELIST = 0.015 ether;
    uint256 public constant MINT_PRICE_PUBLIC = 0.02 ether;
    uint256 public constant MAX_SUPPLY = 2000;
    uint256 public constant FREE_SUPPLY = 500;
    string public constant BASE_EXTENSION = ".json";
    string public constant BASE_URI = "ipfs://QmSwRo6ddmkzxZd5qkczzaE7ibAiioCkm9wF6YqgRaaJH9/";

    // Variables
    uint256 public publicOpen;
    uint256 public wlOpen;
    mapping(address => uint256) public mintedFree;
    mapping(address => uint256) public mintedPaid;
    mapping(address => bool) public whitelist;
    uint256 public totalFreeMinted;
    uint256 public totalPaidMinted;
    bool public teamMinted;

    constructor() ERC721A("The Carrotz", "The Carrotz") {
        _setDefaultRoyalty(msg.sender, 500);
        wlOpen = 1687870800; // 27th 1pm
        publicOpen = wlOpen + 6 hours;
    }
    
    function mint(uint256 _amount) public payable {
        require(totalFreeMinted.add(totalPaidMinted).add(_amount) <= MAX_SUPPLY, "Exceeds max supply");
        require(block.timestamp >= wlOpen, "Minting not open yet");

        uint256 cost;
        uint256 amountToPay = _amount;
        uint256 freeToMint = 0;

        if (totalFreeMinted < FREE_SUPPLY) {
            uint256 freeAmount;
            
            if (block.timestamp < publicOpen && whitelist[msg.sender]) {
                freeAmount = FREE_MINT_WHITELIST;
            } else {
                freeAmount = FREE_MINT_PUBLIC;
            }

            freeAmount = freeAmount > mintedFree[msg.sender] ? freeAmount - mintedFree[msg.sender] : 0;
            freeToMint = freeAmount > _amount ? _amount : freeAmount;
            amountToPay = _amount.sub(freeToMint);
        }

        if (block.timestamp < publicOpen) {
            require(whitelist[msg.sender], "Not in whitelist");
            require(mintedPaid[msg.sender].add(amountToPay) <= MAX_MINT_WHITELIST, "Exceeds max mint for whitelist");
            cost = MINT_PRICE_WHITELIST.mul(amountToPay);
        } else {
            require(mintedPaid[msg.sender].add(amountToPay) <= MAX_MINT_PUBLIC, "Exceeds max mint for public");
            cost = MINT_PRICE_PUBLIC.mul(amountToPay);
        }

        require(msg.value >= cost, "Insufficient ETH sent for mint");

        mintedFree[msg.sender] = mintedFree[msg.sender].add(freeToMint);
        totalFreeMinted = totalFreeMinted.add(freeToMint);
        mintedPaid[msg.sender] = mintedPaid[msg.sender].add(amountToPay);
        totalPaidMinted = totalPaidMinted.add(amountToPay);

        // Transfer the Ether to the contract owner
        if (msg.value > 0) {
            payable(owner()).transfer(msg.value);
        }
        
        _mint(msg.sender, _amount);
    }

    function mint23Team() external onlyOwner {
        require(teamMinted == false);
        _mint(owner(), 23);
        teamMinted = true;
    }

    function getMintInfo(uint256 _desiredAmount, address _minter) public view returns (uint256 cost, uint256 maxAmount) {
        cost = 0;
        maxAmount = 0;

        if (totalFreeMinted.add(totalPaidMinted).add(_desiredAmount) <= MAX_SUPPLY && block.timestamp >= wlOpen) {
            uint256 amountToPay = _desiredAmount;
            uint256 freeToMint = 0;
            uint256 freeAmount = 0;

            if (totalFreeMinted < FREE_SUPPLY) {
                if (block.timestamp < publicOpen && whitelist[_minter]) {
                    freeAmount = FREE_MINT_WHITELIST;
                } else if (block.timestamp >= publicOpen) {
                    freeAmount = FREE_MINT_PUBLIC;
                }

                freeAmount = freeAmount > mintedFree[_minter] ? freeAmount - mintedFree[_minter] : 0;
                freeToMint = freeAmount > _desiredAmount ? _desiredAmount : freeAmount;
                amountToPay = _desiredAmount.sub(freeToMint);
            }

            if (block.timestamp < publicOpen && whitelist[_minter]) {
                if (mintedPaid[_minter].add(amountToPay) <= MAX_MINT_WHITELIST) {
                    cost = MINT_PRICE_WHITELIST.mul(amountToPay);
                    maxAmount = freeToMint.add(amountToPay);
                } else {
                    maxAmount = freeToMint.add(MAX_MINT_WHITELIST - mintedPaid[_minter]);
                    cost = MINT_PRICE_WHITELIST.mul(MAX_MINT_WHITELIST - mintedPaid[_minter]);
                }
            } else if (block.timestamp >= publicOpen) {
                if (mintedPaid[_minter].add(amountToPay) <= MAX_MINT_PUBLIC) {
                    cost = MINT_PRICE_PUBLIC.mul(amountToPay);
                    maxAmount = freeToMint.add(amountToPay);
                } else {
                    maxAmount = freeToMint.add(MAX_MINT_PUBLIC - mintedPaid[_minter]);
                    cost = MINT_PRICE_PUBLIC.mul(MAX_MINT_PUBLIC - mintedPaid[_minter]);
                }
            }
        }

        return (cost, maxAmount);
    }

    function addToWhitelist(address[] calldata addressList) external onlyOwner {
        for (uint i = 0; i < addressList.length; i++) {
            whitelist[addressList[i]] = true;
        }
    }

    function removeFromWhitelist(address[] calldata addressList) external onlyOwner {
        for (uint i = 0; i < addressList.length; i++) {
            delete whitelist[addressList[i]];
        }
    }

    function emergencyOpenMint() external onlyOwner {
        wlOpen = block.timestamp;
        publicOpen = wlOpen + 6 hours;
    }

    function emergencyOpenFcfs() external onlyOwner {
        publicOpen = block.timestamp;
        wlOpen = publicOpen - 6 hours;
    }

    function mintState() view external returns(uint state) {
        if (block.timestamp < wlOpen) state = 0;
        else if (block.timestamp >= wlOpen && block.timestamp < publicOpen) state = 1;
        else if (block.timestamp >= publicOpen) state = 2;
        return state;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(_exists(_tokenId), "Token does not exist!");

        return
            string(
                abi.encodePacked(
                    BASE_URI,
                    _tokenId.toString(),
                    BASE_EXTENSION
                )
            );
    }

    // OpenSea Enforcer functions
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }
    
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC721A, ERC2981) returns (bool) {
        return 
            ERC721A.supportsInterface(interfaceId) || 
            ERC2981.supportsInterface(interfaceId);
    }

    function initWl() internal {
        whitelist[0xf03A4C89A8D14ACA07C62479cBdDde753ad6233b] = true;
        whitelist[0xCcCb76953089072DF94C15762dF81Ad4786aa2Db] = true;
        whitelist[0x2B1f2858fCE17213B46b52ae8d308a5fD1BE3b24] = true;
        whitelist[0x37BC058f6eb74F6f77bAB2C88E02f4535777344c] = true;
        whitelist[0xfDA5498583cBf5B9982a9d4563745e9b0cE74aBC] = true;
        whitelist[0x172bFF9DE0356749a074114393478455dcEb1dDd] = true;
        whitelist[0xf910a209C0686f76200bFA1Fb01037c1F8FbbA7D] = true;
        whitelist[0x8D17a220f9EBE8BeE396E601Af4fc47743c409d0] = true;
        whitelist[0x977b69AC9B5eB664C1B7f12D736aEb51C2e64Cd1] = true;
        whitelist[0x23A7494fEdf00619cfb7423960b58B9B01150537] = true;
        whitelist[0xA6740EC280dca36E05e691b3229A59e4ed9Ea4af] = true;
        whitelist[0x34Ca227D0a9fe241289b0C3861a61Ecb5d0e8e88] = true;
        whitelist[0xbF559099Bc938A9114cae01E1208b9751C404343] = true;
        whitelist[0x3928FA28AB3456B9b74E04156a0327bCB6b14D56] = true;
        whitelist[0x253C042f709e568E7bF599046a026eC7a6d5dd47] = true;
        whitelist[0xA614E340B46c347296F9F680Ea1fD1Ba125192De] = true;
        whitelist[0x95Ca3e4F428a867fccfdcdedDd2ba79d9238E7B0] = true;
        whitelist[0x0D8B49bE1176b7c9436167A4FaA2C0F8547Aa7E7] = true;
        whitelist[0x9f13A6aE7D3F5F7ee5CC232d398F543aCf078F26] = true;
        whitelist[0xe4b2da70c752671dff9f0644967Cde041AD0e6Af] = true;
        whitelist[0xD5CD998e0268e0C5E8Ba7736781C6E1494FCc07d] = true;
        whitelist[0x74E94A88D6FC23Efcf571E90B14EE290915802bF] = true;
        whitelist[0x1F312652201D5425C24322139Be39f1bbDcFAc69] = true;
        whitelist[0x356C9915BF8711B2d8D14e91BbdDD4BD3Ea14A58] = true;
        whitelist[0xcA53c086b4c6e9b69ab162634bF1c52028522531] = true;
        whitelist[0x008DBA3dE3A8b4654bf74D536FE4BE8f1311ddb8] = true;
        whitelist[0xD56181DfA8C833fDb4c545301154DEe70d783653] = true;
        whitelist[0xFD1c6c3105352C8e6E61eb20F9c9DA99e301ADC6] = true;
        whitelist[0xBe17431D4FBb36e7A24b9026AA07E41D368233CB] = true;
        whitelist[0x332b4a450c0262A5B0d6dB7E0336899F4ddf9947] = true;
        whitelist[0xC38e07206018140040c940A8cb4102E76C23CB16] = true;
        whitelist[0xD100a6f2723A9c2f0b833CE4B35023D9C63E1545] = true;
        whitelist[0x477DbEC58BAd6f6318ca70AFF2d9953BA3b4dCbb] = true;
        whitelist[0x0290bAd3Dc58Aa95AAC7E165E0999FE2A1a047A1] = true;
        whitelist[0x3d4FbAC05963165cD00aa4F500dC77638F29359c] = true;
        whitelist[0xe68e795EF44052C489ce570BA6572358d5C6680f] = true;
        whitelist[0x38504f61fD97f0917cF6685F6519942E0fD6d926] = true;
        whitelist[0x50AF4A1c782b6c68aEB5bCe6eeC5fBf30A769D6E] = true;
        whitelist[0xc4962D1D85e2e9ca3d5380390FBF2382a87b32D4] = true;
        whitelist[0x3D6bf109B1CbA1c626c01Aa737CA3DCde6F46Bf1] = true;
        whitelist[0xdC96ec380093a9dEA62636944A6c0f509A5d641D] = true;
        whitelist[0xAd44D11ef8019adC52F46443F0a27098Ad086486] = true;
        whitelist[0x80058Aa95daB107D79f600E6131a1FD00B262105] = true;
        whitelist[0x18eAB583B9a4cc805359c814da65C8C412C22ba6] = true;
        whitelist[0x9B9e1b73d7346286520a3dDb36dD6e530dB1537E] = true;
        whitelist[0x7F3bee8Ed460d3c8F1BB7dF37d43e1c4bC0E4159] = true;
        whitelist[0x0794CefCDb136e160c884DF8e134fc294503a504] = true;
        whitelist[0xEe7978D41462D23d785A020e948A48926271A870] = true;
        whitelist[0x43b45cA3aC8DC9FF7bf4EbdF824d75760EFE9d07] = true;
        whitelist[0xc611aC187751E6792A5c548bfCF80F9c1A15A50D] = true;
        whitelist[0x656211f6eC16B75c1cd6F423c0134ad141f0C5d6] = true;
        whitelist[0xE85DBB09A699c0543C363c3f6E51ef0049e3edC5] = true;
        whitelist[0x59C7602dFf791B5eC0348Cc0F6bDB73066De34E7] = true;
        whitelist[0xFBD99A273f18714c3893708A47b796a7ed6CBD4f] = true;
        whitelist[0x21C6baBB004E9aAa33d368ba227602686DEFed3C] = true;
        whitelist[0x997D22170e91Cc91Fcb3F52AF677E486816e7364] = true;
        whitelist[0xb9A17e131aB04B680Cd05dBc33A7E324A8D5e894] = true;
        whitelist[0x737FEfc91A4E1f7cdA843880AA285C4E8A9EF7E0] = true;
        whitelist[0x215DDCe5d1d12D26861d608858a213e749584657] = true;
        whitelist[0xb991175200A225f124C7BB820751411144D03552] = true;
        whitelist[0x0A76658Cdf816a572AE1883217D1d0ee546725C1] = true;
        whitelist[0xF95e8785CA65e6ac36da484c9507B78E427De453] = true;
        whitelist[0x019Aa3358AD5a788CcB6393d3Bd9fbc990414054] = true;
        whitelist[0xa4C45893F095F9DA82AcD9B52Fa16a7Eb947B02c] = true;
        whitelist[0x4C1a3AA19BecFc7bA64878045e42dd06167Dc699] = true;
        whitelist[0x5d7cbDB9adb0d3FE3651845DeD0433f90bAbe055] = true;
        whitelist[0x918B1Fae44b01AdaFB76e620d91DCB884a08f5F9] = true;
        whitelist[0xa03D83048Db96CfE9ee0c288689F7A07b85a2AD2] = true;
        whitelist[0xD0e8C95Ee57694e1B105907B89c05b7171A92692] = true;
        whitelist[0xf6c2997ffF7affe4A7601988539089Ce3af9DAAe] = true;
        whitelist[0x99dFe8F8574D00c31d1543C7549A731129461113] = true;
        whitelist[0x4Bb8Ee32aac8b538b193333e58Ca3816cC7671cD] = true;
        whitelist[0xc6579463baB5BCB90a9635bef91CcAa78fFFD7b1] = true;
        whitelist[0xBbcF026F909fE2eCE5689e136F050F38fC4b472e] = true;
        whitelist[0x64bde4b06ccca328d76D47D7B2b4c54f94922A6c] = true;
        whitelist[0xC6779f81e6E1C8626A7a83220A67f0BaDda9115f] = true;
        whitelist[0x3A8A085e9362084E1c71d937a4c3fE664E7832Bc] = true;
        whitelist[0xd92e2f8C08fb61D3c2191C435735a3cddF7e013C] = true;
        whitelist[0xD63b1828B35D1F4075Aa7F8a32D69c87795AA8D1] = true;
        whitelist[0xEC225a1Fd31603790f5125Ab5621E80D8047E901] = true;
        whitelist[0x5FC2E9c6E1F32FcbFDdf5BDCd7cb9AF59bdC9b4B] = true;
        whitelist[0xddF6De3A7eCF342Fa3Af23a1A796829a5E3AFc93] = true;
        whitelist[0x7fC4Caa51e07cC7E25e34314e9881e88616E9E37] = true;
        whitelist[0x39D53165b15a67AA82D7Ed2c0AaD47A43a318fa6] = true;
        whitelist[0x0Edfa76A60D989B8911C8E9E949a9854B0607fE5] = true;
        whitelist[0x0705f087FB70C784094Ac6482a38AbA82a73Aca7] = true;
        whitelist[0x8d4028c2FB187452ce49A69514f0AD51ebc5c19b] = true;
        whitelist[0x47EaEc8cA6DDb250544F6185EA8503EDc93a834A] = true;
        whitelist[0xFD7A8935EcE990f06304E38EeAeA647feF07eBD4] = true;
        whitelist[0x50C2618D13f34E62375f5EED5336FefC3581fdA8] = true;
        whitelist[0x54450EDf860Df79347a202866E880C689d364e80] = true;
        whitelist[0x0A4E5cA0F6681ca903D736d589Cfb3Fc6aC08F35] = true;
        whitelist[0x4A69c3a1DA84c23661EBEcB12Df3318cfb8bBcdE] = true;
        whitelist[0x81D42EC28DBb33F3583038195CaF1f44DC1c8753] = true;
        whitelist[0x5D60886a6018088DbE8ff85E6B438ae409C7D193] = true;
        whitelist[0x5Aa889B6d4A447bCCDec25A5bDeA4f6e3755E863] = true;
        whitelist[0xDeaD9F6D2208b6Da3Db0E5CdEC8814a098D44199] = true;
        whitelist[0xCdfb83642Eb801d05e77302BD919De5f92C21ED5] = true;
        whitelist[0x3Ab62BaFACbb8030CCa852924b41aD3aF7919a41] = true;
        whitelist[0xfBb210aB20a551fBC6Eb062F85bcF30040797D44] = true;
        whitelist[0x0D4Cc1bccBAF2481155a3e6f54b6743dB9ec39E6] = true;
        whitelist[0x4b3757B48F70bF8Ff9D6474381e43DFECF9D5BA9] = true;
        whitelist[0x56f9f1efa72E1E4BA56E74574d45C5A43624960A] = true;
        whitelist[0x8fd5a8d39229e66321c78B0F0A806717C265d80e] = true;
        whitelist[0xF08C2C228c488815ae500BD7D0F98dD1E8c49Fab] = true;
        whitelist[0x7a3741108217319DC6958827FDe572AF213dE41e] = true;
        whitelist[0x3C23975c937d880d9B601F7FF674e7bF14a8359F] = true;
        whitelist[0x1d4E93a8a6299051472D618b45bE9F333951F7AE] = true;
        whitelist[0x5d571d126F427aF40aeABe434DD6CF0aA487c0A4] = true;
        whitelist[0x144c02f5370Be541e123Fa5cF9083E30Ab7c5a04] = true;
        whitelist[0xbDf3DFF1090194Db81ad03D65b07D5842cE220b9] = true;
        whitelist[0x3bcf3426692A406032D271dA0E050f665B4b3F67] = true;
        whitelist[0xF13d63c10e9Ee31F2E26101B95fA44af072cB8a1] = true;
        whitelist[0x28156730f1F2f588fcc3e9ED2f5793CAD354282c] = true;
        whitelist[0x55eb72F2A5694aee534B8dd2cf7ea1F8bAe584C5] = true;
        whitelist[0xB7b2297Ccb4b921deB22F4e43d7EbddE7A0a4d45] = true;
        whitelist[0x640F2499Aa01755116516bc82F84c72357BB3E1a] = true;
        whitelist[0x84334B7170376b36C7cc2214da1c304682c8d83f] = true;
        whitelist[0x97D722875D270aC502071d52869E8D05deB58cBB] = true;
        whitelist[0x2F6Bb93b36CD91C1969d24F783C038C1537f0e30] = true;
        whitelist[0x9F2F290a213c9970C693AA23aE96c27dFE879Adb] = true;
        whitelist[0x2e9a2A5e91FEdC88d3550D815F5907006e93A008] = true;
        whitelist[0x9659D4698b3a66c135e4BdD8Be06d84C889154fF] = true;
        whitelist[0xE2155675D790a6A4B9a460862ae9a0b26305eaeF] = true;
        whitelist[0x2f98f2D97A571591197232D04f8B4989755599FF] = true;
        whitelist[0xfc6b6862Ef4E88a899AC03a0513EBF33e80Cd432] = true;
        whitelist[0xDba797B6a5c14Bff9eD3753Ecb38c92c7E86A2d6] = true;
        whitelist[0x55FcCBc6c3164692e5a8A62cc5f9CA4e40CAf57F] = true;
        whitelist[0xc8915E6eB2Ce78d2818606DF6D74605F3C3418c4] = true;
        whitelist[0x86fB98Cef52a02bBeF066B21a1BCEFD6DB235039] = true;
        whitelist[0xbcd562d5743Ad1F97da6DEea093461CCcd344F10] = true;
        whitelist[0xfF032987AFB855B302c7678Ec36FbF312d268F7b] = true;
        whitelist[0x950c589C8fD106790F877A93C3ca339948C5d68c] = true;
        whitelist[0x4B90c639cFAe70d715a0F6ab96253A9A8f5b862E] = true;
        whitelist[0x12Bb206124930a2533F9147f2f134a5372EA5b91] = true;
        whitelist[0x2438a0F10518C5E2262C5eb9f8A4476692e0EeCd] = true;
        whitelist[0xfd829521010D0FE2Dd1D203F867549ef827aEF2D] = true;
        whitelist[0x1a13b044B9bC01b19072661A4CD63bd20FEC3687] = true;
        whitelist[0x38151BEB36276CDb25bA044F72d2FFA1539f88dc] = true;
        whitelist[0xde197FFd6ba7F264Ba7Cdf016E48c4dbdf782064] = true;
        whitelist[0x0Dffa0D8f5e3B7Ed53b9d11C3789dA2BE46758Ea] = true;
        whitelist[0xD7F2a6ad9d6D407842Da01eC5B81D8646C8C87B5] = true;
        whitelist[0x923Ada6487AaE22bC1f12027618A2A6DeE645DA5] = true;
        whitelist[0x4C8455351ABC38391fB9D06CeCca87E429E81F86] = true;
        whitelist[0x0e8F71c94F6eBf2949f1fb65a579b94200a75d6A] = true;
        whitelist[0x4c70c0ce91602Db64Ab86d522439a68e1A981b23] = true;
        whitelist[0xa40Cd8AC5d59b78ae5786DACF9Ff16a7712F645E] = true;
        whitelist[0xaA0CD688DF3bB2e501165cFF07c9dCE683dE0b88] = true;
        whitelist[0xc5555798C0F46016280B62871a879a13064D2336] = true;
        whitelist[0xDb075017593060427b729A50daD132004bc402EA] = true;
        whitelist[0xc486F7eF93C1961374186129077a0230116d8Db8] = true;
        whitelist[0xbA282a20d32248680003DFC1ED8168CBe0B41Fa4] = true;
        whitelist[0x13214c6DFE518592c970A1B36E1A844996FD4C33] = true;
        whitelist[0x94f604e11683eB2e39180DDDC64094698D7579B1] = true;
        whitelist[0xD81cCC0c14FCCbF9111bA030652aE45a1b85c13E] = true;
        whitelist[0x5C70633b8b78326F0A587528590Eb1cfFBe76eeE] = true;
        whitelist[0x5B90400667fB6e6f7952ebb44cdC074f95d8177f] = true;
        whitelist[0xc123Cc025Cb7bed2d8d258D6E005780D3Cb2629A] = true;
        whitelist[0x53dA3Df491c3F648b74c8DC459E8fb9Cf0841EFE] = true;
        whitelist[0xcada6C66116458be3cFE4157477e2b7013DB9Bc8] = true;
        whitelist[0x8B4A4c7Ffd3116e2DBa4af91EEc78c0722548E20] = true;
        whitelist[0xdb21bDF8EBF4Ee33dA75B922A260cFF0B85FE3C2] = true;
        whitelist[0x4f6bCEffCB3B3Abfd5873109a5F7088E4A7D93Af] = true;
        whitelist[0x6c4AEC5EA9e714a7Be23fb9e60BAedEE093b5c47] = true;
        whitelist[0x3D49DB743505E9cC8068bb2974672867C47545eA] = true;
        whitelist[0xfFf049824fd1ecDfbA1C9Fd2da125EA0c3eC9AaE] = true;
        whitelist[0x115A8DBA086A865ACC49AFFc8bf5299Fcac72fD4] = true;
        whitelist[0x77eDcc641D9cF3d8F3bFdE9a059EB0dAFe879790] = true;
        whitelist[0x568c50Fd91F1b7E56C810D314DEb5368e72EDd9e] = true;
        whitelist[0x44941809D2FfaA9099B94409FEFC89B16A0F45b0] = true;
        whitelist[0xeb17ED1d341bc61A2cB82751E14825975920E359] = true;
        whitelist[0x31494f0dC9D8B10e3a604E5E8A6B0E3535EFfe6a] = true;
        whitelist[0xC2BBfA869877B8Bf2AEbaC55f3881BAb21a21542] = true;
        whitelist[0xa57ABf3cfd0E9722eD712e782f12D4ce146aeFE7] = true;
        whitelist[0x18127166DD88A9C75f33BB85209597d0bD785967] = true;
        whitelist[0xD7ff2D1588d47cDcECe05E33968a84a6BDC2fEb1] = true;
        whitelist[0x862fD8Ba75d6858DA149EAE01Fa9f3DE7765527a] = true;
        whitelist[0xDb59dd5A1e02645908746fd4Dac69734A8559f6E] = true;
        whitelist[0x27Bbb4f42BdE862ff9Df700CECD43F634E0b5e9B] = true;
        whitelist[0x4B52Bcc4b49A94048E959BFacEcE0A961F7693d0] = true;
        whitelist[0xca2666880926d4Fc298e474F7e66d53B39fF4757] = true;
        whitelist[0xB85Bb5596AC087dD1cB03A2F9947833710135C4b] = true;
        whitelist[0x5D7a5bdA784aBA8AB48396EEEf9F3381250Cd65E] = true;
        whitelist[0xa222eE471990a559C1F46Bc874F373acFa32e6e9] = true;
        whitelist[0x6Ef966c37BB3d5f4Ac162f4EDFB27f3Ce729E419] = true;
        whitelist[0x75F5f17406e5eCeE8FFCf8011BB4cC6f4DD46eD3] = true;
        whitelist[0xb74dE96D154CC700a76025ab0F2c11a97E3fBc4E] = true;
        whitelist[0x4306E0b1f2DE74F6B94E0d2e1b0d7f5c45b67fC9] = true;
        whitelist[0x50eA3f87875Fcc6f5670FaEa69Ae45d0CD3C649d] = true;
        whitelist[0xd7B0281a96E3F309564F6c3Addf0B3852A5E9622] = true;
        whitelist[0x955FC5cC4c0Cc2E255d1693b91a3e0Eff5da4F03] = true;
        whitelist[0xf6F78237f48B541656e7c6312253F4743188861F] = true;
        whitelist[0x69b418E8eF7471EEf7a80245B87a14eAC52a6B28] = true;
        whitelist[0xEBA79C8902D1C18a87603E339f3d45eBc6CF1817] = true;
        whitelist[0xE6C986f4A4B32c73aE73110b9812Cf43F7836EFB] = true;
        whitelist[0x4b67EC0BF2fe540CD4014b4D0938d6a14EEB577B] = true;
        whitelist[0x1a0BbabFB78D065ba2Ffa964630B13d4A7b8e283] = true;
        whitelist[0xBb6b7D9cF93d6Ad37A851445974960be2e236403] = true;
        whitelist[0x2247FABd537Ddb0CcfF67196CB573aaeAC02ed70] = true;
        whitelist[0x494f8965639cf305ea30dB7371c9cD8173E37EA6] = true;
        whitelist[0x373a15E17e21475c2EA1FEbD1F22191bf6Ac3b40] = true;
        whitelist[0x08D496C9cF496dA6333819f24b691EC04Da830f0] = true;
        whitelist[0x312D2e7dF6Bf07B592d4Aa7F3BC8BD011a68A8cB] = true;
        whitelist[0x646d83Ba1840dB6D100E455Fc5602367838DF4e3] = true;
        whitelist[0xe44D61473e3816DEA491Df3797167988D1A22Fd2] = true;
        whitelist[0x71FB19fd5791699e95032A0ddF8F482261a095b4] = true;
        whitelist[0x162382a00A826c8FaAdEf9875e67D3233768cB31] = true;
        whitelist[0x88d697dE90889596F624F9bBfA144CB8C4eCA676] = true;
        whitelist[0xf96A186195262f85928880D6bc1cc5Dd22ceaf42] = true;
        whitelist[0xe59E036dE50CD81509E28B6C2a7fAc7e3346fA68] = true;
        whitelist[0x63eC40ffD185e7DE69f0922478f3Ad98cbeeDE9A] = true;
        whitelist[0xAE8AD72b10b606BA38d01E816527A23c5b069509] = true;
        whitelist[0xF7e25D8B3791E9C2b9D5e6190b3F444BC4b0E80B] = true;
        whitelist[0x43eEa2E44f23524F4D573B3E98C6D471a84CefA2] = true;
        whitelist[0x2260909Cbd5d5e4Fac768c738fAf163f425b48DF] = true;
        whitelist[0x219895b55A5b88d6a32D48Ba28793CD8010d6Ee6] = true;
        whitelist[0xDC4F2F9aCb36Da79C27dA4a1eb226B81b51cEb9B] = true;
        whitelist[0xaC3247801ca573F88A8B6675F59A0232132532F4] = true;
        whitelist[0xb7F890197550BF6f87f4d1Ed92cC69A8BB32C04f] = true;
        whitelist[0x5404A4D869b31e1ce899B02C54A0C3556A21e4bD] = true;
        whitelist[0x612d8b36Ef942CD035B03Dc228a1aFdA28d43d18] = true;
        whitelist[0x532F18649Cc8D8D09d427409383C3F8c53C032A9] = true;
        whitelist[0x6c9E02eAD987B05835332cf3381bfE6D13c6b27A] = true;
        whitelist[0x51201c1472fE8663d6B91B761Ba396422c40e7A7] = true;
        whitelist[0x23B540Ad5fEFfbf0bADa6fb65b419DffC4524Bc7] = true;
        whitelist[0x24877757fd4c9a029E702f12Af7dFE3FbD57820E] = true;
        whitelist[0xc96CdEA7cF6236f3e62919C816448fd4D8d6009b] = true;
        whitelist[0xF6bfcF958a5D9C95765969d6704E685a673Ab0DE] = true;
        whitelist[0xa4270519A1ED788A1E0f597DBEb6AaE3d7dB2199] = true;
        whitelist[0xF3352bD2B4D11908d30b21AFB92805ed0017030b] = true;
        whitelist[0xBF9d8c49f0a910cD98feFBa098fe2405A8f06EFe] = true;
        whitelist[0x8c4A285c92b971E0508B79d54a35d985EB006a09] = true;
        whitelist[0x5fc460265E46458435273EB92Cc6d89b842611d2] = true;
        whitelist[0x6DfFE2014b2F60b4E5CAa8e8258E6be90bDf8694] = true;
        whitelist[0x1345E047f847c8b73c51111ffb511c29B6737709] = true;
        whitelist[0x7e3cE3Ad2Ffc04343a9cEbc726b4131b60c2927a] = true;
        whitelist[0xEf0F34669f9b9D53Cc8b0cEFDE50b9d27355B293] = true;
        whitelist[0xe8eeCf0228B0eD6E885B934f8bFb9161240d6E5B] = true;
        whitelist[0x49E3371cBc4d51aFCbfF9e295Ab91ee34bcf26Ed] = true;
        whitelist[0xE33B49C068ddCdB576Bd18Dc69c272f4600B18Fd] = true;
        whitelist[0x2Aeb5f1b609696bA2D7d0942f668908a1608fB9E] = true;
        whitelist[0x99244FD465d24dd233a0a067c23440B629b552Dc] = true;
        whitelist[0x7aB1cB052a99c6b5D0cA34175Ae60f8316D29Bf5] = true;
        whitelist[0x9E34702FE8878F122E153Fe586FbC4162658BF58] = true;
        whitelist[0xfB23aCdA916351B0B271fabFE50e16e8c9A92a2b] = true;
        whitelist[0x6def6445893aEdE553bC6544643616b53F328f38] = true;
        whitelist[0xa843362b483A7c1ef6784602C89C9Bf5D6c5E282] = true;
        whitelist[0x1fD1E6Eeda4cde0A9D564356cef7A9637db872Ad] = true;
        whitelist[0xc1233d91eABB314723106d08FD42E2863c1c2e16] = true;
        whitelist[0x051C5559BC2a7Bd0066E58006E6747B4e7A7c328] = true;
        whitelist[0xB4Be85887D68A3dFDd5e9826A5b7744379FD34E4] = true;
        whitelist[0x1f2C12E691dEd35b5F663B8f14e73922a00Ded94] = true;
        whitelist[0xB5E5cCD5aDA260b7C62aCb174A888231e4fF3683] = true;
        whitelist[0x9557a93c5852bb5D6AEaD51627239187DEd13C08] = true;
        whitelist[0xB16CDc1f5DBc9D0637422C408c099c5EDab69830] = true;
        whitelist[0x9FAa2e996366b0dB8989fb0F140F30d731B88434] = true;
        whitelist[0x42DdFA7855199bdb666D16f346683Bd4355C1c4B] = true;
        whitelist[0x3EdC6fC51E3fb43857e4a7a7755eb4B61c477077] = true;
        whitelist[0x691AbBe6d8aC6a284Eb6bD08240e3AFF0F25d016] = true;
        whitelist[0x592467de8e2d90cf2eF255b27D6aCf3AFC32a43C] = true;
        whitelist[0x44df89C5df80DeB8abB87CF71c249586520e3826] = true;
        whitelist[0x0eB1FC6AAA220aC62Bf8C42C655F899Eb4FC9561] = true;
        whitelist[0xdD13c7c4e84011B22230cD284cD0c48cBeB0B217 ] = true;
        whitelist[0x18A100CdA80Fdc7274EE14E6e3CD6B0b6CdE4ed8] = true;
        whitelist[0x0898EA214BDA9d32e4C97cCFaE54363e11199A80] = true;
        whitelist[0x57903f3DbDC520191B2AD065cf2237E89B617B15] = true;
        whitelist[0x0FbfdA03999B8320B292E7D5289728c01Ed8de44] = true;
        whitelist[0xED638d2de9E7b6E8D06514A161bb2cEFf28bfCDd] = true;
        whitelist[0xD4d3E342902766344075D06c94391e61A9bB7e60] = true;
        whitelist[0x21100971d97cE316630793238CA06Af426171E94] = true;
        whitelist[0x57F835090F138E57042Ba602973cbF88292f6f93] = true;
        whitelist[0x5Ca8035FD1937DEaD7d1577348A79fa5B440F417] = true;
        whitelist[0xCCC7aAd892060574Ea2C89548aBaF060AFB568f4] = true;
        whitelist[0xA4cf064D02E35Aed6340df50D0c9e121B16B1Bb6] = true;
        whitelist[0xe470872c0c2a9387481Ee6A01a27bf1E0669EBA9] = true;
        whitelist[0xEA471194ADCcbb913f5a3FF0af4a4914ac2C3B79] = true;
        whitelist[0xec9DD4D4768446c2549eb408739F0D9e051113d8] = true;
        whitelist[0x1025049DcAed60766f34c8F8aFd5DD0151D98B39] = true;
        whitelist[0xC0946AD17B40A661A56E9e9063300F3179d67D55] = true;
        whitelist[0xC454259dAA76b9629cCF1cd59630Cfd81A3D35E6] = true;
        whitelist[0x4e755aEeA8af4a50ff6D4c0c2B36aB100A0CC399] = true;
        whitelist[0x0314b76803735A3560FFC59E781a171eb49D0c69] = true;
        whitelist[0xA4e372e7f07057F537E02E1Bb6f0a1023ad9e639] = true;
        whitelist[0x686e4B8F4bEF04Ad36861EECBE62Da1E964b555B] = true;
        whitelist[0xD3e38e08965980D78a5d4Bc5e9e2931DEc4Fb3e8] = true;
        whitelist[0xc4FDe386ff2cb3a6eE527970dA4D72b9a424db2F] = true;
        whitelist[0xd30252a943259911018617A13a34a62941847Dc0] = true;
        whitelist[0x488aa9C4BE0770612EfB9Feb942114a95d8A0A5F] = true;
        whitelist[0xA865c8cdfcD73B5c23371988c81DaF7F364B395e] = true;
        whitelist[0x57e766997eD89eC496fdF3FA315D12bc2aE87E63] = true;
        whitelist[0x6C42C30C87081a53AbBFcD1D6ADfC4816a371f30] = true;
        whitelist[0xd024c93588fB2fC5Da321eba704d2302D2c9443A] = true;
        whitelist[0xf026EE4353dBFA0AF713a6D42C03dAcB7F07A9A5] = true;
        whitelist[0x755C8d16D5298395922d791db8EAEf7294de0Cd4] = true;
        whitelist[0x38f8B2aC82773573eB5e9151870361563AE166A7] = true;
        whitelist[0xe53Cd10d1B802101e766b6fDa4CE1ad476567b5B] = true;
        whitelist[0x060F6383C0a5c04F063d5330DcA113aC4Af5C99D] = true;
        whitelist[0x55FA9F8f4755D020efB55Ff7a33068B326144a2B] = true;
        whitelist[0xA4182F5DeDeA830F5fEf7276C4cD9cfc11F68783] = true;
        whitelist[0xF92d2Faa1EfEf8bBd39150DfF58a96686DA09914] = true;
        whitelist[0x7C89867e28a971848fa908D42D9C5e6F456A093f] = true;
        whitelist[0x317A72CAa9dcAd31D931d1BEc4Aa2DF32C59B842] = true;
        whitelist[0x772Ec4695cECdfF105de3875c934Cd6EE8540756] = true;
        whitelist[0xF46e9A726721954f590619D3862A91f30dA02f3E] = true;
        whitelist[0x3Ece982Cf573c53b383cB95BDc29a2781B7D5A83] = true;
        whitelist[0x2c0205A117caDD1ECb842453710db7755648f633] = true;
        whitelist[0x146c879461eC856A287910a746677E692A5203c4] = true;
        whitelist[0x31d35bDA1daEE81236439eC5cD7F1DdC988829Ea] = true;
        whitelist[0xE75b6c11e7a8Dd3f7d51Ab0f7a6669Fe22e6aD41] = true;
        whitelist[0xfE721f7Db4B09D739D942c02752B96BB5F7454F1] = true;
        whitelist[0x02ff44eBd3A432915f2A30E8087721200d9038d7] = true;
        whitelist[0x7FB0ad0039E27E1cE9521C2D76D632AC3b3EBD3A] = true;
        whitelist[0x8e037f7Fd208f57dF23381B095aA8cD0b690CfF1] = true;
        whitelist[0x9a36D4D379B9Ba1270F49dDA5510E89B5BB07C6d] = true;
        whitelist[0x12a92623A8b698DF20f62ebDfC76f4c7Fe2Aa7b8] = true;
        whitelist[0xD4262407Ab46769960Ff4141405D7F2d1173BDe6] = true;
        whitelist[0xC51BE51c7d06e2C72d4AA1C3DE8CC454FfE1D339] = true;
        whitelist[0x2F595b88f1d8f091fbE45985265E9adBdfDb85d5] = true;
        whitelist[0x08B93bbF65E897Ab789a56dAD62D0Ac0158baAAF] = true;
        whitelist[0xa9911eDf7aCc458d429Ff495dB5ED487308Ac49F] = true;
        whitelist[0xe8d876A510b0C860921A2d30e83cF63247c33612] = true;
        whitelist[0xA99501bEfB474a86a4E071f164032f5D7AE5F9e3] = true;
        whitelist[0x7631a76e19f118c0C453c843BC716bD68F4689e8] = true;
        whitelist[0xBba1Fb1378f8143bb7dC6Dd3617274ed05645723] = true;
        whitelist[0x4358e08585dd1dbf0Fe29aA8cF7372F620eae7f6] = true;
        whitelist[0x2FF1f99638d3906C72b65ccF401333f6704797aC] = true;
        whitelist[0xc3787781039BcFdF011376B00de8edf752a93Db1] = true;
        whitelist[0x0c8BD9Cd85545DF9cb42F19C0ae55eC9dF5b0dcc] = true;
        whitelist[0x4f75804Ac5aC8ec9A5046C75d79f5E84473B2338] = true;
        whitelist[0xE4471279812d283e9285c8c4A1Fc1C42C64Adaf6] = true;
        whitelist[0xAd11966551c4860bbEC7d8294843A2d74A273dDc] = true;
        whitelist[0x5678F92F425ABa27F22781A37Ae6e8a44804eEa8] = true;
        whitelist[0x4A2AC2E17A66a82b33cA83635b1Bb9488698811d] = true;
        whitelist[0x245f223614222f4550E43d2F4c267cb791CE078A] = true;
        whitelist[0xD5Cff943cd22c2F68DCd704B9f4E44B3F7230b60] = true;
        whitelist[0x394b0CA58672253287a2b4BB2EE8ae73D3bad4c2] = true;
        whitelist[0x92c4f9b7Db19ee06Aa0E0C8267ED764aE540D297] = true;
        whitelist[0x05BEab108486185760d13526b31937cf49a47B9c] = true;
        whitelist[0x76ac1b58201D6a51059cf7BF8bf0CA5e76A10cB1] = true;
        whitelist[0x81F591D8199cCFf1156A70BD0Db484c5CD26443d] = true;
        whitelist[0x99aD52a36Fa960CE95509CEF13e7F9df371c7b3A] = true;
        whitelist[0x5d176B7daCeA96Db482430e5b98Aab87b0f9D4a6] = true;
        whitelist[0xAB75604A23E75e3fC44e22f85E35F581b1B64851] = true;
        whitelist[0xa2585Be1d95956005655B73Cc2D55379c0569E84] = true;
        whitelist[0x6656Fd8f040B398244057896CC4c65E1FBDDA393] = true;
        whitelist[0x7F437771d52D1907DBEbE574E26BC3A1B522C1Ef] = true;
        whitelist[0x5B22d954Cb04c181E20d6262Ac8894737AF72e25] = true;
        whitelist[0xe265E2BAE51B893b5236118276DA06D05D0e255d] = true;
        whitelist[0xB502B9056f97929e49992a9a3B522c8C74DFafbd] = true;
        whitelist[0x02C435d8189D9a983CDBD77F2109fdd5663A33BB] = true;
        whitelist[0xEE191a3915f13B2F68d14Be93310C6F39432b7A0] = true;
        whitelist[0x6Ca1a3E8B1e05416189B616AeA2caF2a6d0Aa167] = true;
        whitelist[0xcF08be72e2433069C8D4E23cDc7a2ED68D1F2AC3] = true;
        whitelist[0x46c6540D66bb8339Cfebe6D864B018De0e98D591] = true;
        whitelist[0xdad3e16b087879228709c6c28e6a809C39A6d0F4] = true;
        whitelist[0x547267c134d67Fa66dEC8Da44876E0bb5210B78B] = true;
        whitelist[0xf693c14B507912621A223B6F550b46e45F950CE7] = true;
        whitelist[0xd957cBBCfE92864183b10D318711E9993f4b536a] = true;
        whitelist[0xA7A884C7EbEC1c22A464d4197136c1FD1aF044aF] = true;
        whitelist[0x39C1645B9b7aF942e561B1428B2201659C845729] = true;
    }
}