// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

library ShackledMath {
    /** @dev Get the minimum of two numbers */
    function min(int256 a, int256 b) internal pure returns (int256) {
        return a < b ? a : b;
    }

    /** @dev Get the maximum of two numbers */
    function max(int256 a, int256 b) internal pure returns (int256) {
        return a > b ? a : b;
    }

    /** @dev perform a modulo operation, with support for negative numbers */
    function mod(int256 n, int256 m) internal pure returns (int256) {
        if (n < 0) {
            return ((n % m) + m) % m;
        } else {
            return n % m;
        }
    }

    /** @dev 'randomly' select n numbers between 0 and m 
    (useful for getting a randomly sampled index)
    */
    function randomIdx(
        bytes32 seedModifier,
        uint256 n, // number of elements to select
        uint256 m // max value of elements
    ) internal pure returns (uint256[] memory) {
        uint256[] memory result = new uint256[](n);
        for (uint256 i = 0; i < n; i++) {
            result[i] =
                uint256(keccak256(abi.encodePacked(seedModifier, i))) %
                m;
        }
        return result;
    }

    /** @dev create a 2d array and fill with a single value */
    function get2dArray(
        uint256 m,
        uint256 q,
        int256 value
    ) internal pure returns (int256[][] memory) {
        /// Create a matrix of values with dimensions (m, q)
        int256[][] memory rows = new int256[][](m);
        for (uint256 i = 0; i < m; i++) {
            int256[] memory row = new int256[](q);
            for (uint256 j = 0; j < q; j++) {
                row[j] = value;
            }
            rows[i] = row;
        }
        return rows;
    }

    /** @dev get the absolute of a number
     */
    function abs(int256 x) internal pure returns (int256) {
        assembly {
            if slt(x, 0) {
                x := sub(0, x)
            }
        }
        return x;
    }

    /** @dev get the square root of a number
     */
    function sqrt(int256 y) internal pure returns (int256 z) {
        assembly {
            if sgt(y, 3) {
                z := y
                let x := add(div(y, 2), 1)
                for {

                } slt(x, z) {

                } {
                    z := x
                    x := div(add(div(y, x), x), 2)
                }
            }
            if and(slt(y, 4), sgt(y, 0)) {
                z := 1
            }
        }
    }

    /** @dev get the hypotenuse of a triangle given the length of 2 sides
     */
    function hypot(int256 x, int256 y) internal pure returns (int256) {
        int256 sumsq;
        assembly {
            let xsq := mul(x, x)
            let ysq := mul(y, y)
            sumsq := add(xsq, ysq)
        }

        return sqrt(sumsq);
    }

    /** @dev addition between two vectors (size 3)
     */
    function vector3Add(int256[3] memory v1, int256[3] memory v2)
        internal
        pure
        returns (int256[3] memory result)
    {
        assembly {
            mstore(result, add(mload(v1), mload(v2)))
            mstore(
                add(result, 0x20),
                add(mload(add(v1, 0x20)), mload(add(v2, 0x20)))
            )
            mstore(
                add(result, 0x40),
                add(mload(add(v1, 0x40)), mload(add(v2, 0x40)))
            )
        }
    }

    /** @dev subtraction between two vectors (size 3)
     */
    function vector3Sub(int256[3] memory v1, int256[3] memory v2)
        internal
        pure
        returns (int256[3] memory result)
    {
        assembly {
            mstore(result, sub(mload(v1), mload(v2)))
            mstore(
                add(result, 0x20),
                sub(mload(add(v1, 0x20)), mload(add(v2, 0x20)))
            )
            mstore(
                add(result, 0x40),
                sub(mload(add(v1, 0x40)), mload(add(v2, 0x40)))
            )
        }
    }

    /** @dev multiply a vector (size 3) by a constant
     */
    function vector3MulScalar(int256[3] memory v, int256 a)
        internal
        pure
        returns (int256[3] memory result)
    {
        assembly {
            mstore(result, mul(mload(v), a))
            mstore(add(result, 0x20), mul(mload(add(v, 0x20)), a))
            mstore(add(result, 0x40), mul(mload(add(v, 0x40)), a))
        }
    }

    /** @dev divide a vector (size 3) by a constant
     */
    function vector3DivScalar(int256[3] memory v, int256 a)
        internal
        pure
        returns (int256[3] memory result)
    {
        assembly {
            mstore(result, sdiv(mload(v), a))
            mstore(add(result, 0x20), sdiv(mload(add(v, 0x20)), a))
            mstore(add(result, 0x40), sdiv(mload(add(v, 0x40)), a))
        }
    }

    /** @dev get the length of a vector (size 3)
     */
    function vector3Len(int256[3] memory v) internal pure returns (int256) {
        int256 res;
        assembly {
            let x := mload(v)
            let y := mload(add(v, 0x20))
            let z := mload(add(v, 0x40))
            res := add(add(mul(x, x), mul(y, y)), mul(z, z))
        }
        return sqrt(res);
    }

    /** @dev scale and then normalise a vector (size 3)
     */
    function vector3NormX(int256[3] memory v, int256 fidelity)
        internal
        pure
        returns (int256[3] memory result)
    {
        int256 l = vector3Len(v);
        assembly {
            mstore(result, sdiv(mul(fidelity, mload(add(v, 0x40))), l))
            mstore(
                add(result, 0x20),
                sdiv(mul(fidelity, mload(add(v, 0x20))), l)
            )
            mstore(add(result, 0x40), sdiv(mul(fidelity, mload(v)), l))
        }
    }

    /** @dev get the dot-product of two vectors (size 3)
     */
    function vector3Dot(int256[3] memory v1, int256[3] memory v2)
        internal
        view
        returns (int256 result)
    {
        assembly {
            result := add(
                add(
                    mul(mload(v1), mload(v2)),
                    mul(mload(add(v1, 0x20)), mload(add(v2, 0x20)))
                ),
                mul(mload(add(v1, 0x40)), mload(add(v2, 0x40)))
            )
        }
    }

    /** @dev get the cross product of two vectors (size 3)
     */
    function crossProduct(int256[3] memory v1, int256[3] memory v2)
        internal
        pure
        returns (int256[3] memory result)
    {
        assembly {
            mstore(
                result,
                sub(
                    mul(mload(add(v1, 0x20)), mload(add(v2, 0x40))),
                    mul(mload(add(v1, 0x40)), mload(add(v2, 0x20)))
                )
            )
            mstore(
                add(result, 0x20),
                sub(
                    mul(mload(add(v1, 0x40)), mload(v2)),
                    mul(mload(v1), mload(add(v2, 0x40)))
                )
            )
            mstore(
                add(result, 0x40),
                sub(
                    mul(mload(v1), mload(add(v2, 0x20))),
                    mul(mload(add(v1, 0x20)), mload(v2))
                )
            )
        }
    }

    /** @dev linearly interpolate between two vectors (size 12)
     */
    function vector12Lerp(
        int256[12] memory v1,
        int256[12] memory v2,
        int256 ir,
        int256 scaleFactor
    ) internal view returns (int256[12] memory result) {
        int256[12] memory vd = vector12Sub(v2, v1);
        // loop through all 12 items
        assembly {
            let ix
            for {
                let i := 0
            } lt(i, 0xC) {
                // (i < 12)
                i := add(i, 1)
            } {
                /// get index of the next element
                ix := mul(i, 0x20)

                /// store into the result array
                mstore(
                    add(result, ix),
                    add(
                        // v1[i] + (ir * vd[i]) / 1e3
                        mload(add(v1, ix)),
                        sdiv(mul(ir, mload(add(vd, ix))), 1000)
                    )
                )
            }
        }
    }

    /** @dev subtraction between two vectors (size 12)
     */
    function vector12Sub(int256[12] memory v1, int256[12] memory v2)
        internal
        view
        returns (int256[12] memory result)
    {
        // loop through all 12 items
        assembly {
            let ix
            for {
                let i := 0
            } lt(i, 0xC) {
                // (i < 12)
                i := add(i, 1)
            } {
                /// get index of the next element
                ix := mul(i, 0x20)
                /// store into the result array
                mstore(
                    add(result, ix),
                    sub(
                        // v1[ix] - v2[ix]
                        mload(add(v1, ix)),
                        mload(add(v2, ix))
                    )
                )
            }
        }
    }

    /** @dev map a number from one range into another
     */
    function mapRangeToRange(
        int256 num,
        int256 inMin,
        int256 inMax,
        int256 outMin,
        int256 outMax
    ) internal pure returns (int256 res) {
        assembly {
            res := add(
                sdiv(
                    mul(sub(outMax, outMin), sub(num, inMin)),
                    sub(inMax, inMin)
                ),
                outMin
            )
        }
    }
}