// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.19;

// OpenZeppelin Contracts (last updated v4.8.0) (access/Ownable2Step.sol)

// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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

/**
 * @dev Contract module which provides access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership} and {acceptOwnership}.
 *
 * This module is used through inheritance. It will make available all functions
 * from parent (Ownable).
 */
abstract contract Ownable2Step is Ownable {
    address private _pendingOwner;

    event OwnershipTransferStarted(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Returns the address of the pending owner.
     */
    function pendingOwner() public view virtual returns (address) {
        return _pendingOwner;
    }

    /**
     * @dev Starts the ownership transfer of the contract to a new account. Replaces the pending transfer if there is one.
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual override onlyOwner {
        _pendingOwner = newOwner;
        emit OwnershipTransferStarted(owner(), newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`) and deletes any pending owner.
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual override {
        delete _pendingOwner;
        super._transferOwnership(newOwner);
    }

    /**
     * @dev The new owner accepts the ownership transfer.
     */
    function acceptOwnership() external {
        address sender = _msgSender();
        require(pendingOwner() == sender, "Ownable2Step: caller is not the new owner");
        _transferOwnership(sender);
    }
}

// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

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

library Fixed256x18 {
    uint256 internal constant ONE = 1e18; // 18 decimal places

    function mulDown(uint256 a, uint256 b) internal pure returns (uint256) {
        return (a * b) / ONE;
    }

    function mulUp(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 product = a * b;

        if (product == 0) {
            return 0;
        } else {
            return ((product - 1) / ONE) + 1;
        }
    }

    function divDown(uint256 a, uint256 b) internal pure returns (uint256) {
        return (a * ONE) / b;
    }

    function divUp(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        } else {
            return (((a * ONE) - 1) / b) + 1;
        }
    }

    function complement(uint256 x) internal pure returns (uint256) {
        return (x < ONE) ? (ONE - x) : 0;
    }
}

library MathUtils {
    // --- Constants ---

    /// @notice Represents 100%.
    /// @dev 1e18 is the scaling factor (100% == 1e18).
    uint256 public constant _100_PERCENT = Fixed256x18.ONE;

    /// @notice Precision for Nominal ICR (independent of price).
    /// @dev Rationale for the value:
    /// - Making it “too high” could lead to overflows.
    /// - Making it “too low” could lead to an ICR equal to zero, due to truncation from floor division.
    ///
    /// This value of 1e20 is chosen for safety: the NICR will only overflow for numerator > ~1e39 collateralToken,
    /// and will only truncate to 0 if the denominator is at least 1e20 times greater than the numerator.
    uint256 internal constant _NICR_PRECISION = 1e20;

    /// @notice Number of minutes in 1000 years.
    uint256 internal constant _MINUTES_IN_1000_YEARS = 1000 * 365 days / 1 minutes;

    // --- Functions ---

    /// @notice Multiplies two decimal numbers and use normal rounding rules:
    /// - round product up if 19'th mantissa digit >= 5
    /// - round product down if 19'th mantissa digit < 5.
    /// @param x First number.
    /// @param y Second number.
    function _decMul(uint256 x, uint256 y) internal pure returns (uint256 decProd) {
        decProd = (x * y + Fixed256x18.ONE / 2) / Fixed256x18.ONE;
    }

    /// @notice Exponentiation function for 18-digit decimal base, and integer exponent n.
    ///
    /// @dev Uses the efficient "exponentiation by squaring" algorithm. O(log(n)) complexity. The exponent is capped to
    /// avoid reverting due to overflow.
    ///
    /// If a period of > 1000 years is ever used as an exponent in either of the above functions, the result will be
    /// negligibly different from just passing the cap, since the decayed base rate will be 0 for 1000 years or > 1000
    /// years.
    /// @param base The decimal base.
    /// @param exponent The exponent.
    /// @return The result of the exponentiation.
    function _decPow(uint256 base, uint256 exponent) internal pure returns (uint256) {
        if (exponent == 0) {
            return Fixed256x18.ONE;
        }

        uint256 y = Fixed256x18.ONE;
        uint256 x = base;
        uint256 n = Math.min(exponent, _MINUTES_IN_1000_YEARS); // cap to avoid overflow

        // Exponentiation-by-squaring
        while (n > 1) {
            if (n % 2 != 0) {
                y = _decMul(x, y);
            }
            x = _decMul(x, x);
            n /= 2;
        }

        return _decMul(x, y);
    }

    /// @notice Computes the Nominal Individual Collateral Ratio (NICR) for given collateral and debt. If debt is zero,
    /// it returns the maximal value for uint256 (represents "infinite" CR).
    /// @param collateral Collateral amount.
    /// @param debt Debt amount.
    /// @return NICR.
    function _computeNominalCR(uint256 collateral, uint256 debt) internal pure returns (uint256) {
        return debt > 0 ? collateral * _NICR_PRECISION / debt : type(uint256).max;
    }

    /// @notice Computes the Collateral Ratio for given collateral, debt and price. If debt is zero, it returns the
    /// maximal value for uint256 (represents "infinite" CR).
    /// @param collateral Collateral amount.
    /// @param debt Debt amount.
    /// @param price Collateral price.
    /// @return Collateral ratio.
    function _computeCR(uint256 collateral, uint256 debt, uint256 price) internal pure returns (uint256) {
        return debt > 0 ? collateral * price / debt : type(uint256).max;
    }
}

interface IPriceOracle {
    // --- Errors ---

    /// @dev Contract initialized with an invalid deviation parameter.
    error InvalidDeviation();

    // --- Types ---

    struct PriceOracleResponse {
        bool isBrokenOrFrozen;
        bool priceChangeAboveMax;
        uint256 price;
    }

    // --- Functions ---

    /// @dev Return price oracle response which consists the following information: oracle is broken or frozen, the
    /// price change between two rounds is more than max, and the price.
    function getPriceOracleResponse() external returns (PriceOracleResponse memory);

    /// @dev Maximum time period allowed since oracle latest round data timestamp, beyond which oracle is considered
    /// frozen.
    function timeout() external view returns (uint256);

    /// @dev Used to convert a price answer to an 18-digit precision uint.
    function TARGET_DIGITS() external view returns (uint256);

    /// @dev price deviation for the oracle in percentage.
    function DEVIATION() external view returns (uint256);
}

interface IPriceFeed {
    // --- Events ---

    /// @dev Last good price has been updated.
    event LastGoodPriceUpdated(uint256 lastGoodPrice);

    /// @dev Price difference between oracles has been updated.
    /// @param priceDifferenceBetweenOracles New price difference between oracles.
    event PriceDifferenceBetweenOraclesUpdated(uint256 priceDifferenceBetweenOracles);

    /// @dev Primary oracle has been updated.
    /// @param primaryOracle New primary oracle.
    event PrimaryOracleUpdated(IPriceOracle primaryOracle);

    /// @dev Secondary oracle has been updated.
    /// @param secondaryOracle New secondary oracle.
    event SecondaryOracleUpdated(IPriceOracle secondaryOracle);

    // --- Errors ---

    /// @dev Invalid primary oracle.
    error InvalidPrimaryOracle();

    /// @dev Invalid secondary oracle.
    error InvalidSecondaryOracle();

    /// @dev Primary oracle is broken or frozen or has bad result.
    error PrimaryOracleBrokenOrFrozenOrBadResult();

    /// @dev Invalid price difference between oracles.
    error InvalidPriceDifferenceBetweenOracles();

    // --- Functions ---

    /// @dev Return primary oracle address.
    function primaryOracle() external returns (IPriceOracle);

    /// @dev Return secondary oracle address
    function secondaryOracle() external returns (IPriceOracle);

    /// @dev The last good price seen from an oracle by Raft.
    function lastGoodPrice() external returns (uint256);

    /// @dev The maximum relative price difference between two oracle responses.
    function priceDifferenceBetweenOracles() external returns (uint256);

    /// @dev Set primary oracle address.
    /// @param newPrimaryOracle Primary oracle address.
    function setPrimaryOracle(IPriceOracle newPrimaryOracle) external;

    /// @dev Set secondary oracle address.
    /// @param newSecondaryOracle Secondary oracle address.
    function setSecondaryOracle(IPriceOracle newSecondaryOracle) external;

    /// @dev Set the maximum relative price difference between two oracle responses.
    /// @param newPriceDifferenceBetweenOracles The maximum relative price difference between two oracle responses.
    function setPriceDifferenceBetweenOracles(uint256 newPriceDifferenceBetweenOracles) external;

    /// @dev Returns the latest price obtained from the Oracle. Called by Raft functions that require a current price.
    ///
    /// Also callable by anyone externally.
    /// Non-view function - it stores the last good price seen by Raft.
    ///
    /// Uses a primary oracle and a fallback oracle in case primary fails. If both fail,
    /// it uses the last good price seen by Raft.
    ///
    /// @return currentPrice Returned price.
    /// @return deviation Deviation of the reported price in percentage.
    /// @notice Actual returned price is in range `currentPrice` +/- `currentPrice * deviation / ONE`
    function fetchPrice() external returns (uint256 currentPrice, uint256 deviation);
}

contract PriceFeed is IPriceFeed, Ownable2Step {
    // --- Types ---

    using Fixed256x18 for uint256;

    // --- Constants ---

    uint256 private constant MIN_PRICE_DIFFERENCE_BETWEEN_ORACLES = 1e15; // 0.1%
    uint256 private constant MAX_PRICE_DIFFERENCE_BETWEEN_ORACLES = 1e17; // 10%

    // --- Variables ---

    IPriceOracle public override primaryOracle;
    IPriceOracle public override secondaryOracle;

    uint256 public override lastGoodPrice;

    uint256 public override priceDifferenceBetweenOracles;

    // --- Constructor ---

    constructor(IPriceOracle primaryOracle_, IPriceOracle secondaryOracle_, uint256 priceDifferenceBetweenOracles_) {
        _setPrimaryOracle(primaryOracle_);
        _setSecondaryOracle(secondaryOracle_);
        _setPriceDifferenceBetweenOracle(priceDifferenceBetweenOracles_);
    }

    // --- Functions ---

    function setPrimaryOracle(IPriceOracle newPrimaryOracle) external override onlyOwner {
        _setPrimaryOracle(newPrimaryOracle);
    }

    function setSecondaryOracle(IPriceOracle newSecondaryOracle) external override onlyOwner {
        _setSecondaryOracle(newSecondaryOracle);
    }

    function setPriceDifferenceBetweenOracles(uint256 newPriceDifferenceBetweenOracles) external override onlyOwner {
        _setPriceDifferenceBetweenOracle(newPriceDifferenceBetweenOracles);
    }

    function fetchPrice() external override returns (uint256, uint256) {
        IPriceOracle.PriceOracleResponse memory primaryOracleResponse = primaryOracle.getPriceOracleResponse();
        // If primary oracle is broken or frozen, try secondary oracle
        if (primaryOracleResponse.isBrokenOrFrozen) {
            // If secondary oracle is broken or frozen, then both oracles are untrusted, so return the last good price
            IPriceOracle.PriceOracleResponse memory secondaryOracleResponse = secondaryOracle.getPriceOracleResponse();
            if (secondaryOracleResponse.isBrokenOrFrozen || secondaryOracleResponse.priceChangeAboveMax) {
                return (lastGoodPrice, Math.max(primaryOracle.DEVIATION(), secondaryOracle.DEVIATION()));
            }

            return (_storePrice(secondaryOracleResponse.price), secondaryOracle.DEVIATION());
        }

        // If primary oracle price has changed by > MAX_PRICE_DEVIATION_FROM_PREVIOUS_ROUND between two consecutive
        // rounds, compare it to secondary oracle's price
        if (primaryOracleResponse.priceChangeAboveMax) {
            IPriceOracle.PriceOracleResponse memory secondaryOracleResponse = secondaryOracle.getPriceOracleResponse();
            // If secondary oracle is broken or frozen, then both oracles are untrusted, so return the last good price
            if (secondaryOracleResponse.isBrokenOrFrozen) {
                return (lastGoodPrice, Math.max(primaryOracle.DEVIATION(), secondaryOracle.DEVIATION()));
            }

            /*
            * If the secondary oracle is live and both oracles have a similar price, conclude that the primary oracle's
            * large price deviation between two consecutive rounds were likely a legitimate market price movement, so
            * continue using primary oracle
            */
            if (_bothOraclesSimilarPrice(primaryOracleResponse.price, secondaryOracleResponse.price)) {
                return (_storePrice(primaryOracleResponse.price), primaryOracle.DEVIATION());
            }

            // If both oracle are live and have different prices, return the price that is a lower changed between the
            // two oracle's prices
            uint256 price = _getPriceWithLowerChange(primaryOracleResponse.price, secondaryOracleResponse.price);
            uint256 deviation = (price == primaryOracleResponse.price)
                ? primaryOracle.DEVIATION()
                : (
                    (price == secondaryOracleResponse.price)
                        ? secondaryOracle.DEVIATION()
                        : Math.max(primaryOracle.DEVIATION(), secondaryOracle.DEVIATION())
                );
            return (_storePrice(price), deviation);
        }

        // If primary oracle is working, return primary oracle current price
        return (_storePrice(primaryOracleResponse.price), primaryOracle.DEVIATION());
    }

    // --- Helper functions ---

    function _bothOraclesSimilarPrice(
        uint256 primaryOraclePrice,
        uint256 secondaryOraclePrice
    )
        internal
        view
        returns (bool)
    {
        // Get the relative price difference between the oracles. Use the lower price as the denominator, i.e. the
        // reference for the calculation.
        uint256 minPrice = Math.min(primaryOraclePrice, secondaryOraclePrice);
        uint256 maxPrice = Math.max(primaryOraclePrice, secondaryOraclePrice);
        uint256 percentPriceDifference = (maxPrice - minPrice).divDown(minPrice);

        /*
        * Return true if the relative price difference is <= 3%: if so, we assume both oracles are probably reporting
        * the honest market price, as it is unlikely that both have been broken/hacked and are still in-sync.
        */
        return percentPriceDifference <= priceDifferenceBetweenOracles;
    }

    // @dev Returns one of oracles' prices that deviates least from the last good price.
    //      If both oracles' prices are above the last good price, return the lower one.
    //      If both oracles' prices are below the last good price, return the higher one.
    //      Otherwise, return the last good price.
    function _getPriceWithLowerChange(
        uint256 primaryOraclePrice,
        uint256 secondaryOraclePrice
    )
        internal
        view
        returns (uint256)
    {
        if (primaryOraclePrice > lastGoodPrice && secondaryOraclePrice > lastGoodPrice) {
            return Math.min(primaryOraclePrice, secondaryOraclePrice);
        }
        if (primaryOraclePrice < lastGoodPrice && secondaryOraclePrice < lastGoodPrice) {
            return Math.max(primaryOraclePrice, secondaryOraclePrice);
        }
        return lastGoodPrice;
    }

    function _setPrimaryOracle(IPriceOracle newPrimaryOracle) internal {
        if (address(newPrimaryOracle) == address(0)) {
            revert InvalidPrimaryOracle();
        }

        IPriceOracle.PriceOracleResponse memory primaryOracleResponse = newPrimaryOracle.getPriceOracleResponse();

        if (primaryOracleResponse.isBrokenOrFrozen || primaryOracleResponse.priceChangeAboveMax) {
            revert PrimaryOracleBrokenOrFrozenOrBadResult();
        }

        primaryOracle = newPrimaryOracle;

        // Get an initial price from primary oracle to serve as first reference for lastGoodPrice
        _storePrice(primaryOracleResponse.price);

        emit PrimaryOracleUpdated(newPrimaryOracle);
    }

    function _setSecondaryOracle(IPriceOracle newSecondaryOracle) internal {
        if (address(newSecondaryOracle) == address(0)) {
            revert InvalidSecondaryOracle();
        }

        secondaryOracle = newSecondaryOracle;

        emit SecondaryOracleUpdated(newSecondaryOracle);
    }

    function _setPriceDifferenceBetweenOracle(uint256 newPriceDifferenceBetweenOracles) internal {
        if (
            newPriceDifferenceBetweenOracles < MIN_PRICE_DIFFERENCE_BETWEEN_ORACLES
                || newPriceDifferenceBetweenOracles > MAX_PRICE_DIFFERENCE_BETWEEN_ORACLES
        ) {
            revert InvalidPriceDifferenceBetweenOracles();
        }

        priceDifferenceBetweenOracles = newPriceDifferenceBetweenOracles;

        emit PriceDifferenceBetweenOraclesUpdated(newPriceDifferenceBetweenOracles);
    }

    function _storePrice(uint256 currentPrice) internal returns (uint256) {
        lastGoodPrice = currentPrice;
        emit LastGoodPriceUpdated(currentPrice);
        return currentPrice;
    }
}