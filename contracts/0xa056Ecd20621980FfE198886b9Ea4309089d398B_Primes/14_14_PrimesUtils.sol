// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

// @title: Primes methods
// @author: g56d

library PrimesUtils {
    function getNumberOfPrimes(
        uint256 _tokenId
    ) internal pure returns (uint256) {
        uint256 count = (_tokenId * 81) - 80;
        uint256 total = 0;

        for (uint256 x = 1; x <= 81; x += 1) {
            if (isPrime(uint256(count))) {
                total += 1;
            }
            count += 1;
        }

        return total;
    }

    function randomOI(
        uint256 _seed,
        uint256 _salt
    ) internal view returns (uint256 number) {
        number =
            uint256(keccak256(abi.encodePacked(msg.sender, _seed, _salt))) %
            2;
    }

    function setAnimationEvent(
        uint256 _seed,
        uint256 _salt
    ) internal view returns (string memory initAnimation) {
        if (randomOI(_seed, _salt) == 1) {
            initAnimation = "begin";
        } else {
            initAnimation = "end";
        }
    }

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

    function concatenate(
        string memory _a,
        string memory _b
    ) internal pure returns (string memory result) {
        result = string(abi.encodePacked(bytes(_a), bytes(_b)));
    }
}