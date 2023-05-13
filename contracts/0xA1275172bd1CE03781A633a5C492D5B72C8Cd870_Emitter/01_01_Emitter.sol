// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.7;

abstract contract TokenLike {
    function transfer(address, uint256) external virtual returns (bool);

    function balanceOf(address) external view virtual returns (uint256);
}

/// @notice Immutable RATE token emitter
/// @dev Contract assumes the start balance has been deposited to the contract
/// @dev If additional tokens are sent to the contract they will be distributed in the next emission;
contract Emitter {
    uint256 public immutable init; // timestamp when distribution starts, unix timestamp
    uint256 public immutable start; // token initial amount that will be distributed, WAD
    uint256 public immutable c; // WAD
    uint256 public immutable lam; // WAD

    TokenLike public immutable token; // token distributed by the contract
    address public immutable receiver; // receiver of the tokens

    uint256 public lastMonthDistributed; // last month to be distributed

    uint256 public constant e = 2718281828459045235; // WAD
    uint256 public constant WAD = 10 ** 18;
    uint256 public constant MONTH = 30 days;

    constructor(
        uint256 init_,
        uint256 start_,
        uint256 c_,
        uint256 lam_,
        address token_,
        address receiver_
    ) public {
        require(init_ > 0, "invalid constructor param init_");
        require(start_ > 0, "invalid constructor param startBlock_");
        require(c_ > 0, "invalid constructor param c_");
        require(lam_ > 0, "invalid constructor param lam_");
        require(token_ != address(0), "invalid constructor param token_");
        require(receiver_ != address(0), "invalid constructor param receiver_");
        init = init_;
        start = start_;
        c = c_;
        lam = lam_;
        token = TokenLike(token_);
        receiver = receiver_;
    }

    /// Math - from vectorized/solady, transmissions11/solmate and reflexer-labs/geb
    function add(uint x, uint y) public pure returns (uint z) {
        z = x + y;
        require(z >= x, "uint-uint-add-overflow");
    }

    function sub(uint x, uint y) public pure returns (uint z) {
        z = x - y;
        require(z <= x, "uint-uint-sub-underflow");
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, "mul-overflow");
    }

    function mulWad(int256 x, int256 y) internal pure returns (int256 r) {
        /// @solidity memory-safe-assembly
        assembly {
            // Store x * y in r for now.
            r := mul(x, y)

            // Equivalent to require(x == 0 || (x * y) / x == y)
            if iszero(or(iszero(x), eq(sdiv(r, x), y))) {
                revert(0, 0)
            }

            // Scale the result down by 1e18.
            r := sdiv(r, 1000000000000000000)
        }
    }

    /// @dev Equivalent to `(x * y) / WAD` rounded down.
    function mulWad(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Equivalent to `require(y == 0 || x <= type(uint256).max / y)`.
            if mul(y, gt(x, div(not(0), y))) {
                // Store the function selector of `MulWadFailed()`.
                mstore(0x00, 0xbac65e5b)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
            z := div(mul(x, y), WAD)
        }
    }

    /// @dev Equivalent to `x` to the power of `y`.
    /// because `x ** y = (e ** ln(x)) ** y = e ** (ln(x) * y)`.
    function powWad(int256 x, int256 y) internal pure returns (int256) {
        // Using `ln(x)` means `x` must be greater than 0.
        return expWad(mulWad(lnWad(x), y));
    }

    /// @dev Returns `exp(x)`, denominated in `WAD`.
    function expWad(int256 x) internal pure returns (int256 r) {
        // When the result is < 0.5 we return zero. This happens when
        // x <= floor(log(0.5e18) * 1e18) ~ -42e18
        if (x <= -42139678854452767551) return r;

        /// @solidity memory-safe-assembly
        assembly {
            // When the result is > (2**255 - 1) / 1e18 we can not represent it as an
            // int. This happens when x >= floor(log((2**255 - 1) / 1e18) * 1e18) ~ 135.
            if iszero(slt(x, 135305999368893231589)) {
                // Store the function selector of `ExpOverflow()`.
                mstore(0x00, 0xa37bfec9)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
        }

        // x is now in the range (-42, 136) * 1e18. Convert to (-42, 136) * 2**96
        // for more intermediate precision and a binary basis. This base conversion
        // is a multiplication by 1e18 / 2**96 = 5**18 / 2**78.
        x = (x << 78) / 5 ** 18;

        // Reduce range of x to (-½ ln 2, ½ ln 2) * 2**96 by factoring out powers
        // of two such that exp(x) = exp(x') * 2**k, where k is an integer.
        // Solving this gives k = round(x / log(2)) and x' = x - k * log(2).
        int256 k = ((x << 96) / 54916777467707473351141471128 + 2 ** 95) >> 96;
        x = x - k * 54916777467707473351141471128;

        // k is in the range [-61, 195].

        // Evaluate using a (6, 7)-term rational approximation.
        // p is made monic, we'll multiply by a scale factor later.
        int256 y = x + 1346386616545796478920950773328;
        y = ((y * x) >> 96) + 57155421227552351082224309758442;
        int256 p = y + x - 94201549194550492254356042504812;
        p = ((p * y) >> 96) + 28719021644029726153956944680412240;
        p = p * x + (4385272521454847904659076985693276 << 96);

        // We leave p in 2**192 basis so we don't need to scale it back up for the division.
        int256 q = x - 2855989394907223263936484059900;
        q = ((q * x) >> 96) + 50020603652535783019961831881945;
        q = ((q * x) >> 96) - 533845033583426703283633433725380;
        q = ((q * x) >> 96) + 3604857256930695427073651918091429;
        q = ((q * x) >> 96) - 14423608567350463180887372962807573;
        q = ((q * x) >> 96) + 26449188498355588339934803723976023;

        /// @solidity memory-safe-assembly
        assembly {
            // Div in assembly because solidity adds a zero check despite the unchecked.
            // The q polynomial won't have zeros in the domain as all its roots are complex.
            // No scaling is necessary because p is already 2**96 too large.
            r := sdiv(p, q)
        }

        // r should be in the range (0.09, 0.25) * 2**96.

        // We now need to multiply r by:
        // * the scale factor s = ~6.031367120.
        // * the 2**k factor from the range reduction.
        // * the 1e18 / 2**96 factor for base conversion.
        // We do this all at once, with an intermediate result in 2**213
        // basis, so the final right shift is always by a positive amount.
        r = int256(
            (uint256(r) * 3822833074963236453042738258902158003155416615667) >>
                uint256(195 - k)
        );
    }

    /// @dev Returns `ln(x)`, denominated in `WAD`.
    function lnWad(int256 x) internal pure returns (int256 r) {
        /// @solidity memory-safe-assembly
        assembly {
            if iszero(sgt(x, 0)) {
                // Store the function selector of `LnWadUndefined()`.
                mstore(0x00, 0x1615e638)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
        }

        // We want to convert x from 10**18 fixed point to 2**96 fixed point.
        // We do this by multiplying by 2**96 / 10**18. But since
        // ln(x * C) = ln(x) + ln(C), we can simply do nothing here
        // and add ln(2**96 / 10**18) at the end.

        // Compute k = log2(x) - 96.
        int256 k;
        /// @solidity memory-safe-assembly
        assembly {
            let v := x
            k := shl(7, lt(0xffffffffffffffffffffffffffffffff, v))
            k := or(k, shl(6, lt(0xffffffffffffffff, shr(k, v))))
            k := or(k, shl(5, lt(0xffffffff, shr(k, v))))

            // For the remaining 32 bits, use a De Bruijn lookup.
            // See: https://graphics.stanford.edu/~seander/bithacks.html
            v := shr(k, v)
            v := or(v, shr(1, v))
            v := or(v, shr(2, v))
            v := or(v, shr(4, v))
            v := or(v, shr(8, v))
            v := or(v, shr(16, v))

            // forgefmt: disable-next-item
            k := sub(
                or(
                    k,
                    byte(
                        shr(251, mul(v, shl(224, 0x07c4acdd))),
                        0x0009010a0d15021d0b0e10121619031e080c141c0f111807131b17061a05041f
                    )
                ),
                96
            )
        }

        // Reduce range of x to (1, 2) * 2**96
        // ln(2^k * x) = k * ln(2) + ln(x)
        x <<= uint256(159 - k);
        x = int256(uint256(x) >> 159);

        // Evaluate using a (8, 8)-term rational approximation.
        // p is made monic, we will multiply by a scale factor later.
        int256 p = x + 3273285459638523848632254066296;
        p = ((p * x) >> 96) + 24828157081833163892658089445524;
        p = ((p * x) >> 96) + 43456485725739037958740375743393;
        p = ((p * x) >> 96) - 11111509109440967052023855526967;
        p = ((p * x) >> 96) - 45023709667254063763336534515857;
        p = ((p * x) >> 96) - 14706773417378608786704636184526;
        p = p * x - (795164235651350426258249787498 << 96);

        // We leave p in 2**192 basis so we don't need to scale it back up for the division.
        // q is monic by convention.
        int256 q = x + 5573035233440673466300451813936;
        q = ((q * x) >> 96) + 71694874799317883764090561454958;
        q = ((q * x) >> 96) + 283447036172924575727196451306956;
        q = ((q * x) >> 96) + 401686690394027663651624208769553;
        q = ((q * x) >> 96) + 204048457590392012362485061816622;
        q = ((q * x) >> 96) + 31853899698501571402653359427138;
        q = ((q * x) >> 96) + 909429971244387300277376558375;
        /// @solidity memory-safe-assembly
        assembly {
            // Div in assembly because solidity adds a zero check despite the unchecked.
            // The q polynomial is known not to have zeros in the domain.
            // No scaling required because p is already 2**96 too large.
            r := sdiv(p, q)
        }

        // r is in the range (0, 0.125) * 2**96

        // Finalization, we need to:
        // * multiply by the scale factor s = 5.549…
        // * add ln(2**96 / 10**18)
        // * add k * ln(2)
        // * multiply by 10**18 / 2**96 = 5**18 >> 78

        // mul s * 5e18 * 2**96, base is now 5**18 * 2**192
        r *= 1677202110996718588342820967067443963516166;
        // add ln(2) * k * 5e18 * 2**192
        r +=
            16597577552685614221487285958193947469193820559219878177908093499208371 *
            k;
        // add ln(2**96 / 10**18) * 5e18 * 2**192
        r += 600920179829731861736702779321621459595472258049074101567377883020018308;
        // base conversion: mul 2**18 / 2**192
        r >>= 174;
    }

    /// Issuance calculation
    // @notice Amount at beginning of `n` blocks after launch
    // @param n Month number since start of distribution
    function startingSupplyMonths(uint256 n) public view returns (uint256) {
        return
            mulWad(
                start,
                uint256(powWad(int256(mulWad(c, e)), -int256(mul(lam, n))))
            );
    }

    // @notice Number of months since init
    // @dev Returns 1 for first month
    function currentMonth() public view returns (uint256) {
        return add(sub(now, init) / MONTH, 1);
    }

    // @notice Emits tokens for a specific month
    // @dev Reverts if already distributed in the same month
    function emitTokens() public {
        uint256 month = currentMonth();
        require(month > lastMonthDistributed, "already distributed");

        uint256 distributionAmount = sub(
            token.balanceOf(address(this)),
            startingSupplyMonths(month)
        );

        require(
            token.transfer(receiver, distributionAmount),
            "transfer failed"
        );
        lastMonthDistributed = month;
    }
}