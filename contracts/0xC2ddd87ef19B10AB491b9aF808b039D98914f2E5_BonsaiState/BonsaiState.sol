/**
 *Submitted for verification at Etherscan.io on 2023-02-10
*/

// SPDX-License-Identifier: VPL - VIRAL PUBLIC LICENSE
pragma solidity ^0.8.13;

enum PruneDegrees {NONE, LOW, MEDIUM, HIGH}

enum HealthStatus {OK, DRY, DEAD}

struct BonsaiProfile {
    uint256 modifiedSteps;

    uint64 adjustedStartTime;
    uint64 ratio;
    uint32 seed;
    uint8 trunkSVGNumber;

    uint64 lastWatered;
}

struct WateringStatus {
    uint64 lastWatered; 
    HealthStatus healthStatus;
    string status;
}

struct Vars {
    uint256 layer;
    uint256 strokeWidth;
    bytes32[12] gradients;
}

struct RawAttributes {
    bytes32 backgroundColor;
    bytes32 blossomColor;
    bytes32 wateringStatus;

    uint32 seed;
    uint64 ratio;
    uint64 adjustedStartTime;
    uint64 lastWatered;
    uint8 trunkSVGNumber;
    HealthStatus healthStatus;

    uint256[] modifiedSteps;
}

interface IBonsaiRenderer {
    function numTrunks() external view returns(uint256);
    function renderForHumans(uint256 tokenId) external view returns(string memory);
    function renderForRobots(uint256 tokenId) external view returns(RawAttributes memory);
}

interface IBonsaiState {
    function getBonsaiProfile(uint256 tokenId) external view returns(BonsaiProfile memory);
    function initializeBonsai(uint256 tokenId, bool mayBeBot) external;
    function water(uint256 tokenId) external returns(WateringStatus memory);
    function wateringStatus(uint256 tokenId) external view returns(WateringStatus memory);
    function wateringStatusForRender(uint64 lastWatered, uint64 adjustedStartTime, bool watering) external view returns(WateringStatus memory ws);
    function prune(uint256 tokenId, PruneDegrees degree) external;
}

// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

// OpenZeppelin Contracts (last updated v4.7.0) (utils/math/Math.sol)

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
            return result + (rounding == Rounding.Up && 1 << (result << 3) < value ? 1 : 0);
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

library HelpersLib {

    function _getPointInRange(uint64 center, uint64 intervalWidth, uint256 seed) internal pure returns(uint64 ratio) {
        // unchecked assuming caller picks center and intervalWidth that would be safe and sensible
        uint256 jump = seed % uint256(intervalWidth);
        unchecked{
        if (seed % 2 == 0) {
            ratio = center + uint64(jump); 
        } else {
            ratio = center - uint64(jump); 
        }
        }//uc
    }

    function _toUint8Arr(uint256 encoded) internal pure returns(uint256[] memory) {
        uint256 mask = uint256(type(uint8).max); 
        uint256[] memory ret = new uint256[](32);
        uint256 shift;
        unchecked{
        for (uint256 i; i < 32; ++i) {
            shift = i*8; 
            ret[i] = (encoded & (mask << shift)) >> shift;
        }
        }//uc
        return ret;
    }

    function _buildStringArray(uint256[] memory nums) internal pure returns(string memory) {
        bytes memory tmp;
        uint256 numsLength = nums.length;
        unchecked{
        for (uint256 i; i < numsLength; ++i) {
            tmp = abi.encodePacked(tmp, Strings.toString(nums[i]), ",");
        }
        }//uc
        return string(abi.encodePacked(
                  "[",
                  tmp,
                  "]" 
        ));
    }

    function _push(uint256[] memory arrayStack, uint256 value) internal pure {
        unchecked{ // protected by _maxCacheSize initializing the cache
        ++arrayStack[0];
        }//uc
        arrayStack[arrayStack[0]] = value;
    }

    function _pop(uint256[] memory arrayStack) internal pure returns(uint256 value) {
        if (arrayStack[0] == 0) return type(uint256).max; // semantic overloading 
        value = arrayStack[arrayStack[0]]; 
        unchecked{
        --arrayStack[0];
        }// protected by first line
    }

    function _getUint8(uint256 pad, uint256 idx) internal pure returns(uint256) {
        unchecked{
        return pad >> (idx*8) & type(uint8).max; 
        }//uc assuming all static calls are by dev
    }

    function _steppedHash(uint256 seed, uint256 step) internal pure returns(uint256 result) {
        assembly {
           let m := add(mload(0x40), 0x40) // 0x40 two words
            // Update the free memory pointer to allocate.
            mstore(0x40, m)
            
            mstore(m, seed)
            mstore(add(m, 0x20), step)

            result := keccak256(m, 0x40)
        } 
    }
}

contract BonsaiState is IBonsaiState {

    mapping(uint256 => BonsaiProfile) private _bonsais;

    address private _bonsaiNFT;
    IBonsaiRenderer private _bonsaiRenderer;

    address public OWNER;

    uint64 constant private PHI = 1618033988749894848;

    constructor(address owner_) {
        OWNER = owner_;
    }

    function _onlyOwner() private view {
        require(msg.sender == OWNER, "not owner.");
    }

    function _onlyBonsaiNFT() private view {
        require(msg.sender == _bonsaiNFT, "not BonsaiNFT.");
    }

    function setBonsaiNFT(address bonsaiNFT_) external {
        _onlyOwner();
        require(_bonsaiNFT == address(0), "can only be set once.");
        _bonsaiNFT = bonsaiNFT_;
    }

    function setBonsaiRenderer(address bonsaiRenderer_) external {
        _onlyOwner();
        require(address(_bonsaiRenderer) == address(0), "can only be set once.");
        _bonsaiRenderer = IBonsaiRenderer(bonsaiRenderer_);
    }

    function getBonsaiProfile(uint256 tokenId) external view returns(BonsaiProfile memory) {
        return _bonsais[tokenId];
    }

    function initializeBonsai(uint256 tokenId, bool mayBeBot) external {
        _onlyBonsaiNFT();
        // tokenId is from bonzai's counter
        uint256 seed = uint256(keccak256(abi.encodePacked(tokenId, tx.origin, blockhash(block.number - 1))));
        uint64 intervalWidth = 1e15;
        uint256 modulus = _bonsaiRenderer.numTrunks();
        unchecked{
        if (mayBeBot) {
            intervalWidth = 1e16; 
            modulus /= 2;
        }
        uint64 ratio = HelpersLib._getPointInRange({center: PHI, intervalWidth: intervalWidth, seed: seed});

        modulus = (seed % 100 > 2) ? modulus/2 : modulus; // only top 2%tile gets "full" trunk list to choose from
        uint8 trunkSVGNumber = uint8(uint256(keccak256(abi.encodePacked(seed, blockhash(block.number - 1)))) % modulus);

        uint256 originalSteps = uint256(keccak256(abi.encodePacked(seed))); // easy
        uint64 originalStartTime = uint64(block.timestamp - 1 days); // render needs to be "bootstrapped" by one day

        _bonsais[tokenId] = BonsaiProfile({
            modifiedSteps: originalSteps,    
            adjustedStartTime: originalStartTime,
            ratio: ratio,
            seed: uint32(seed),
            trunkSVGNumber: trunkSVGNumber,
            lastWatered: originalStartTime
        });
        }// uc
    }

    function water(uint256 tokenId) external returns(WateringStatus memory) {
        _onlyBonsaiNFT(); // nft has checked that bonsai exists
        BonsaiProfile memory bp = _bonsais[tokenId];
        uint64 lastWatered = bp.lastWatered;
        WateringStatus memory ws = _wateringStatus({lastWatered: lastWatered, adjustedStartTime: bp.adjustedStartTime, watering: true});
        if (ws.lastWatered != lastWatered)
            _bonsais[tokenId].lastWatered = ws.lastWatered;
        return ws;
    }

    function wateringStatus(uint256 tokenId) public view returns(WateringStatus memory) {
        _onlyBonsaiNFT(); // nft has checked that bonsai exists
        BonsaiProfile memory bp = _bonsais[tokenId];
        return _wateringStatus({lastWatered: bp.lastWatered, adjustedStartTime: bp.adjustedStartTime, watering: false});
    }

    function wateringStatusForRender(uint64 lastWatered, uint64 adjustedStartTime, bool watering) external view returns(WateringStatus memory ws) {
        return _wateringStatus(lastWatered, adjustedStartTime, watering);
    }

    function _wateringStatus(uint64 lastWatered, uint64 adjustedStartTime, bool watering) private view returns(WateringStatus memory ws) {
        unchecked{
        ws.lastWatered = lastWatered;
        if (lastWatered == type(uint64).max) {
            ws.status = "Matured: doesn't need watering.";
            ws.healthStatus = HealthStatus.OK;
        } else if (block.timestamp < lastWatered + 1 weeks) {
            ws.status = "Watered: just water once a week.";
            ws.healthStatus = HealthStatus.OK;
        } else if (block.timestamp >= lastWatered + 1 weeks && block.timestamp < lastWatered + 2 weeks) {
            if (watering) {
                if (block.timestamp >= 6 weeks + adjustedStartTime) {
                    ws.lastWatered = type(uint64).max; // no more watering needed :)
                    ws.status = "Matured: doesn't need watering.";
                } else {
                    ws.lastWatered = uint64(block.timestamp); 
                    ws.status = "Watered: right on schedule.";
                }
                ws.healthStatus = HealthStatus.OK;
            } else {
                ws.status = "Dry: plant needs watering.";
                ws.healthStatus = HealthStatus.DRY;
            }
        } else if (block.timestamp >= lastWatered + 2 weeks) {
            ws.status = "DEAD: plant has dried out.";
            ws.healthStatus = HealthStatus.DEAD;
            // lastWatered kept so that blackened bonsai retains shape
        }
        }//uc
    }

    function prune(uint256 tokenId, PruneDegrees degree) external {
        _onlyBonsaiNFT(); // nft has checked that degree > NONE
        BonsaiProfile memory bp = _bonsais[tokenId];
        WateringStatus memory ws = _wateringStatus({lastWatered: bp.lastWatered, adjustedStartTime: bp.adjustedStartTime, watering: false});
        HealthStatus hs = ws.healthStatus;
        if (hs == HealthStatus.DEAD) revert("no use pruning DEAD bonsai.");
        if (hs == HealthStatus.DRY) revert("first water bonsai before pruning.");

        // just a few levels to reduce complexity, first 3 levels to be exact
        // and so there'll easily be feedback for the user
        uint256 steps = bp.modifiedSteps;
        unchecked{
        uint256 stepSeed = uint256(keccak256(abi.encodePacked(steps, tx.origin, msg.sender, blockhash(block.timestamp-1))));

        uint256[] memory stepsArr = HelpersLib._toUint8Arr(steps);
        uint256 updatedSteps;
        uint256 startingIdx;
        updatedSteps |= stepsArr[startingIdx]; // first level cannot be changed
        
        startingIdx = uint256(PruneDegrees.HIGH) - uint256(degree) + 1;

        // copy from last
        for (uint256 i = 1; i < startingIdx; ++i) {
            updatedSteps |= stepsArr[i] << (i*8);
        }

        uint256[] memory newStepsArr = HelpersLib._toUint8Arr(stepSeed);
        for (uint256 i = startingIdx; i < 32; ++i) {
            updatedSteps |= newStepsArr[i] << (i*8);
        }

        _bonsais[tokenId].modifiedSteps = updatedSteps;

        // update age
        uint256 quotient = uint256(degree) + 1;
        uint256 age = block.timestamp - _bonsais[tokenId].adjustedStartTime;
        age /= quotient;
        age = (age < 1 days) ? 1 days : age; // recall: render needs to be "bootstrapped" by one day
        _bonsais[tokenId].adjustedStartTime = uint64(block.timestamp - age);
        }//uc
    }
}