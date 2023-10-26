// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

// @author g56d

library PrimesUtils {
    /**
     * @notice Get the number of primes
     * @param _i at serie number
     * @return The total
     */
    function getNumberOfPrimeNumber(
        uint256 _i
    ) internal pure returns (uint256) {
        uint256 value = _i * 81;
        uint256 total = 0;
        for (uint256 x = value - 80; x < value; x += 1) {
            if (isPrime(uint256(x))) {
                total += 1;
            }
        }
        return total;
    }

    /**
     * @param _a interger
     * @param _b interger
     * @return True or false
     */
    function booleanRandom(
        uint256 _a,
        uint256 _b
    ) internal view returns (bool) {
        return
            (uint256(keccak256(abi.encodePacked(_a, msg.sender))) % _b) % 2 ==
            0;
    }

    /**
     * @notice Check if a number is prime
     * @param _n The number to check
     * @return True if the number is prime and false otherwise (including 1)
     */
    function isPrime(uint256 _n) internal pure returns (bool) {
        uint256 p = sqrt(_n);
        for (uint256 i = 2; i <= p; i++) {
            if (_n % i == 0) {
                return false;
            }
        }
        return _n != 1;
    }

    // from @openzeppelin/contracts/utils/math/Math.sol
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 result = 1 << (log2(a) >> 1);
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

    // from @openzeppelin/contracts/utils/math/Math.sol
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

    // from @openzeppelin/contracts/utils/math/Math.sol
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    // from @openzeppelin/contracts/utils/math/Math.sol
    function abs(int256 n) internal pure returns (uint256) {
        // must be unchecked in order to support `n = type(int256).min`
        unchecked {
            return uint256(n >= 0 ? n : -n);
        }
    }

    function concatenate(
        string memory _a,
        string memory _b
    ) internal pure returns (string memory result) {
        result = string(abi.encodePacked(bytes(_a), bytes(_b)));
    }
}