// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

/**
 * @title LibSecp256k1
 *
 * @notice Library for secp256k1 elliptic curve computations
 *
 * @dev This library was developed to efficiently compute aggregated public
 *      keys for Schnorr signatures based on secp256k1, i.e. it is _not_ a
 *      general purpose elliptic curve library!
 *
 *      References to the Ethereum Yellow Paper are based on the following
 *      version: "BERLIN VERSION beacfbd – 2022-10-24".
 */
library LibSecp256k1 {
    using LibSecp256k1 for LibSecp256k1.Point;
    using LibSecp256k1 for LibSecp256k1.JacobianPoint;

    uint private constant ADDRESS_MASK =
        0x000000000000000000000000FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

    // -- Secp256k1 Constants --
    //
    // Taken from https://www.secg.org/sec2-v2.pdf.
    // See section 2.4.1 "Recommended Parameters secp256k1".

    uint private constant _A = 0;
    uint private constant _B = 7;
    uint private constant _P =
        0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFC2F;

    /// @dev Returns the order of the group.
    function Q() internal pure returns (uint) {
        return
            0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141;
    }

    /// @dev Returns the generator G.
    ///      Note that the generator is also called base point.
    function G() internal pure returns (Point memory) {
        return Point({
            x: 0x79be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798,
            y: 0x483ada7726a3c4655da4fbfc0e1108a8fd17b448a68554199c47d08ffb10d4b8
        });
    }

    /// @dev Returns the zero point.
    function ZERO_POINT() internal pure returns (Point memory) {
        return Point({x: 0, y: 0});
    }

    // -- (Affine) Point --

    /// @dev Point encapsulates a secp256k1 point in Affine coordinates.
    struct Point {
        uint x;
        uint y;
    }

    /// @dev Returns the Ethereum address of `self`.
    ///
    /// @dev An Ethereum address is defined as the rightmost 160 bits of the
    ///      keccak256 hash of the concatenation of the hex-encoded x and y
    ///      coordinates of the corresponding ECDSA public key.
    ///      See "Appendix F: Signing Transactions" §134 in the Yellow Paper.
    function toAddress(Point memory self) internal pure returns (address) {
        address addr;
        // Functionally equivalent Solidity code:
        // addr = address(uint160(uint(keccak256(abi.encode(self.x, self.y)))));
        assembly ("memory-safe") {
            addr := and(keccak256(self, 0x40), ADDRESS_MASK)
        }
        return addr;
    }

    /// @dev Returns Affine point `self` in Jacobian coordinates.
    function toJacobian(Point memory self)
        internal
        pure
        returns (JacobianPoint memory)
    {
        return JacobianPoint({x: self.x, y: self.y, z: 1});
    }

    /// @dev Returns whether `self` is the zero point.
    function isZeroPoint(Point memory self) internal pure returns (bool) {
        return (self.x | self.y) == 0;
    }

    /// @dev Returns whether `self` is a point on the curve.
    ///
    /// @dev The secp256k1 curve is specified as y² ≡ x³ + ax + b (mod P)
    ///      where:
    ///         a = 0
    ///         b = 7
    function isOnCurve(Point memory self) internal pure returns (bool) {
        uint left = mulmod(self.y, self.y, _P);
        // Note that adding a * x can be waived as ∀x: a * x = 0.
        uint right =
            addmod(mulmod(self.x, mulmod(self.x, self.x, _P), _P), _B, _P);

        return left == right;
    }

    /// @dev Returns the parity of `self`'s y coordinate.
    ///
    /// @dev The value 0 represents an even y value and 1 represents an odd y
    ///      value.
    ///      See "Appendix F: Signing Transactions" in the Yellow Paper.
    function yParity(Point memory self) internal pure returns (uint) {
        return self.y & 1;
    }

    // -- Jacobian Point --

    /// @dev JacobianPoint encapsulates a secp256k1 point in Jacobian
    ///      coordinates.
    struct JacobianPoint {
        uint x;
        uint y;
        uint z;
    }

    /// @dev Returns Jacobian point `self` in Affine coordinates.
    ///
    /// @custom:invariant Reverts iff out of gas.
    /// @custom:invariant Does not run into an infinite loop.
    function toAffine(JacobianPoint memory self)
        internal
        pure
        returns (Point memory)
    {
        Point memory result;

        // Compute z⁻¹, i.e. the modular inverse of self.z.
        uint zInv = _invMod(self.z);

        // Compute (z⁻¹)² (mod P)
        uint zInv_2 = mulmod(zInv, zInv, _P);

        // Compute self.x * (z⁻¹)² (mod P), i.e. the x coordinate of given
        // Jacobian point in Affine representation.
        result.x = mulmod(self.x, zInv_2, _P);

        // Compute self.y * (z⁻¹)³ (mod P), i.e. the y coordinate of given
        // Jacobian point in Affine representation.
        result.y = mulmod(self.y, mulmod(zInv, zInv_2, _P), _P);

        return result;
    }

    /// @dev Adds Affine point `p` to Jacobian point `self`.
    ///
    ///      It is the caller's responsibility to ensure given points are on the
    ///      curve!
    ///
    ///      Computation based on: https://www.hyperelliptic.org/EFD/g1p/auto-shortw-jacobian.html#addition-madd-2007-bl.
    ///
    ///      Note that the formula assumes z2 = 1, which always holds if z2's
    ///      point is given in Affine coordinates.
    ///
    ///      Note that eventhough the function is marked as pure, to be
    ///      understood as only being dependent on the input arguments, it
    ///      nevertheless has side effects by writing the result into the
    ///      `self` memory variable.
    ///
    /// @custom:invariant Only mutates `self` memory variable.
    /// @custom:invariant Reverts iff out of gas.
    /// @custom:invariant Uses constant amount of gas.
    function addAffinePoint(JacobianPoint memory self, Point memory p)
        internal
        pure
    {
        // Addition formula:
        //      x = r² - j - (2 * v)             (mod P)
        //      y = (r * (v - x)) - (2 * y1 * j) (mod P)
        //      z = (z1 + h)² - z1² - h²         (mod P)
        //
        // where:
        //      r = 2 * (s - y1) (mod P)
        //      j = h * i        (mod P)
        //      v = x1 * i       (mod P)
        //      h = u - x1       (mod P)
        //      s = y2 * z1³     (mod P)       Called s2 in reference
        //      i = 4 * h²       (mod P)
        //      u = x2 * z1²     (mod P)       Called u2 in reference
        //
        // and:
        //      x1 = self.x
        //      y1 = self.y
        //      z1 = self.z
        //      x2 = p.x
        //      y2 = p.y
        //
        // Note that in order to save memory allocations the result is stored
        // in the self variable, i.e. the following holds true after the
        // functions execution:
        //      x = self.x
        //      y = self.y
        //      z = self.z

        // Cache self's coordinates on stack.
        uint x1 = self.x;
        uint y1 = self.y;
        uint z1 = self.z;

        // Compute z1_2 = z1²     (mod P)
        //              = z1 * z1 (mod P)
        uint z1_2 = mulmod(z1, z1, _P);

        // Compute h = u        - x1       (mod P)
        //           = u        + (P - x1) (mod P)
        //           = x2 * z1² + (P - x1) (mod P)
        //
        // Unchecked because the only protected operation performed is P - x1
        // where x1 is guaranteed by the caller to be an x coordinate belonging
        // to a point on the curve, i.e. being less than P.
        uint h;
        unchecked {
            h = addmod(mulmod(p.x, z1_2, _P), _P - x1, _P);
        }

        // Compute h_2 = h²    (mod P)
        //             = h * h (mod P)
        uint h_2 = mulmod(h, h, _P);

        // Compute i = 4 * h² (mod P)
        uint i = mulmod(4, h_2, _P);

        // Compute z = (z1 + h)² - z1²       - h²       (mod P)
        //           = (z1 + h)² - z1²       + (P - h²) (mod P)
        //           = (z1 + h)² + (P - z1²) + (P - h²) (mod P)
        //             ╰───────╯   ╰───────╯   ╰──────╯
        //               left         mid       right
        //
        // Unchecked because the only protected operations performed are
        // subtractions from P where the subtrahend is the result of a (mod P)
        // computation, i.e. the subtrahend being guaranteed to be less than P.
        unchecked {
            uint left = mulmod(addmod(z1, h, _P), addmod(z1, h, _P), _P);
            uint mid = _P - z1_2;
            uint right = _P - h_2;

            self.z = addmod(left, addmod(mid, right, _P), _P);
        }

        // Compute v = x1 * i (mod P)
        uint v = mulmod(x1, i, _P);

        // Compute j = h * i (mod P)
        uint j = mulmod(h, i, _P);

        // Compute r = 2 * (s               - y1)       (mod P)
        //           = 2 * (s               + (P - y1)) (mod P)
        //           = 2 * ((y2 * z1³)      + (P - y1)) (mod P)
        //           = 2 * ((y2 * z1² * z1) + (P - y1)) (mod P)
        //
        // Unchecked because the only protected operation performed is P - y1
        // where y1 is guaranteed by the caller to be an y coordinate belonging
        // to a point on the curve, i.e. being less than P.
        uint r;
        unchecked {
            r = mulmod(
                2,
                addmod(mulmod(p.y, mulmod(z1_2, z1, _P), _P), _P - y1, _P),
                _P
            );
        }

        // Compute x = r² - j - (2 * v)             (mod P)
        //           = r² - j + (P - (2 * v))       (mod P)
        //           = r² + (P - j) + (P - (2 * v)) (mod P)
        //                  ╰─────╯   ╰───────────╯
        //                    mid         right
        //
        // Unchecked because the only protected operations performed are
        // subtractions from P where the subtrahend is the result of a (mod P)
        // computation, i.e. the subtrahend being guaranteed to be less than P.
        unchecked {
            uint r_2 = mulmod(r, r, _P);
            uint mid = _P - j;
            uint right = _P - mulmod(2, v, _P);

            self.x = addmod(r_2, addmod(mid, right, _P), _P);
        }

        // Compute y = (r * (v - x))       - (2 * y1 * j)       (mod P)
        //           = (r * (v - x))       + (P - (2 * y1 * j)) (mod P)
        //           = (r * (v + (P - x))) + (P - (2 * y1 * j)) (mod P)
        //             ╰─────────────────╯   ╰────────────────╯
        //                    left                 right
        //
        // Unchecked because the only protected operations performed are
        // subtractions from P where the subtrahend is the result of a (mod P)
        // computation, i.e. the subtrahend being guaranteed to be less than P.
        unchecked {
            uint left = mulmod(r, addmod(v, _P - self.x, _P), _P);
            uint right = _P - mulmod(2, mulmod(y1, j, _P), _P);

            self.y = addmod(left, right, _P);
        }
    }

    // -- Private Helpers --

    /// @dev Returns the modular inverse of `x` for modulo `_P`.
    ///
    ///      It is the caller's responsibility to ensure `x` is less than `_P`!
    ///
    ///      The modular inverse of `x` is x⁻¹ such that x * x⁻¹ ≡ 1 (mod P).
    ///
    /// @dev Modified from Jordi Baylina's [ecsol](https://github.com/jbaylina/ecsol/blob/c2256afad126b7500e6f879a9369b100e47d435d/ec.sol#L51-L67).
    ///
    /// @custom:invariant Reverts iff out of gas.
    /// @custom:invariant Does not run into an infinite loop.
    function _invMod(uint x) private pure returns (uint) {
        uint t;
        uint q;
        uint newT = 1;
        uint r = _P;

        assembly ("memory-safe") {
            // Implemented in assembly to circumvent division-by-zero
            // and over-/underflow protection.
            //
            // Functionally equivalent Solidity code:
            //      while (x != 0) {
            //          q = r / x;
            //          (t, newT) = (newT, addmod(t, (_P - mulmod(q, newT, _P)), _P));
            //          (r, x) = (x, r - (q * x));
            //      }
            //
            // For the division r / x, x is guaranteed to not be zero via the
            // loop condition.
            //
            // The subtraction of form P - mulmod(_, _, P) is guaranteed to not
            // underflow due to the subtrahend being a (mod P) result,
            // i.e. the subtrahend being guaranteed to be less than P.
            //
            // The subterm q * x is guaranteed to not overflow because
            // q * x ≤ r due to q = ⎣r / x⎦.
            //
            // The term r - (q * x) is guaranteed to not underflow because
            // q * x ≤ r and therefore r - (q * x) ≥ 0.
            for {} x {} {
                q := div(r, x)

                let tmp := t
                t := newT
                newT := addmod(tmp, sub(_P, mulmod(q, newT, _P)), _P)

                tmp := r
                r := x
                x := sub(tmp, mul(q, x))
            }
        }

        return t;
    }
}