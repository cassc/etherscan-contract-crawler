// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "../helper/PackedOrderId.sol";
import "../../../interfaces/ILiquidityPool.sol";
import "../../../interfaces/IPairManager.sol";
import "./LiquidityMath.sol";
import "./../helper/BitMathLiquidity.sol";

import "hardhat/console.sol";
import "../helper/Convert.sol";
import "../exchange/BitMath.sol";
import "../../../interfaces/IRebalanceStrategy.sol";

library PoolLiquidity {
    using U128Math for uint128;
    using Convert for int128;
    using Convert for int256;
    int256 public constant PNL_DENOMINATOR = 10**18;
    using PackedOrderId for bytes32;
    using PoolLiquidity for PoolLiquidityInfo;
    struct PoolLiquidityInfo {
        address pairManager;
        address strategy;
        // the last updated liquidity in quote
        //        uint128 lastUpdatePip;
        //        uint128 lastUpdateBaseLiquidity;
        // total pool liquidity converted to quote
        // each deposit must update
        // totalQuoteDeposited += base2quote(baseAmount, price) + quoteAmount
        // each remove must update
        // totalQuoteDeposited -= base2quote(baseAmount, price) + quoteAmount
        uint128 totalQuoteDeposited;
        // all-time profit & loss per share
        // this value can negative
        uint128 totalFundingCertificates;
        uint128 baseLiquidity;
        uint128 quoteLiquidity;
        // each pool only hold up to 256 limit orders
        // because of the gas limit
        // we don't need to hold more than 256 orders
        // each array push, remove costs ~20k gas
        // so we just need to replace new order to the filled orders
        bytes32[256] supplyOrders;
        // to identify the filled orders, we use the following variables
        // a bit set, marks that the limit order at that bit position is filled
        // each bit position represents the `supplyOrders` index
        // 1 means filled
        // 0 means not
        // eg:
        // bit pos: 1 2 3 4 5 6 7 8 9 10
        //          0 0 0 1 0 0 0 1 0 0
        // means supplyOrders[4] and supplyOrders[8] has been filled
        // other orders have not been filled
        // In an other word:
        // 1 means replaceable
        // 0 means there's a pending order at supplyOrders[bitPos]
        // full name: Supply order removable bit positions
        // NOTE: initialize should set this var to type(int256).max
        int128 soRemovablePosBuy;
        int128 soRemovablePosSell;
    }

    function pushSupply(
        bytes32[256] storage supplyOrders,
        ILiquidityPool.ReBalanceState memory state,
        bytes32 value
    ) internal {
        if (value.isBuy()) {
            // side is buy
            require(state.soRemovablePosBuy != 0, "No slot to push");
            uint256 pos = rightMostSetBitPos(state.soRemovablePosBuy);
            supplyOrders[pos] = value;
            state.soRemovablePosBuy = setPosToZero(
                state.soRemovablePosBuy,
                pos
            );
        } else {
            // side sell
            require(state.soRemovablePosSell != 0, "No slot to push");
            uint256 pos = rightMostSetBitPos(state.soRemovablePosSell);
            supplyOrders[BitMathLiquidity.getPosOfSell(uint128(pos))] = value;
            state.soRemovablePosSell = setPosToZero(
                state.soRemovablePosSell,
                pos
            );
        }
    }

    /// @dev unset bit with given position in a int128 bitmask
    /// Example: given mask = 0x1111...1111, position = 2, return 0x1111...1011
    function clearBitPositionInt128(int128 mask, uint8 position)
        internal
        pure
        returns (int128)
    {
        return mask & (~(int128(1) << position));
    }

    // @dev set bit at `bitPos` to 1
    // Example: given oldSo 000...000, bitPos = 2, return 000...010
    function markSoRemovablePos(int128 oldSo, uint8 bitPos)
        internal
        view
        returns (int128 newSo)
    {
        return oldSo | int128(uint128(1 << bitPos));
    }

    // @dev set bit at `bitPos` to 1 with Int256
    // Example: given oldSo 000...000, bitPos = 2, return 000...010
    function markSoRemovablePosInt256(int256 oldSo, uint128 bitPos)
        internal
        view
        returns (int256 newSo)
    {
        return oldSo | int256(uint256(1 << bitPos));
    }

    // @dev find the right most set bit position
    // Example: given n = 18 (010010), return 2
    // given n = 19 (010011), return 1
    /*
    Algorithm: (Example 12(1100))
    Let I/P be 12 (1100)
    1. Take two’s complement of the given no as all bits are reverted
    except the first ‘1’ from right to left (0100)
    2  Do a bit-wise & with original no, this will return no with the
    required one only (0100)
    3  Take the log2 of the no, you will get (position – 1) (2)
    4  Add 1 (3)

    Explanation –

    (n&~(n-1)) always return the binary number containing the rightmost set bit as 1.
    if N = 12 (1100) then it will return 4 (100)
    Here log2 will return you, the number of times we can express that number in a power of two.
    For all binary numbers containing only the rightmost set bit as 1 like 2, 4, 8, 16, 32….
    We will find that position of rightmost set bit is always equal to log2(Number)+1

    Ref: https://www.geeksforgeeks.org/position-of-rightmost-set-bit/
    */
    function rightMostSetBitPos(int128 n) internal pure returns (uint128) {
        return uint128(log2(uint256(int256((n & -n)))));
    }

    // manually tested on Remix
    function rightMostSetBitPosUint256(int256 n)
        internal
        pure
        returns (uint256)
    {
        return log2(uint256(n & -n));
    }

    function rightMostUnSetBitPosInt256(int256 n)
        internal
        pure
        returns (uint256)
    {
        n = ~n;
        return log2(uint256(n & -n));
    }

    function leftMostUnsetBitPos(int128 n) internal view returns (uint8) {
        n = n ^ type(int128).max;
        return uint8(BitMath.mostSignificantBit(uint256(uint128(n))));
    }

    // Simple Method Loop through all bits in an integer, check if a bit is set and if it is, then increment the set bit count.
    // TODO Need to find a save gas solution
    // currently spent approx. 20k gas to count 100 bits
    // ref: https://www.geeksforgeeks.org/count-set-bits-in-an-integer/?ref=lbp
    function countBitSet(int128 n) internal pure returns (uint8 count) {
        while (n != 0) {
            count += uint8(uint128(n & 1));
            n >>= 1;
        }
    }

    function countBitSet(uint256 n) internal pure returns (uint8 count) {
        while (n != 0) {
            count += uint8(n & 1);
            n >>= 1;
        }
    }

    // @dev just rename the function to avoid confusion
    // Because `so` mark `0` as pending orders
    // so we just need to count the unset bit in the given `so`
    function countPendingSoOrder(int128 so)
        internal
        pure
        returns (uint8 count)
    {
        return countUnsetBit(so);
    }

    // @dev count unset bit in given int128 n
    // Example: given 17 (10001), return 3
    // The idea is to toggle bits in O(1) time. Then apply any of the methods discussed in count set bits article.
    // In GCC, we can directly count set bits using __builtin_popcount(). First toggle the bits and then apply above function __builtin_popcount().
    // Ref: https://www.geeksforgeeks.org/count-unset-bits-number/
    // unit test available in test/unit/TestPoolLiquidityLibrary.test.ts #L211 -> L227
    function countUnsetBit(int128 n) internal pure returns (uint8 count) {
        int128 x = n;

        // Make all bits set MSB
        // (including MSB)

        // This makes sure two bits
        // (From MSB and including MSB)
        // are set
        n |= n >> 1;

        // This makes sure 4 bits
        // (From MSB and including MSB)
        // are set
        n |= n >> 2;

        n |= n >> 4;
        n |= n >> 8;
        n |= n >> 16;
        n |= n >> 32;
        n |= n >> 64;
        n |= n >> 128;
        return _countBit128(x ^ n);
    }

    function _countBit128(int128 x) private pure returns (uint8) {
        // To store the count
        // of set bits
        uint8 setBits = 0;
        while (x != 0) {
            x = x & (x - 1);
            setBits++;
        }

        return setBits;
    }

    //copy form https://ethereum.stackexchange.com/questions/8086/logarithm-math-operation-in-solidity
    function log2(uint256 x) internal pure returns (uint256 y) {
        assembly {
            let arg := x
            x := sub(x, 1)
            x := or(x, div(x, 0x02))
            x := or(x, div(x, 0x04))
            x := or(x, div(x, 0x10))
            x := or(x, div(x, 0x100))
            x := or(x, div(x, 0x10000))
            x := or(x, div(x, 0x100000000))
            x := or(x, div(x, 0x10000000000000000))
            x := or(x, div(x, 0x100000000000000000000000000000000))
            x := add(x, 1)
            let m := mload(0x40)
            mstore(
                m,
                0xf8f9cbfae6cc78fbefe7cdc3a1793dfcf4f0e8bbd8cec470b6a28a7a5a3e1efd
            )
            mstore(
                add(m, 0x20),
                0xf5ecf1b3e9debc68e1d9cfabc5997135bfb7a7a3938b7b606b5b4b3f2f1f0ffe
            )
            mstore(
                add(m, 0x40),
                0xf6e4ed9ff2d6b458eadcdf97bd91692de2d4da8fd2d0ac50c6ae9a8272523616
            )
            mstore(
                add(m, 0x60),
                0xc8c0b887b0a8a4489c948c7f847c6125746c645c544c444038302820181008ff
            )
            mstore(
                add(m, 0x80),
                0xf7cae577eec2a03cf3bad76fb589591debb2dd67e0aa9834bea6925f6a4a2e0e
            )
            mstore(
                add(m, 0xa0),
                0xe39ed557db96902cd38ed14fad815115c786af479b7e83247363534337271707
            )
            mstore(
                add(m, 0xc0),
                0xc976c13bb96e881cb166a933a55e490d9d56952b8d4e801485467d2362422606
            )
            mstore(
                add(m, 0xe0),
                0x753a6d1b65325d0c552a4d1345224105391a310b29122104190a110309020100
            )
            mstore(0x40, add(m, 0x100))
            let
                magic
            := 0x818283848586878898a8b8c8d8e8f929395969799a9b9d9e9faaeb6bedeeff
            let
                shift
            := 0x100000000000000000000000000000000000000000000000000000000000000
            let a := div(mul(x, magic), shift)
            y := div(mload(add(m, sub(255, a))), shift)
            y := add(
                y,
                mul(
                    256,
                    gt(
                        arg,
                        0x8000000000000000000000000000000000000000000000000000000000000000
                    )
                )
            )
        }
    }

    // function to calculate the return amounts of base and quote
    function calculateReturnAmounts(
        uint128 quoteDeposited,
        uint128 totalQuoteDeposited,
        uint128 poolBaseLiquidity,
        uint128 poolQuoteLiquidity
    ) internal pure returns (uint128 baseAmount, uint128 quoteAmount) {
        baseAmount = (quoteDeposited * poolBaseLiquidity) / totalQuoteDeposited;
        quoteAmount =
            (quoteDeposited * poolQuoteLiquidity) /
            totalQuoteDeposited;
    }

    /// @notice canculate the pool pnl
    /// poolPnl = deltaPip / _basisPoint * _baseLiquidity
    function calculatePoolPnl(
        int128 _deltaPip,
        uint256 _basisPoint,
        uint128 _baseLiquidity
    ) internal pure returns (int128) {
        return
            (_deltaPip * int128(_baseLiquidity)) / int128(uint128(_basisPoint));
    }

    function getCurrentPipAndBasisPoint(PoolLiquidityInfo memory _pool)
        internal
        view
        returns (uint128 pip, uint128 _basisPoint)
    {
        return IPairManager(_pool.pairManager).getCurrentPipAndBasisPoint();
    }

    function updateLiquidity(
        PoolLiquidityInfo storage pool,
        uint128 baseAmount,
        uint128 quoteAmount,
        uint128 totalQuoteDeposited,
        uint128 addedFundCertificates
    ) internal {
        unchecked {
            pool.baseLiquidity += baseAmount;
            pool.quoteLiquidity += quoteAmount;
            pool.totalQuoteDeposited += totalQuoteDeposited;
            pool.totalFundingCertificates += addedFundCertificates;
        }
    }

    function removeLiquidity(
        PoolLiquidityInfo storage pool,
        uint128 newBaseAmount,
        uint128 newQuoteAmount,
        uint128 totalQuoteDeposited,
        uint128 removedFundCertificates
    ) internal {
        unchecked {
            // should never overflow
            pool.baseLiquidity = newBaseAmount;
            pool.quoteLiquidity = newQuoteAmount;
            pool.totalQuoteDeposited -= totalQuoteDeposited;
            pool.totalFundingCertificates -= removedFundCertificates;
        }
    }

    // @dev get user's Pnl
    // divided by the PNL_DENOMINATOR
    function getUserPnl(PoolLiquidityInfo memory _pool, int256 userDepositQ)
        internal
        view
        returns (int128)
    {
        return 0;
    }

    function getUserBaseQuoteOut(
        PoolLiquidityInfo memory _pool,
        uint128 quoteLiquidity,
        uint128 baseLiquidity,
        uint128 totalPoolLiquidityQ,
        uint128 userClaimableQ
    ) internal view returns (uint128 base, uint128 quote) {
        base = uint128(
            LiquidityMath.baseOut(
                baseLiquidity,
                userClaimableQ,
                totalPoolLiquidityQ
            )
        );
        quote = uint128(
            LiquidityMath.quoteOut(
                quoteLiquidity,
                userClaimableQ,
                totalPoolLiquidityQ
            )
        );
    }

    function setPosToZero(int128 soRemovablePos, uint256 pos)
        private
        view
        returns (int128)
    {
        return soRemovablePos & ~int128(uint128((1 << pos)));
    }
}