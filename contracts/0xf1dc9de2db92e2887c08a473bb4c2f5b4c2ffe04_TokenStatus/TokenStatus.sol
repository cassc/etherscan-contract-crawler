/**
 *Submitted for verification at Etherscan.io on 2023-09-22
*/

// SPDX-License-Identifier: MIT

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
    function sqrt(
        uint256 a,
        Rounding rounding
    ) internal pure returns (uint256) {
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
    function log2(
        uint256 value,
        Rounding rounding
    ) internal pure returns (uint256) {
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
    function log10(
        uint256 value,
        Rounding rounding
    ) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return
                result +
                (rounding == Rounding.Up && 10 ** result < value ? 1 : 0);
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
    function log256(
        uint256 value,
        Rounding rounding
    ) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return
                result +
                (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}

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
    function toHexString(
        uint256 value,
        uint256 length
    ) internal pure returns (string memory) {
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

pragma solidity ^0.8.9;

abstract contract Operable is Context {
    mapping(address => bool) _operators;
    modifier onlyOperator() {
        _checkOperatorRole(_msgSender());
        _;
    }

    function isOperator(address _operator) public view returns (bool) {
        return _operators[_operator];
    }

    function _grantOperatorRole(address _candidate) internal {
        require(
            !_operators[_candidate],
            string(
                abi.encodePacked(
                    "account ",
                    Strings.toHexString(uint160(_msgSender()), 20),
                    " is already has an operator role"
                )
            )
        );
        _operators[_candidate] = true;
    }

    function _revokeOperatorRole(address _candidate) internal {
        _checkOperatorRole(_candidate);
        delete _operators[_candidate];
    }

    function _checkOperatorRole(address _operator) internal view {
        require(
            _operators[_operator],
            string(
                abi.encodePacked(
                    "account ",
                    Strings.toHexString(uint160(_msgSender()), 20),
                    " is not an operator"
                )
            )
        );
    }
}

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

/*
𝒎𝒐𝒓𝒐𝒈𝒂𝒎𝒊 𝑺𝑻
*/

pragma solidity ^0.8.0;

contract TokenStatus is Operable {
    // ステータス情報を格納するマッピング
    mapping(uint256 => uint256) private tokenStatus;
    mapping(uint256 => uint256) private tokenLevel;
    mapping(uint256 => uint256) private tokenAttribute;
    uint256 minStatus = 10;
    uint256 maxStatus = 70;
    uint256 addStatus = 10;
    uint256 minLevel = 1;
    uint256 maxLevel = 5;
    uint256 AttributeRandomNumber = 12;
    uint256 StatusRandomNumber = 10;
    bool statusRndFlag = true;

    // コントラクトの所有者
    address private owner;
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdTracker;

    uint256 private constant TOKEN_TYPES = 2;
    uint256 private constant PROBABILITY = 10; // 1/10000 chance for each token

    // オーナー限定のmodifier
    modifier onlyOwner() {
        require(
            msg.sender == owner,
            "Only the contract owner can call this function."
        );
        _;
    }

    // コントラクトの作成時にオーナーを設定
    constructor() {
        _grantOperatorRole(msg.sender);
        owner = msg.sender;
    }

    // TOKEN IDごとのステータスを取得
    function getStatuses(
        uint256 tokenId
    ) public view returns (uint256[] memory) {
        uint256[] memory statuses = new uint256[](3);
        statuses[0] = getLevel(tokenId);
        statuses[1] = getAtribute(tokenId);
        statuses[2] = getStatus(tokenId);
        return statuses;
    }

    // TOKEN IDごとのステータスを取得
    function getStatus(uint256 tokenId) public view returns (uint256) {
        if (tokenStatus[tokenId] == 0) {
            return minStatus;
        }
        if (tokenStatus[tokenId] > maxStatus) {
            return maxStatus;
        } else {
            return tokenStatus[tokenId];
        }
    }

    // TOKEN IDごとのレベルを取得
    function getLevel(uint256 tokenId) public view returns (uint256) {
        if (tokenLevel[tokenId] == 0) {
            return minLevel;
        }
        if (tokenLevel[tokenId] > maxLevel) {
            return maxLevel;
        } else {
            return tokenLevel[tokenId];
        }
    }

    // TOKEN IDごとのレベルを取得
    function getLevelMaxOrNo(uint256 tokenId) public view returns (bool) {
        return tokenLevel[tokenId] == maxLevel;
    }

    // TOKEN IDごとのレベルを更新
    function getAtribute(uint256 tokenId) public view returns (uint256) {
        return tokenAttribute[tokenId];
    }

    // TOKEN IDごとのレベルを更新
    function getMinStatus() public view returns (uint256) {
        return minStatus;
    }

    // TOKEN IDごとのステータスを更新
    function setStatus(uint256 tokenId, uint256 status) public onlyOperator {
        tokenStatus[tokenId] = status;
    }

    // TOKEN IDごとのレベルを更新
    function setLevel(uint256 tokenId, uint256 _level) public onlyOperator {
        tokenLevel[tokenId] = _level;
    }

    // TOKEN IDごとの属性を更新
    function setAtribute(
        uint256 tokenId,
        uint256 _attribute
    ) public onlyOperator {
        tokenAttribute[tokenId] = _attribute;
    }

    // minStatus    を更新
    function setminStatus(uint256 _Num) public onlyOperator {
        minStatus = _Num;
    }

    // maxStatus    を更新
    function setmaxStatus(uint256 _Num) public onlyOperator {
        maxStatus = _Num;
    }

    // addStatus    を更新
    function setaddStatus(uint256 _Num) public onlyOperator {
        addStatus = _Num;
    }

    // minLevel    を更新
    function setminLevel(uint256 _Num) public onlyOperator {
        minLevel = _Num;
    }

    // maxLevel    を更新
    function setmaxLevel(uint256 _Num) public onlyOperator {
        maxLevel = _Num;
    }

    // 属性ランラム値を更新
    function setAttributeRandomNumber(uint256 randNum_) public onlyOperator {
        AttributeRandomNumber = randNum_;
    }

    // ステータスランラム値を更新
    function setStatusRandomNumber(uint256 randNum_) public onlyOperator {
        StatusRandomNumber = randNum_;
    }

    // ランダム関数
    function random(uint256 _number) public view virtual returns (uint256) {
        bytes32 seed = bytes32(
            uint256(keccak256(abi.encodePacked(block.timestamp)))
        );
        uint256 randomInt = uint256(
            keccak256(abi.encodePacked(seed, blockhash(block.number)))
        );
        return randomInt % _number;
    }

    // ADDステータスFLAG
    function setAddStatusFlag(bool _flag) public onlyOperator {
        statusRndFlag = _flag;
    }

    // TOKEN IDごとのレベルを更新
    function upLevel(uint256 tokenId) public onlyOperator {
        if (tokenLevel[tokenId] < maxLevel) {
            if (tokenLevel[tokenId] == 0) {
                tokenLevel[tokenId] += minLevel;
            }
            tokenLevel[tokenId] += 1;
            upStatus(tokenId);
            upAtribute(tokenId);
        }
    }

    // TOKEN IDごとのステータスを更新
    function upStatus(uint256 tokenId) public onlyOperator {
        if (tokenStatus[tokenId] == 0) {
            tokenStatus[tokenId] += minStatus;
        }
        tokenStatus[tokenId] += addStatus;
        if (statusRndFlag) {
            tokenStatus[tokenId] += random(StatusRandomNumber);
        }
    }

    // TOKEN IDごとの属性を更新(陰陽トライアル)
    function upAtribute(uint256 tokenId) public onlyOperator {
        if (tokenAttribute[tokenId] < 6) {
            uint256 randomResult = random(AttributeRandomNumber);
            if (randomResult == AttributeRandomNumber - 1) {
                tokenAttribute[tokenId] = 6;
            } else if (randomResult == (AttributeRandomNumber - 2)) {
                tokenAttribute[tokenId] = 7;
            }
        }
    }

    /**
        @dev Operable.Role.ADD
     */
    function grantOperatorRole(address _candidate) external onlyOwner {
        _grantOperatorRole(_candidate);
    }

    /**
        @dev Operable.Role.REMOVE
     */
    function revokeOperatorRole(address _candidate) external onlyOwner {
        _revokeOperatorRole(_candidate);
    }
}