// SPDX-License-Identifier: MIT
// @title: Primes utils
// @creator: g56d
// @dev: bortch
pragma solidity 0.8.17;

library PrimesUtils {
    /**
     * @notice Get the number of primes in a token ID
     * @param _i for series position index
     * @return The number of primes
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
     * @notice Generate a random number either true or false
     * @param _seed The seed
     * @param _salt The salt
     * @return The random number either true or false
     */
    function randomOI(
        uint256 _seed,
        uint256 _salt
    ) internal view returns (bool) {
        return
            uint256(keccak256(abi.encodePacked(msg.sender, _seed, _salt))) %
                2 ==
            1;
    }

    function setAnimationEvent(
        uint256 _seed,
        uint256 _salt
    ) internal view returns (string memory) {
        if (randomOI(_seed, _salt)) {
            return "begin";
        } else {
            return "end";
        }
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