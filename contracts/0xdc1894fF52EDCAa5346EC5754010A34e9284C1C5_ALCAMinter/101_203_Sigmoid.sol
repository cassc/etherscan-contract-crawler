// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

abstract contract Sigmoid {
    // Constants for P function
    uint256 internal constant _P_A = 200;
    uint256 internal constant _P_B = 2500 * 10 ** 18;
    uint256 internal constant _P_C = 5611050234958650739260304 + 125 * 10 ** 39;
    uint256 internal constant _P_D = 4;
    uint256 internal constant _P_S = 2524876234590519489452;

    // Constants for P Inverse function
    uint256 internal constant _P_INV_C_1 = _P_A * ((_P_A + _P_D) * _P_S + _P_A * _P_B);
    uint256 internal constant _P_INV_C_2 = _P_A + _P_D;
    uint256 internal constant _P_INV_C_3 = _P_D * (2 * _P_A + _P_D);
    uint256 internal constant _P_INV_D_0 = ((_P_A + _P_D) * _P_S + _P_A * _P_B) ** 2;
    uint256 internal constant _P_INV_D_1 = 2 * (_P_A * _P_S + (_P_A + _P_D) * _P_B);

    function _p(uint256 t) internal pure returns (uint256) {
        return
            (_P_A + _P_D) *
            t +
            (_P_A * _P_S) -
            _sqrt(_P_A ** 2 * ((_safeAbsSub(_P_B, t)) ** 2 + _P_C));
    }

    function _pInverse(uint256 m) internal pure returns (uint256) {
        return
            (_P_INV_C_2 *
                m +
                _sqrt(_P_A ** 2 * (m ** 2 + _P_INV_D_0 - _P_INV_D_1 * m)) -
                _P_INV_C_1) / _P_INV_C_3;
    }

    function _safeAbsSub(uint256 a, uint256 b) internal pure returns (uint256) {
        return _max(a, b) - _min(a, b);
    }

    function _min(uint256 a_, uint256 b_) internal pure returns (uint256) {
        if (a_ <= b_) {
            return a_;
        }
        return b_;
    }

    function _max(uint256 a_, uint256 b_) internal pure returns (uint256) {
        if (a_ >= b_) {
            return a_;
        }
        return b_;
    }

    function _sqrt(uint256 x) internal pure returns (uint256) {
        unchecked {
            if (x <= 1) {
                return x;
            }
            if (x >= ((1 << 128) - 1) ** 2) {
                return (1 << 128) - 1;
            }
            // Here, e represents the bit length;
            // its value is at most 256, so it could fit in a uint16.
            uint256 e = 1;
            // Here, result is a copy of x to compute the bit length
            uint256 result = x;
            if (result >= (1 << 128)) {
                result >>= 128;
                e += 128;
            }
            if (result >= (1 << 64)) {
                result >>= 64;
                e += 64;
            }
            if (result >= (1 << 32)) {
                result >>= 32;
                e += 32;
            }
            if (result >= (1 << 16)) {
                result >>= 16;
                e += 16;
            }
            if (result >= (1 << 8)) {
                result >>= 8;
                e += 8;
            }
            if (result >= (1 << 4)) {
                result >>= 4;
                e += 4;
            }
            if (result >= (1 << 2)) {
                result >>= 2;
                e += 2;
            }
            if (result >= (1 << 1)) {
                e += 1;
            }
            // e is currently bit length; we overwrite it to scale x
            e = (256 - e) >> 1;
            // m now satisfies 2**254 <= m < 2**256
            uint256 m = x << (2 * e);
            // result now stores the result
            result = 1 + (m >> 254);
            result = (result << 1) + (m >> 251) / result;
            result = (result << 3) + (m >> 245) / result;
            result = (result << 7) + (m >> 233) / result;
            result = (result << 15) + (m >> 209) / result;
            result = (result << 31) + (m >> 161) / result;
            result = (result << 63) + (m >> 65) / result;
            result >>= e;
            return result * result <= x ? result : (result - 1);
        }
    }
}