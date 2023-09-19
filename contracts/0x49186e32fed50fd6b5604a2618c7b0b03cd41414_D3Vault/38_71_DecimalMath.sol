// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;
pragma experimental ABIEncoderV2;

import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

/**
 * @title DecimalMath
 * @author DODO Breeder
 *
 * @notice Functions for fixed point number with 18 decimals
 */

library DecimalMath {
    uint256 internal constant ONE = 10 ** 18;
    uint256 internal constant ONE2 = 10 ** 36;

    function mul(uint256 target, uint256 d) internal pure returns (uint256) {
        return target * d / (10 ** 18);
    }

    function mulFloor(uint256 target, uint256 d) internal pure returns (uint256) {
        return target * d / (10 ** 18);
    }

    function mulCeil(uint256 target, uint256 d) internal pure returns (uint256) {
        return _divCeil(target * d, 10 ** 18);
    }

    function div(uint256 target, uint256 d) internal pure returns (uint256) {
        return target * (10 ** 18) / d;
    }

    function divFloor(uint256 target, uint256 d) internal pure returns (uint256) {
        return target * (10 ** 18) / d;
    }

    function divCeil(uint256 target, uint256 d) internal pure returns (uint256) {
        return _divCeil(target * (10 ** 18), d);
    }

    function reciprocalFloor(uint256 target) internal pure returns (uint256) {
        return uint256(10 ** 36) / target;
    }

    function reciprocalCeil(uint256 target) internal pure returns (uint256) {
        return _divCeil(uint256(10 ** 36), target);
    }

    function sqrt(uint256 target) internal pure returns (uint256) {
        return Math.sqrt(target * ONE);
    }

    function powFloor(uint256 target, uint256 e) internal pure returns (uint256) {
        if (e == 0) {
            return 10 ** 18;
        } else if (e == 1) {
            return target;
        } else {
            uint256 p = powFloor(target, e / 2);
            p = p * p / (10 ** 18);
            if (e % 2 == 1) {
                p = p * target / (10 ** 18);
            }
            return p;
        }
    }

    function _divCeil(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 quotient = a / b;
        uint256 remainder = a - quotient * b;
        if (remainder > 0) {
            return quotient + 1;
        } else {
            return quotient;
        }
    }
}