// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

library TickMath {
    uint256 private constant Q56 = 0x100000000000000;
    uint256 private constant Q128 = 0x100000000000000000000000000000000;

    /// @dev Minimum tick supported in this protocol
    int24 internal constant MIN_TICK = -776363;
    /// @dev Maximum tick supported in this protocol
    int24 internal constant MAX_TICK = 776363;
    /// @dev Minimum sqrt price, i.e. tickToSqrtPrice(MIN_TICK)
    uint128 internal constant MIN_SQRT_P = 65539;
    /// @dev Maximum sqrt price, i.e. tickToSqrtPrice(MAX_TICK)
    uint128 internal constant MAX_SQRT_P = 340271175397327323250730767849398346765;

    /**
     * @dev Find sqrtP = u^tick, where u = sqrt(1.0001)
     *
     * Let b_i = the i-th bit of x and b_i ∈ {0, 1}
     * Then  x = (b0 * 2^0) + (b1 * 2^1) + (b2 * 2^2) + ...
     * Thus, r = u^x
     *         = u^(b0 * 2^0) * u^(b1 * 2^1) * u^(b2 * 2^2) * ...
     *         = k0^b0 * k1^b1 * k2^b2 * ... (where k_i = u^(2^i))
     * We pre-compute k_i since u is a known constant. In practice, we use u = 1/sqrt(1.0001) to
     * prevent overflow during the computation, then inverse the result at the end.
     */
    function tickToSqrtPrice(int24 tick) internal pure returns (uint128 sqrtP) {
        unchecked {
            require(MIN_TICK <= tick && tick <= MAX_TICK);
            uint256 x = uint256(uint24(tick < 0 ? -tick : tick)); // abs(tick)
            uint256 r = Q128; // UQ128.128

            if (x & 0x1 > 0)     r = (r * 0xFFFCB933BD6FAD37AA2D162D1A594001) >> 128;
            if (x & 0x2 > 0)     r = (r * 0xFFF97272373D413259A46990580E213A) >> 128;
            if (x & 0x4 > 0)     r = (r * 0xFFF2E50F5F656932EF12357CF3C7FDCC) >> 128;
            if (x & 0x8 > 0)     r = (r * 0xFFE5CACA7E10E4E61C3624EAA0941CD0) >> 128;
            if (x & 0x10 > 0)    r = (r * 0xFFCB9843D60F6159C9DB58835C926644) >> 128;
            if (x & 0x20 > 0)    r = (r * 0xFF973B41FA98C081472E6896DFB254C0) >> 128;
            if (x & 0x40 > 0)    r = (r * 0xFF2EA16466C96A3843EC78B326B52861) >> 128;
            if (x & 0x80 > 0)    r = (r * 0xFE5DEE046A99A2A811C461F1969C3053) >> 128;
            if (x & 0x100 > 0)   r = (r * 0xFCBE86C7900A88AEDCFFC83B479AA3A4) >> 128;
            if (x & 0x200 > 0)   r = (r * 0xF987A7253AC413176F2B074CF7815E54) >> 128;
            if (x & 0x400 > 0)   r = (r * 0xF3392B0822B70005940C7A398E4B70F3) >> 128;
            if (x & 0x800 > 0)   r = (r * 0xE7159475A2C29B7443B29C7FA6E889D9) >> 128;
            if (x & 0x1000 > 0)  r = (r * 0xD097F3BDFD2022B8845AD8F792AA5825) >> 128;
            if (x & 0x2000 > 0)  r = (r * 0xA9F746462D870FDF8A65DC1F90E061E5) >> 128;
            if (x & 0x4000 > 0)  r = (r * 0x70D869A156D2A1B890BB3DF62BAF32F7) >> 128;
            if (x & 0x8000 > 0)  r = (r * 0x31BE135F97D08FD981231505542FCFA6) >> 128;
            if (x & 0x10000 > 0) r = (r * 0x9AA508B5B7A84E1C677DE54F3E99BC9) >> 128;
            if (x & 0x20000 > 0) r = (r * 0x5D6AF8DEDB81196699C329225EE604) >> 128;
            if (x & 0x40000 > 0) r = (r * 0x2216E584F5FA1EA926041BEDFE98) >> 128;
            if (x & 0x80000 > 0) r = (r * 0x48A170391F7DC42444E8FA2) >> 128;
            // Stop computation here since abs(tick) < 2**20 (i.e. 776363 < 1048576)

            // Inverse r since base = 1/sqrt(1.0001)
            if (tick >= 0) r = type(uint256).max / r;

            // Downcast to UQ56.72 and round up
            sqrtP = uint128((r >> 56) + (r % Q56 > 0 ? 1 : 0));
        }
    }

    /// @dev Find tick = floor(log_u(sqrtP)), where u = sqrt(1.0001)
    function sqrtPriceToTick(uint128 sqrtP) internal pure returns (int24 tick) {
        unchecked {
            require(MIN_SQRT_P <= sqrtP && sqrtP <= MAX_SQRT_P);
            uint256 x = uint256(sqrtP);

            // Find msb of sqrtP (since sqrtP < 2^128, we start the check at 2**64)
            uint256 xc = x;
            uint256 msb;
            if (xc >= 0x10000000000000000) { xc >>= 64; msb += 64; }
            if (xc >= 0x100000000)         { xc >>= 32; msb += 32; }
            if (xc >= 0x10000)             { xc >>= 16; msb += 16; }
            if (xc >= 0x100)               { xc >>= 8;  msb += 8; }
            if (xc >= 0x10)                { xc >>= 4;  msb += 4; }
            if (xc >= 0x4)                 { xc >>= 2;  msb += 2; }
            if (xc >= 0x2)                 { xc >>= 1;  msb += 1; }

            // Calculate integer part of log2(x), can be negative
            int256 r = (int256(msb) - 72) << 64; // Q64.64

            // Scale up x to make it 127-bit
            uint256 z = x << (127 - msb);

            // Do the following to find the decimal part of log2(x) (i.e. from 63th bit downwards):
            //   1. sqaure z
            //   2. if z becomes 128 bit:
            //   3.     half z
            //   4.     set this bit to 1
            // And stop at 46th bit since we have enough decimal places to continue to next steps
            z = (z * z) >> 127;    if (z >= Q128) { z >>= 1; r |= 0x8000000000000000; }
            z = (z * z) >> 127;    if (z >= Q128) { z >>= 1; r |= 0x4000000000000000; }
            z = (z * z) >> 127;    if (z >= Q128) { z >>= 1; r |= 0x2000000000000000; }
            z = (z * z) >> 127;    if (z >= Q128) { z >>= 1; r |= 0x1000000000000000; }
            z = (z * z) >> 127;    if (z >= Q128) { z >>= 1; r |= 0x800000000000000; }
            z = (z * z) >> 127;    if (z >= Q128) { z >>= 1; r |= 0x400000000000000; }
            z = (z * z) >> 127;    if (z >= Q128) { z >>= 1; r |= 0x200000000000000; }
            z = (z * z) >> 127;    if (z >= Q128) { z >>= 1; r |= 0x100000000000000; }
            z = (z * z) >> 127;    if (z >= Q128) { z >>= 1; r |= 0x80000000000000; }
            z = (z * z) >> 127;    if (z >= Q128) { z >>= 1; r |= 0x40000000000000; }
            z = (z * z) >> 127;    if (z >= Q128) { z >>= 1; r |= 0x20000000000000; }
            z = (z * z) >> 127;    if (z >= Q128) { z >>= 1; r |= 0x10000000000000; }
            z = (z * z) >> 127;    if (z >= Q128) { z >>= 1; r |= 0x8000000000000; }
            z = (z * z) >> 127;    if (z >= Q128) { z >>= 1; r |= 0x4000000000000; }
            z = (z * z) >> 127;    if (z >= Q128) { z >>= 1; r |= 0x2000000000000; }
            z = (z * z) >> 127;    if (z >= Q128) { z >>= 1; r |= 0x1000000000000; }
            z = (z * z) >> 127;    if (z >= Q128) { z >>= 1; r |= 0x800000000000; }
            z = (z * z) >> 127;    if (z >= Q128) { z >>= 1; r |= 0x400000000000; }

            // Change the base of log2(x) to sqrt(1.0001). (i.e. log_u(x) = log2(u) * log_u(2))
            r *= 255738958999603826347141;

            // Add both the maximum positive and negative errors to r to see if it diverges into two different ticks.
            // If it does, calculate the upper tick's sqrtP and compare with the given sqrtP.
            int24 tickUpper = int24((r + 17996007701288367970265332090599899137) >> 128);
            int24 tickLower = int24(
                r < -230154402537746701963478439606373042805014528 ? (r - 98577143636729737466164032634120830977) >> 128 :
                r < -162097929153559009270803518120019400513814528 ? (r - 527810000259722480933883300202676225) >> 128 :
                r >> 128
            );
            tick = (tickUpper == tickLower || sqrtP >= tickToSqrtPrice(tickUpper)) ? tickUpper : tickLower;
        }
    }

    struct Cache {
        int24 tick;
        uint128 sqrtP;
    }

    /// @dev memoize last tick-to-sqrtP conversion
    function tickToSqrtPriceMemoized(Cache memory cache, int24 tick) internal pure returns (uint128 sqrtP) {
        if (tick == cache.tick) sqrtP = cache.sqrtP;
        else {
            sqrtP = tickToSqrtPrice(tick);
            cache.sqrtP = sqrtP;
            cache.tick = tick;
        }
    }
}