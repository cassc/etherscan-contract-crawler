// SPDX-License-Identifier: -
// License: https://license.clober.io/LICENSE.pdf

pragma solidity ^0.8.0;

import "../Errors.sol";

abstract contract GeometricPriceBook {
    uint256 private immutable _a;
    uint256 private immutable _r0;
    uint256 private immutable _r1;
    uint256 private immutable _r2;
    uint256 private immutable _r3;
    uint256 private immutable _r4;
    uint256 private immutable _r5;
    uint256 private immutable _r6;
    uint256 private immutable _r7;
    uint256 private immutable _r8;
    uint256 private immutable _r9;
    uint256 private immutable _r10;
    uint256 private immutable _r11;
    uint256 private immutable _r12;
    uint256 private immutable _r13;
    uint256 private immutable _r14;
    uint256 private immutable _r15;
    uint256 private immutable _r16;

    constructor(uint128 a_, uint128 r_) {
        uint256 castedR = uint256(r_);
        if ((a_ * castedR) / 10**18 <= a_) {
            revert Errors.CloberError(Errors.INVALID_COEFFICIENTS);
        }
        _a = a_;
        _r0 = ((1 << 64) * castedR) / 10**18;
        _r1 = (_r0 * _r0) >> 64;
        _r2 = (_r1 * _r1) >> 64;
        _r3 = (_r2 * _r2) >> 64;
        _r4 = (_r3 * _r3) >> 64;
        _r5 = (_r4 * _r4) >> 64;
        _r6 = (_r5 * _r5) >> 64;
        _r7 = (_r6 * _r6) >> 64;
        _r8 = (_r7 * _r7) >> 64;
        _r9 = (_r8 * _r8) >> 64;
        _r10 = (_r9 * _r9) >> 64;
        _r11 = (_r10 * _r10) >> 64;
        _r12 = (_r11 * _r11) >> 64;
        _r13 = (_r12 * _r12) >> 64;
        _r14 = (_r13 * _r13) >> 64;
        _r15 = (_r14 * _r14) >> 64;
        _r16 = (_r15 * _r15) >> 64;

        if (_r16 * _a >= 1 << 192) {
            revert Errors.CloberError(Errors.INVALID_COEFFICIENTS);
        }
    }

    function _indexToPrice(uint16 priceIndex) internal view virtual returns (uint128) {
        uint256 price;
        unchecked {
            price = (priceIndex & 0x8000 != 0) ? (_a * _r15) >> 64 : _a;
            if (priceIndex & 0x4000 != 0) price = (price * _r14) >> 64;
            if (priceIndex & 0x2000 != 0) price = (price * _r13) >> 64;
            if (priceIndex & 0x1000 != 0) price = (price * _r12) >> 64;
            if (priceIndex & 0x800 != 0) price = (price * _r11) >> 64;
            if (priceIndex & 0x400 != 0) price = (price * _r10) >> 64;
            if (priceIndex & 0x200 != 0) price = (price * _r9) >> 64;
            if (priceIndex & 0x100 != 0) price = (price * _r8) >> 64;
            if (priceIndex & 0x80 != 0) price = (price * _r7) >> 64;
            if (priceIndex & 0x40 != 0) price = (price * _r6) >> 64;
            if (priceIndex & 0x20 != 0) price = (price * _r5) >> 64;
            if (priceIndex & 0x10 != 0) price = (price * _r4) >> 64;
            if (priceIndex & 0x8 != 0) price = (price * _r3) >> 64;
            if (priceIndex & 0x4 != 0) price = (price * _r2) >> 64;
            if (priceIndex & 0x2 != 0) price = (price * _r1) >> 64;
            if (priceIndex & 0x1 != 0) price = (price * _r0) >> 64;
        }

        return uint128(price);
    }

    function _priceToIndex(uint128 price, bool roundingUp)
        internal
        view
        virtual
        returns (uint16 index, uint128 correctedPrice)
    {
        if (price < _a || price >= (_a * _r16) >> 64) {
            revert Errors.CloberError(Errors.INVALID_PRICE);
        }
        index = 0;
        uint256 _correctedPrice = _a;
        uint256 shiftedPrice = (uint256(price) + 1) << 64;

        unchecked {
            if (shiftedPrice > _r15 * _correctedPrice) {
                index = index | 0x8000;
                _correctedPrice = (_correctedPrice * _r15) >> 64;
            }
            if (shiftedPrice > _r14 * _correctedPrice) {
                index = index | 0x4000;
                _correctedPrice = (_correctedPrice * _r14) >> 64;
            }
            if (shiftedPrice > _r13 * _correctedPrice) {
                index = index | 0x2000;
                _correctedPrice = (_correctedPrice * _r13) >> 64;
            }
            if (shiftedPrice > _r12 * _correctedPrice) {
                index = index | 0x1000;
                _correctedPrice = (_correctedPrice * _r12) >> 64;
            }
            if (shiftedPrice > _r11 * _correctedPrice) {
                index = index | 0x0800;
                _correctedPrice = (_correctedPrice * _r11) >> 64;
            }
            if (shiftedPrice > _r10 * _correctedPrice) {
                index = index | 0x0400;
                _correctedPrice = (_correctedPrice * _r10) >> 64;
            }
            if (shiftedPrice > _r9 * _correctedPrice) {
                index = index | 0x0200;
                _correctedPrice = (_correctedPrice * _r9) >> 64;
            }
            if (shiftedPrice > _r8 * _correctedPrice) {
                index = index | 0x0100;
                _correctedPrice = (_correctedPrice * _r8) >> 64;
            }
            if (shiftedPrice > _r7 * _correctedPrice) {
                index = index | 0x0080;
                _correctedPrice = (_correctedPrice * _r7) >> 64;
            }
            if (shiftedPrice > _r6 * _correctedPrice) {
                index = index | 0x0040;
                _correctedPrice = (_correctedPrice * _r6) >> 64;
            }
            if (shiftedPrice > _r5 * _correctedPrice) {
                index = index | 0x0020;
                _correctedPrice = (_correctedPrice * _r5) >> 64;
            }
            if (shiftedPrice > _r4 * _correctedPrice) {
                index = index | 0x0010;
                _correctedPrice = (_correctedPrice * _r4) >> 64;
            }
            if (shiftedPrice > _r3 * _correctedPrice) {
                index = index | 0x0008;
                _correctedPrice = (_correctedPrice * _r3) >> 64;
            }
            if (shiftedPrice > _r2 * _correctedPrice) {
                index = index | 0x0004;
                _correctedPrice = (_correctedPrice * _r2) >> 64;
            }
            if (shiftedPrice > _r1 * _correctedPrice) {
                index = index | 0x0002;
                _correctedPrice = (_correctedPrice * _r1) >> 64;
            }
            if (shiftedPrice > _r0 * _correctedPrice) {
                index = index | 0x0001;
                _correctedPrice = (_correctedPrice * _r0) >> 64;
            }
        }
        if (roundingUp && _correctedPrice < price) {
            unchecked {
                if (index == type(uint16).max) {
                    revert Errors.CloberError(Errors.INVALID_PRICE);
                }
                index += 1;
            }
            correctedPrice = _indexToPrice(index);
        } else {
            correctedPrice = uint128(_correctedPrice);
        }
    }
}