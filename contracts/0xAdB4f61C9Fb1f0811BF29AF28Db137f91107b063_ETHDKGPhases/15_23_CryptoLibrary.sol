// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

import "contracts/libraries/errors/CryptoLibraryErrors.sol";

/*
    Author: Philipp Schindler
    Source code and documentation available on Github: https://github.com/PhilippSchindler/ethdkg

    Copyright 2019 Philipp Schindler

    Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

// TODO: we may want to check some of the functions to ensure that they are valid.
//       some of them may not be if there are attempts they are called with
//       invalid points.
library CryptoLibrary {
    ////////////////////////////////////////////////////////////////////////////////////////////////
    //// CRYPTOGRAPHIC CONSTANTS

    ////////
    //// These constants are updated to reflect our version, not theirs.
    ////////

    // GROUP_ORDER is the are the number of group elements in the groups G1, G2, and GT.
    uint256 public constant GROUP_ORDER =
        21888242871839275222246405745257275088548364400416034343698204186575808495617;
    // FIELD_MODULUS is the prime number over which the elliptic curves are based.
    uint256 public constant FIELD_MODULUS =
        21888242871839275222246405745257275088696311157297823662689037894645226208583;
    // CURVE_B is the constant of the elliptic curve for G1:
    //
    //      y^2 == x^3 + CURVE_B,
    //
    // with CURVE_B == 3.
    uint256 public constant CURVE_B = 3;

    // G1 == (G1_X, G1_Y) is the standard generator for group G1.
    // uint256 constant G1_X  = 1;
    // uint256 constant G1_Y  = 2;
    // H1 == (H1X, H1Y) = hashToG1([]byte("MadHive Rocks!") from golang code;
    // this is another generator for G1 and dlog_G1(H1) is unknown,
    // which is necessary for security.
    //
    // In the future, the specific value of H1 could be changed every time
    // there is a change in validator set. For right now, though, this will
    // be a fixed constant.
    uint256 public constant H1_X =
        2788159449993757418373833378244720686978228247930022635519861138679785693683;
    uint256 public constant H1_Y =
        12344898367754966892037554998108864957174899548424978619954608743682688483244;

    // H2 == ([H2_XI, H2_X], [H2_YI, H2_Y]) is the *negation* of the
    // standard generator of group G2.
    // The standard generator comes from the Ethereum bn256 Go code.
    // The negated form is required because bn128_pairing check in Solidty requires this.
    //
    // In particular, to check
    //
    //      sig = H(msg)^privK
    //
    // is a valid signature for
    //
    //      pubK = H2Gen^privK,
    //
    // we need
    //
    //      e(sig, H2Gen) == e(H(msg), pubK).
    //
    // This is equivalent to
    //
    //      e(sig, H2) * e(H(msg), pubK) == 1.
    uint256 public constant H2_XI =
        11559732032986387107991004021392285783925812861821192530917403151452391805634;
    uint256 public constant H2_X =
        10857046999023057135944570762232829481370756359578518086990519993285655852781;
    uint256 public constant H2_YI =
        17805874995975841540914202342111839520379459829704422454583296818431106115052;
    uint256 public constant H2_Y =
        13392588948715843804641432497768002650278120570034223513918757245338268106653;

    uint256 public constant G1_X = 1;
    uint256 public constant G1_Y = 2;

    // TWO_256_MOD_P == 2^256 mod FIELD_MODULUS;
    // this is used in hashToBase to obtain a more uniform hash value.
    uint256 public constant TWO_256_MOD_P =
        6350874878119819312338956282401532409788428879151445726012394534686998597021;

    // P_MINUS1 == -1 mod FIELD_MODULUS;
    // this is used in sign0 and all ``negative'' values have this sign value.
    uint256 public constant P_MINUS1 =
        21888242871839275222246405745257275088696311157297823662689037894645226208582;

    // P_MINUS2 == FIELD_MODULUS - 2;
    // this is the exponent used in finite field inversion.
    uint256 public constant P_MINUS2 =
        21888242871839275222246405745257275088696311157297823662689037894645226208581;

    // P_MINUS1_OVER2 == (FIELD_MODULUS - 1) / 2;
    // this is the exponent used in computing the Legendre symbol and is
    // also used in sign0 as the cutoff point between ``positive'' and
    // ``negative'' numbers.
    uint256 public constant P_MINUS1_OVER2 =
        10944121435919637611123202872628637544348155578648911831344518947322613104291;

    // P_PLUS1_OVER4 == (FIELD_MODULUS + 1) / 4;
    // this is the exponent used in computing finite field square roots.
    uint256 public constant P_PLUS1_OVER4 =
        5472060717959818805561601436314318772174077789324455915672259473661306552146;

    // baseToG1 constants
    //
    // These are precomputed constants which are independent of t.
    // All of these constants are computed modulo FIELD_MODULUS.
    //
    // (-1 + sqrt(-3))/2
    uint256 public constant HASH_CONST_1 =
        2203960485148121921418603742825762020974279258880205651966;
    // sqrt(-3)
    uint256 public constant HASH_CONST_2 =
        4407920970296243842837207485651524041948558517760411303933;
    // 1/3
    uint256 public constant HASH_CONST_3 =
        14592161914559516814830937163504850059130874104865215775126025263096817472389;
    // 1 + CURVE_B (CURVE_B == 3)
    uint256 public constant HASH_CONST_4 = 4;

    ////////////////////////////////////////////////////////////////////////////////////////////////
    //// HELPER FUNCTIONS

    function discreteLogEquality(
        uint256[2] memory x1,
        uint256[2] memory y1,
        uint256[2] memory x2,
        uint256[2] memory y2,
        uint256[2] memory proof
    ) internal view returns (bool proofIsValid) {
        uint256[2] memory tmp1;
        uint256[2] memory tmp2;

        tmp1 = bn128Multiply([x1[0], x1[1], proof[1]]);
        tmp2 = bn128Multiply([y1[0], y1[1], proof[0]]);
        uint256[2] memory t1prime = bn128Add([tmp1[0], tmp1[1], tmp2[0], tmp2[1]]);

        tmp1 = bn128Multiply([x2[0], x2[1], proof[1]]);
        tmp2 = bn128Multiply([y2[0], y2[1], proof[0]]);
        uint256[2] memory t2prime = bn128Add([tmp1[0], tmp1[1], tmp2[0], tmp2[1]]);

        uint256 challenge = uint256(keccak256(abi.encodePacked(x1, y1, x2, y2, t1prime, t2prime)));
        proofIsValid = challenge == proof[0];
    }

    function bn128Add(uint256[4] memory input) internal view returns (uint256[2] memory result) {
        // computes P + Q
        // input: 4 values of 256 bit each
        //  *) x-coordinate of point P
        //  *) y-coordinate of point P
        //  *) x-coordinate of point Q
        //  *) y-coordinate of point Q

        bool success;
        assembly ("memory-safe") {
            // 0x06     id of precompiled bn256Add contract
            // 0        number of ether to transfer
            // 128      size of call parameters, i.e. 128 bytes total
            // 64       size of call return value, i.e. 64 bytes / 512 bit for a BN256 curve point
            success := staticcall(not(0), 0x06, input, 128, result, 64)
        }

        if (!success) {
            revert CryptoLibraryErrors.EllipticCurveAdditionFailed();
        }
    }

    function bn128Multiply(
        uint256[3] memory input
    ) internal view returns (uint256[2] memory result) {
        // computes P*x
        // input: 3 values of 256 bit each
        //  *) x-coordinate of point P
        //  *) y-coordinate of point P
        //  *) scalar x

        bool success;
        assembly ("memory-safe") {
            // 0x07     id of precompiled bn256ScalarMul contract
            // 0        number of ether to transfer
            // 96       size of call parameters, i.e. 96 bytes total (256 bit for x, 256 bit for y, 256 bit for scalar)
            // 64       size of call return value, i.e. 64 bytes / 512 bit for a BN256 curve point
            success := staticcall(not(0), 0x07, input, 96, result, 64)
        }
        if (!success) {
            revert CryptoLibraryErrors.EllipticCurveMultiplicationFailed();
        }
    }

    function bn128CheckPairing(uint256[12] memory input) internal view returns (bool) {
        uint256[1] memory result;
        bool success;
        assembly ("memory-safe") {
            // 0x08     id of precompiled bn256Pairing contract     (checking the elliptic curve pairings)
            // 0        number of ether to transfer
            // 384       size of call parameters, i.e. 12*256 bits == 384 bytes
            // 32        size of result (one 32 byte boolean!)
            success := staticcall(not(0), 0x08, input, 384, result, 32)
        }
        if (!success) {
            revert CryptoLibraryErrors.EllipticCurvePairingFailed();
        }
        return result[0] == 1;
    }

    //// Begin new helper functions added
    // expmod perform modular exponentiation with all variables uint256;
    // this is used in legendre, sqrt, and invert.
    //
    // Copied from
    //      https://medium.com/@rbkhmrcr/precompiles-solidity-e5d29bd428c4
    // and slightly modified
    function expmod(uint256 base, uint256 e, uint256 m) internal view returns (uint256 result) {
        bool success;
        assembly ("memory-safe") {
            // define pointer
            let p := mload(0x40)
            // store data assembly-favouring ways
            mstore(p, 0x20) // Length of Base
            mstore(add(p, 0x20), 0x20) // Length of Exponent
            mstore(add(p, 0x40), 0x20) // Length of Modulus
            mstore(add(p, 0x60), base) // Base
            mstore(add(p, 0x80), e) // Exponent
            mstore(add(p, 0xa0), m) // Modulus
            // 0x05           id of precompiled modular exponentiation contract
            // 0xc0 == 192    size of call parameters
            // 0x20 ==  32    size of result
            success := staticcall(gas(), 0x05, p, 0xc0, p, 0x20)
            // data
            result := mload(p)
        }
        if (!success) {
            revert CryptoLibraryErrors.ModularExponentiationFailed();
        }
    }

    // Sign takes byte slice message and private key privK.
    // It then calls HashToG1 with message as input and performs scalar
    // multiplication to produce the resulting signature.
    function sign(
        bytes memory message,
        uint256 privK
    ) internal view returns (uint256[2] memory sig) {
        uint256[2] memory hashPoint;
        hashPoint = hashToG1(message);
        sig = bn128Multiply([hashPoint[0], hashPoint[1], privK]);
    }

    // Verify takes byte slice message, signature sig (element of G1),
    // public key pubK (element of G2), and checks that sig is a valid
    // signature for pubK for message. Also look at the definition of H2.
    function verifySignature(
        bytes memory message,
        uint256[2] memory sig,
        uint256[4] memory pubK
    ) internal view returns (bool v) {
        uint256[2] memory hashPoint;
        hashPoint = hashToG1(message);
        v = bn128CheckPairing(
            [
                sig[0],
                sig[1],
                H2_XI,
                H2_X,
                H2_YI,
                H2_Y,
                hashPoint[0],
                hashPoint[1],
                pubK[0],
                pubK[1],
                pubK[2],
                pubK[3]
            ]
        );
    }

    // Optimized version written in ASM of the Verify function. It takes byte slice message, signature
    // sig (element of G1), public key pubK (element of G2), and checks that sig is a valid signature
    // for pubK for message. Also look at the definition of H2.
    function verifySignatureASM(
        bytes memory message,
        uint256[2] memory sig,
        uint256[4] memory pubK
    ) internal view returns (bool v) {
        uint256[2] memory hashPoint;
        hashPoint = hashToG1ASM(message);
        v = bn128CheckPairing(
            [
                sig[0],
                sig[1],
                H2_XI,
                H2_X,
                H2_YI,
                H2_Y,
                hashPoint[0],
                hashPoint[1],
                pubK[0],
                pubK[1],
                pubK[2],
                pubK[3]
            ]
        );
    }

    // HashToG1 takes byte slice message and outputs an element of G1.
    // This function is based on the Fouque and Tibouchi 2012 paper
    // ``Indifferentiable Hashing to Barreto--Naehrig Curves''.
    // There are a couple improvements included from Wahby and Boneh's 2019 paper
    // ``Fast and simple constant-time hashing to the BLS12-381 elliptic curve''.
    //
    // There are two parts: hashToBase and baseToG1.
    //
    // hashToBase takes a byte slice (with additional bytes for domain
    // separation) and returns uint256 t with 0 <= t < FIELD_MODULUS; thus,
    // it is a valid element of F_p, the base field of the elliptic curve.
    // This is the ``hash'' portion of the hash function. The two byte
    // values are used for domain separation in order to obtain independent
    // hash functions.
    //
    // baseToG1 is a deterministic function which takes t in F_p and returns
    // a valid element of the elliptic curve.
    //
    // By combining hashToBase and baseToG1, we get a HashToG1. Now, we
    // perform this operation twice because without it, we would not have
    // a valid hash function. The reason is that baseToG1 only maps to
    // approximately 9/16ths of the points in the elliptic curve.
    // By doing this twice (with independent hash functions) and adding the
    // resulting points, we have an actual hash function to G1.
    // For more information relating to the hash-to-curve theory,
    // see the FT 2012 paper.
    function hashToG1(bytes memory message) internal view returns (uint256[2] memory h) {
        uint256 t0 = hashToBase(message, 0x00, 0x01);
        uint256 t1 = hashToBase(message, 0x02, 0x03);

        uint256[2] memory h0 = baseToG1(t0);
        uint256[2] memory h1 = baseToG1(t1);

        // Each BaseToG1 call involves a check that we have a valid curve point.
        // Here, we check that we have a valid curve point after the addition.
        // Again, this is to ensure that even if something strange happens, we
        // will not return an invalid curvepoint.
        h = bn128Add([h0[0], h0[1], h1[0], h1[1]]);

        if (!bn128IsOnCurve(h)) {
            revert CryptoLibraryErrors.HashPointNotOnCurve();
        }
        if (!safeSigningPoint(h)) {
            revert CryptoLibraryErrors.HashPointUnsafeForSigning();
        }
    }

    /// HashToG1 takes byte slice message and outputs an element of G1. Optimized version of `hashToG1`
    /// written in EVM assembly.
    function hashToG1ASM(bytes memory message) internal view returns (uint256[2] memory h) {
        assembly ("memory-safe") {
            function revertASM(str, len) {
                let ptr := mload(0x40)
                let startPtr := ptr
                mstore(ptr, hex"08c379a0") // keccak256('Error(string)')[0:4]
                ptr := add(ptr, 0x4)
                mstore(ptr, 0x20)
                ptr := add(ptr, 0x20)
                mstore(ptr, len) // string length
                ptr := add(ptr, 0x20)
                mstore(ptr, str)
                ptr := add(ptr, 0x20)
                revert(startPtr, sub(ptr, startPtr))
            }

            function memCopy(dest, src, len) {
                if lt(len, 32) {
                    revertASM("invalid length", 18)
                }
                // Copy word-length chunks while possible
                for {

                } gt(len, 31) {
                    len := sub(len, 32)
                } {
                    mstore(dest, mload(src))
                    src := add(src, 32)
                    dest := add(dest, 32)
                }

                if iszero(eq(len, 0)) {
                    // Copy remaining bytes
                    let mask := sub(exp(256, sub(32, len)), 1)
                    // e.g len = 4, yields
                    // mask    = 00000000ffffffffffffffffffffffffffffffffffffffffffffffffffffffff
                    // notMask = ffffffff00000000000000000000000000000000000000000000000000000000
                    let srcpart := and(mload(src), not(mask))
                    let destpart := and(mload(dest), mask)
                    mstore(dest, or(destpart, srcpart))
                }
            }

            function bn128CheckPairing(ptr, paramPtr, x, y) -> result {
                mstore(add(ptr, 0xb0), x)
                mstore(add(ptr, 0xc0), y)
                memCopy(ptr, paramPtr, 0xb0)
                let success := staticcall(gas(), 0x08, ptr, 384, ptr, 32)
                if iszero(success) {
                    revertASM("invalid bn128 pairing", 21)
                }
                result := mload(ptr)
            }

            function bn128IsOnCurve(p0, p1) -> result {
                let o1 := mulmod(p0, p0, FIELD_MODULUS)
                o1 := mulmod(p0, o1, FIELD_MODULUS)
                o1 := addmod(o1, 3, FIELD_MODULUS)
                let o2 := mulmod(p1, p1, FIELD_MODULUS)
                result := eq(o1, o2)
            }

            function baseToG1(ptr, t, output) {
                let fp := add(ptr, 0xc0)
                let ap1 := mulmod(t, t, FIELD_MODULUS)

                let alpha := mulmod(ap1, addmod(ap1, HASH_CONST_4, FIELD_MODULUS), FIELD_MODULUS)
                // invert alpha
                mstore(add(ptr, 0x60), alpha)
                mstore(add(ptr, 0x80), P_MINUS2)
                if iszero(staticcall(gas(), 0x05, ptr, 0xc0, fp, 0x20)) {
                    revertASM("exp mod failed at 1", 19)
                }
                alpha := mload(fp)

                ap1 := mulmod(ap1, ap1, FIELD_MODULUS)

                let x := mulmod(ap1, HASH_CONST_2, FIELD_MODULUS)
                x := mulmod(x, alpha, FIELD_MODULUS)
                // negating x
                x := sub(FIELD_MODULUS, x)
                x := addmod(x, HASH_CONST_1, FIELD_MODULUS)

                let x_three := mulmod(x, x, FIELD_MODULUS)
                x_three := mulmod(x_three, x, FIELD_MODULUS)
                x_three := addmod(x_three, 3, FIELD_MODULUS)
                mstore(add(ptr, 0x80), P_PLUS1_OVER4)
                mstore(add(ptr, 0x60), x_three)
                if iszero(staticcall(gas(), 0x05, ptr, 0xc0, fp, 0x20)) {
                    revertASM("exp mod failed at 2", 19)
                }

                let ymul := 1
                if gt(t, P_MINUS1_OVER2) {
                    ymul := P_MINUS1
                }
                let y := mulmod(mload(fp), ymul, FIELD_MODULUS)
                let y_two := mulmod(y, y, FIELD_MODULUS)
                if eq(x_three, y_two) {
                    mstore(output, x)
                    mstore(add(output, 0x20), y)
                    leave
                }
                x := addmod(x, 1, FIELD_MODULUS)
                x := sub(FIELD_MODULUS, x)
                x_three := mulmod(x, x, FIELD_MODULUS)
                x_three := mulmod(x_three, x, FIELD_MODULUS)
                x_three := addmod(x_three, 3, FIELD_MODULUS)
                mstore(add(ptr, 0x60), x_three)
                if iszero(staticcall(gas(), 0x05, ptr, 0xc0, fp, 0x20)) {
                    revertASM("exp mod failed at 3", 19)
                }
                y := mulmod(mload(fp), ymul, FIELD_MODULUS)
                y_two := mulmod(y, y, FIELD_MODULUS)
                if eq(x_three, y_two) {
                    mstore(output, x)
                    mstore(add(output, 0x20), y)
                    leave
                }
                ap1 := addmod(mulmod(t, t, FIELD_MODULUS), 4, FIELD_MODULUS)
                x := mulmod(ap1, ap1, FIELD_MODULUS)
                x := mulmod(x, ap1, FIELD_MODULUS)
                x := mulmod(x, HASH_CONST_3, FIELD_MODULUS)
                x := mulmod(x, alpha, FIELD_MODULUS)
                x := sub(FIELD_MODULUS, x)
                x := addmod(x, 1, FIELD_MODULUS)
                x_three := mulmod(x, x, FIELD_MODULUS)
                x_three := mulmod(x_three, x, FIELD_MODULUS)
                x_three := addmod(x_three, 3, FIELD_MODULUS)
                mstore(add(ptr, 0x60), x_three)
                if iszero(staticcall(gas(), 0x05, ptr, 0xc0, fp, 0x20)) {
                    revertASM("exp mod failed at 4", 19)
                }
                y := mulmod(mload(fp), ymul, FIELD_MODULUS)
                mstore(output, x)
                mstore(add(output, 0x20), y)
            }

            function hashToG1(ptr, messageptr, messagesize, output) {
                let size := add(messagesize, 1)
                memCopy(add(ptr, 1), messageptr, messagesize)
                mstore8(ptr, 0x00)
                let h0 := keccak256(ptr, size)
                mstore8(ptr, 0x01)
                let h1 := keccak256(ptr, size)
                mstore8(ptr, 0x02)
                let h2 := keccak256(ptr, size)
                mstore8(ptr, 0x03)
                let h3 := keccak256(ptr, size)
                mstore(ptr, 0x20)
                mstore(add(ptr, 0x20), 0x20)
                mstore(add(ptr, 0x40), 0x20)
                mstore(add(ptr, 0xa0), FIELD_MODULUS)
                h1 := addmod(h1, mulmod(h0, TWO_256_MOD_P, FIELD_MODULUS), FIELD_MODULUS)
                h2 := addmod(h3, mulmod(h2, TWO_256_MOD_P, FIELD_MODULUS), FIELD_MODULUS)
                baseToG1(ptr, h1, output)
                let x1 := mload(output)
                let y1 := mload(add(output, 0x20))
                let success := bn128IsOnCurve(x1, y1)
                if iszero(success) {
                    revertASM("x1 y1 not in curve", 18)
                }
                baseToG1(ptr, h2, output)
                let x2 := mload(output)
                let y2 := mload(add(output, 0x20))
                success := bn128IsOnCurve(x2, y2)
                if iszero(success) {
                    revertASM("x2 y2 not in curve", 18)
                }
                mstore(ptr, x1)
                mstore(add(ptr, 0x20), y1)
                mstore(add(ptr, 0x40), x2)
                mstore(add(ptr, 0x60), y2)
                if iszero(staticcall(gas(), 0x06, ptr, 128, ptr, 64)) {
                    revertASM("bn256 add failed", 16)
                }
                let x := mload(ptr)
                let y := mload(add(ptr, 0x20))
                success := bn128IsOnCurve(x, y)
                if iszero(success) {
                    revertASM("x y not in curve", 16)
                }
                if or(iszero(x), eq(y, 1)) {
                    revertASM("point not safe to sign", 22)
                }
                mstore(output, x)
                mstore(add(output, 0x20), y)
            }

            let messageptr := add(message, 0x20)
            let messagesize := mload(message)
            let ptr := mload(0x40)
            hashToG1(ptr, messageptr, messagesize, h)
        }
    }

    // baseToG1 is a deterministic map from the base field F_p to the elliptic
    // curve. All values in [0, FIELD_MODULUS) are valid including 0, so we
    // do not need to worry about any exceptions.
    //
    // We remember our elliptic curve has the form
    //
    //      y^2 == x^3 + b
    //          == g(x)
    //
    // The main idea is that given t, we can produce x values x1, x2, and x3
    // such that
    //
    //      g(x1)*g(x2)*g(x3) == s^2.
    //
    // The above equation along with quadratic residues means that
    // when s != 0, at least one of g(x1), g(x2), or g(x3) is a square,
    // which implies that x1, x2, or x3 is a valid x-coordinate to a point
    // on the elliptic curve. For uniqueness, we choose the smallest coordinate.
    // In our construction, the above s value will always be nonzero, so we will
    // always have a solution. This means that baseToG1 is a deterministic
    // map from the base field to the elliptic curve.
    function baseToG1(uint256 t) internal view returns (uint256[2] memory h) {
        // ap1 and ap2 are temporary variables, originally named to represent
        // alpha part 1 and alpha part 2. Now they are somewhat general purpose
        // variables due to using too many variables on stack.
        uint256 ap1;
        uint256 ap2;

        // One of the main constants variables to form x1, x2, and x3
        // is alpha, which has the following definition:
        //
        //      alpha == (ap1*ap2)^(-1)
        //            == [t^2*(t^2 + h4)]^(-1)
        //
        //      ap1 == t^2
        //      ap2 == t^2 + h4
        //      h4  == HASH_CONST_4
        //
        // Defining alpha helps decrease the calls to expmod,
        // which is the most expensive operation we do.
        uint256 alpha;
        ap1 = mulmod(t, t, FIELD_MODULUS);
        ap2 = addmod(ap1, HASH_CONST_4, FIELD_MODULUS);
        alpha = mulmod(ap1, ap2, FIELD_MODULUS);
        alpha = invert(alpha);

        // Another important constant which is used when computing x3 is tmp,
        // which has the following definition:
        //
        //      tmp == (t^2 + h4)^3
        //          == ap2^3
        //
        //      h4  == HASH_CONST_4
        //
        // This is cheap to compute because ap2 has not changed
        uint256 tmp;
        tmp = mulmod(ap2, ap2, FIELD_MODULUS);
        tmp = mulmod(tmp, ap2, FIELD_MODULUS);

        // When computing x1, we need to compute t^4. ap1 will be the
        // temporary variable which stores this value now:
        //
        // Previous definition:
        //      ap1 == t^2
        //
        // Current definition:
        //      ap1 == t^4
        ap1 = mulmod(ap1, ap1, FIELD_MODULUS);

        // One of the potential x-coordinates of our elliptic curve point:
        //
        //      x1 == h1 - h2*t^4*alpha
        //         == h1 - h2*ap1*alpha
        //
        //      ap1 == t^4 (note previous assignment)
        //      h1  == HASH_CONST_1
        //      h2  == HASH_CONST_2
        //
        // When t == 0, x1 is a valid x-coordinate of a point on the elliptic
        // curve, so we need no exceptions; this is different than the original
        // Fouque and Tibouchi 2012 paper. This comes from the fact that
        // 0^(-1) == 0 mod p, as we use expmod for inversion.
        uint256 x1;
        x1 = mulmod(HASH_CONST_2, ap1, FIELD_MODULUS);
        x1 = mulmod(x1, alpha, FIELD_MODULUS);
        x1 = neg(x1);
        x1 = addmod(x1, HASH_CONST_1, FIELD_MODULUS);

        // One of the potential x-coordinates of our elliptic curve point:
        //
        //      x2 == -1 - x1
        uint256 x2;
        x2 = addmod(x1, 1, FIELD_MODULUS);
        x2 = neg(x2);

        // One of the potential x-coordinates of our elliptic curve point:
        //
        //      x3 == 1 - h3*tmp*alpha
        //
        //      h3 == HASH_CONST_3
        uint256 x3;
        x3 = mulmod(HASH_CONST_3, tmp, FIELD_MODULUS);
        x3 = mulmod(x3, alpha, FIELD_MODULUS);
        x3 = neg(x3);
        x3 = addmod(x3, 1, FIELD_MODULUS);

        // We now focus on determing residue1; if residue1 == 1,
        // then x1 is a valid x-coordinate for a point on E(F_p).
        //
        // When computing residues, the original FT 2012 paper suggests
        // blinding for security. We do not use that suggestion here
        // because of the possibility of a random integer being returned
        // which is 0, which would completely destroy the output.
        // Additionally, computing random numbers on Ethereum is difficult.
        uint256 y;
        y = mulmod(x1, x1, FIELD_MODULUS);
        y = mulmod(y, x1, FIELD_MODULUS);
        y = addmod(y, CURVE_B, FIELD_MODULUS);
        int256 residue1 = legendre(y);

        // We now focus on determing residue2; if residue2 == 1,
        // then x2 is a valid x-coordinate for a point on E(F_p).
        y = mulmod(x2, x2, FIELD_MODULUS);
        y = mulmod(y, x2, FIELD_MODULUS);
        y = addmod(y, CURVE_B, FIELD_MODULUS);
        int256 residue2 = legendre(y);

        // i is the index which gives us the correct x value (x1, x2, or x3)
        int256 i = ((residue1 - 1) * (residue2 - 3)) / 4 + 1;

        // This is the simplest way to determine which x value is correct
        // but is not secure. If possible, we should improve this.
        uint256 x;
        if (i == 1) {
            x = x1;
        } else if (i == 2) {
            x = x2;
        } else {
            x = x3;
        }

        // Now that we know x, we compute y
        y = mulmod(x, x, FIELD_MODULUS);
        y = mulmod(y, x, FIELD_MODULUS);
        y = addmod(y, CURVE_B, FIELD_MODULUS);
        y = sqrt(y);

        // We now determine the sign of y based on t; this is a change from
        // the original FT 2012 paper and uses the suggestion from WB 2019.
        //
        // This is done to save computation, as using sign0 reduces the
        // number of calls to expmod from 5 to 4; currently, we call expmod
        // for inversion (alpha), two legendre calls (for residue1 and
        // residue2), and one sqrt call.
        // This change nullifies the proof in FT 2012 that we have a valid
        // hash function. Whether the proof could be slightly modified to
        // compensate for this change is possible but not currently known.
        //
        // (CHG: At the least, I am not sure that the proof holds, nor am I
        // able to see how the proof could potentially be fixed in order
        // for the hash function to be admissible.)
        //
        // If this is included as a precompile, it may be worth it to ignore
        // the cost savings in order to ensure uniformity of the hash function.
        // Also, we would need to change legendre so that legendre(0) == 1,
        // or else things would fail when t == 0. We could also have a separate
        // function for the sign determiniation.
        uint256 ySign;
        ySign = sign0(t);
        y = mulmod(y, ySign, FIELD_MODULUS);

        // Before returning the value, we check to make sure we have a valid
        // curve point. This ensures we will always have a valid point.
        // From Fouque-Tibouchi 2012, the only way to get an invalid point is
        // when t == 0, but we have already taken care of that to ensure that
        // when t == 0, we still return a valid curve point.
        if (!bn128IsOnCurve([x, y])) {
            revert CryptoLibraryErrors.PointNotOnCurve();
        }

        h[0] = x;
        h[1] = y;
    }

    // invert computes the multiplicative inverse of t modulo FIELD_MODULUS.
    // When t == 0, s == 0.
    function invert(uint256 t) internal view returns (uint256 s) {
        s = expmod(t, P_MINUS2, FIELD_MODULUS);
    }

    // sqrt computes the multiplicative square root of t modulo FIELD_MODULUS.
    // sqrt does not check that a square root is possible; see legendre.
    function sqrt(uint256 t) internal view returns (uint256 s) {
        s = expmod(t, P_PLUS1_OVER4, FIELD_MODULUS);
    }

    // legendre computes the legendre symbol of t with respect to FIELD_MODULUS.
    // That is, legendre(t) == 1 when a square root of t exists modulo
    // FIELD_MODULUS, legendre(t) == -1 when a square root of t does not exist
    // modulo FIELD_MODULUS, and legendre(t) == 0 when t == 0 mod FIELD_MODULUS.
    function legendre(uint256 t) internal view returns (int256 chi) {
        uint256 s = expmod(t, P_MINUS1_OVER2, FIELD_MODULUS);
        if (s != 0) {
            chi = 2 * int256(s & 1) - 1;
        } else {
            chi = 0;
        }
    }

    // AggregateSignatures takes takes the signature array sigs, index array
    // indices, and threshold to compute the thresholded group signature.
    // After ensuring some basic requirements are met, it calls
    // LagrangeInterpolationG1 to perform this interpolation.
    //
    // To trade computation (and expensive gas costs) for space, we choose
    // to require that the multiplicative inverses modulo GROUP_ORDER be
    // entered for this function call in invArray. This allows the expensive
    // portion of gas cost to grow linearly in the size of the group rather
    // than quadratically. Additional improvements made be included
    // in the future.
    //
    // One advantage to how this function is designed is that we do not need
    // to know the number of participants, as we only require inverses which
    // will be required as deteremined by indices.
    function aggregateSignatures(
        uint256[2][] memory sigs,
        uint256[] memory indices,
        uint256 threshold,
        uint256[] memory invArray
    ) internal view returns (uint256[2] memory) {
        if (sigs.length != indices.length) {
            revert CryptoLibraryErrors.SignatureIndicesLengthMismatch(sigs.length, indices.length);
        }

        if (sigs.length <= threshold) {
            revert CryptoLibraryErrors.SignaturesLengthThresholdNotMet(sigs.length, threshold);
        }

        uint256 maxIndex = computeArrayMax(indices);
        if (!checkInverses(invArray, maxIndex)) {
            revert CryptoLibraryErrors.InverseArrayIncorrect();
        }
        uint256[2] memory grpsig;
        grpsig = lagrangeInterpolationG1(sigs, indices, threshold, invArray);
        return grpsig;
    }

    // LagrangeInterpolationG1 efficiently computes Lagrange interpolation
    // of pointsG1 using indices as the point location in the finite field.
    // This is an efficient method of Lagrange interpolation as we assume
    // finite field inverses are in invArray.
    function lagrangeInterpolationG1(
        uint256[2][] memory pointsG1,
        uint256[] memory indices,
        uint256 threshold,
        uint256[] memory invArray
    ) internal view returns (uint256[2] memory) {
        if (pointsG1.length != indices.length) {
            revert CryptoLibraryErrors.SignatureIndicesLengthMismatch(
                pointsG1.length,
                indices.length
            );
        }
        uint256[2] memory val;
        val[0] = 0;
        val[1] = 0;
        uint256 i;
        uint256 ell;
        uint256 idxJ;
        uint256 idxK;
        uint256 rj;
        uint256 rjPartial;
        uint256[2] memory partialVal;
        for (i = 0; i < indices.length; i++) {
            idxJ = indices[i];
            if (i > threshold) {
                break;
            }
            rj = 1;
            for (ell = 0; ell < indices.length; ell++) {
                idxK = indices[ell];
                if (ell > threshold) {
                    break;
                }
                if (idxK == idxJ) {
                    continue;
                }
                rjPartial = liRjPartialConst(idxK, idxJ, invArray);
                rj = mulmod(rj, rjPartial, GROUP_ORDER);
            }
            partialVal = pointsG1[i];
            partialVal = bn128Multiply([partialVal[0], partialVal[1], rj]);
            val = bn128Add([val[0], val[1], partialVal[0], partialVal[1]]);
        }
        return val;
    }

    // liRjPartialConst computes the partial constants of rj in Lagrange
    // interpolation based on the the multiplicative inverses in invArray.
    function liRjPartialConst(
        uint256 k,
        uint256 j,
        uint256[] memory invArray
    ) internal pure returns (uint256) {
        if (k == j) {
            revert CryptoLibraryErrors.KMustNotEqualJ();
        }
        uint256 tmp1 = k;
        uint256 tmp2;
        if (k > j) {
            tmp2 = k - j;
        } else {
            tmp1 = mulmod(tmp1, GROUP_ORDER - 1, GROUP_ORDER);
            tmp2 = j - k;
        }
        tmp2 = invArray[tmp2 - 1];
        tmp2 = mulmod(tmp1, tmp2, GROUP_ORDER);
        return tmp2;
    }

    // TODO: identity (0, 0) should be considered a valid point
    function bn128IsOnCurve(uint256[2] memory point) internal pure returns (bool) {
        // check if the provided point is on the bn128 curve (y**2 = x**3 + 3)
        return
            mulmod(point[1], point[1], FIELD_MODULUS) ==
            addmod(
                mulmod(point[0], mulmod(point[0], point[0], FIELD_MODULUS), FIELD_MODULUS),
                3,
                FIELD_MODULUS
            );
    }

    // hashToBase takes in a byte slice message and bytes c0 and c1 for
    // domain separation. The idea is that we treat keccak256 as a random
    // oracle which outputs uint256. The problem is that we want to hash modulo
    // FIELD_MODULUS (p, a prime number). Just using uint256 mod p will lead
    // to bias in the distribution. In particular, there is bias towards the
    // lower 5% of the numbers in [0, FIELD_MODULUS). The 1-norm error between
    // s0 mod p and a uniform distribution is ~ 1/4. By itself, this 1-norm
    // error is not too enlightening, but continue reading, as we will compare
    // it with another distribution that has much smaller 1-norm error.
    //
    // To obtain a better distribution with less bias, we take 2 uint256 hash
    // outputs (using c0 and c1 for domain separation so the hashes are
    // independent) and ``combine them'' to form a ``uint512''. Of course,
    // this is not possible in practice, so we view the combined output as
    //
    //      x == s0*2^256 + s1.
    //
    // This implies that x (combined from s0 and s1 in this way) is a
    // 512-bit uint. If s0 and s1 are uniformly distributed modulo 2^256,
    // then x is uniformly distributed modulo 2^512. We now want to reduce
    // this modulo FIELD_MODULUS (p). This is done as follows:
    //
    //      x mod p == [(s0 mod p)*(2^256 mod p)] + s1 mod p.
    //
    // This allows us easily compute the result without needing to implement
    // higher precision. The 1-norm error between x mod p and a uniform
    // distribution is ~1e-77. This is a *signficant* improvement from s0 mod p.
    // For all practical purposes, there is no difference from a
    // uniform distribution.
    function hashToBase(
        bytes memory message,
        bytes1 c0,
        bytes1 c1
    ) internal pure returns (uint256 t) {
        uint256 s0 = uint256(keccak256(abi.encodePacked(c0, message)));
        uint256 s1 = uint256(keccak256(abi.encodePacked(c1, message)));
        t = addmod(mulmod(s0, TWO_256_MOD_P, FIELD_MODULUS), s1, FIELD_MODULUS);
    }

    // safeSigningPoint ensures that the HashToG1 point we are returning
    // is safe to sign; in particular, it is not Infinity (the group identity
    // element) or the standard curve generator (curveGen) or its negation.
    //
    // TODO: may want to confirm point is valid first as well as reducing mod field prime
    function safeSigningPoint(uint256[2] memory input) internal pure returns (bool) {
        if (input[0] == 0 || input[0] == 1) {
            return false;
        } else {
            return true;
        }
    }

    // neg computes the additive inverse (the negative) modulo FIELD_MODULUS.
    function neg(uint256 t) internal pure returns (uint256 s) {
        if (t == 0) {
            s = 0;
        } else {
            s = FIELD_MODULUS - t;
        }
    }

    // sign0 computes the sign of a finite field element.
    // sign0 is used instead of legendre in baseToG1 from the suggestion
    // of WB 2019.
    function sign0(uint256 t) internal pure returns (uint256 s) {
        s = 1;
        if (t > P_MINUS1_OVER2) {
            s = P_MINUS1;
        }
    }

    // checkInverses takes maxIndex as the maximum element of indices
    // (used in AggregateSignatures) and checks that all of the necessary
    // multiplicative inverses in invArray are correct and present.
    function checkInverses(
        uint256[] memory invArray,
        uint256 maxIndex
    ) internal pure returns (bool) {
        uint256 k;
        uint256 kInv;
        uint256 res;
        bool validInverses = true;
        if ((maxIndex - 1) > invArray.length) {
            revert CryptoLibraryErrors.InvalidInverseArrayLength();
        }
        for (k = 1; k < maxIndex; k++) {
            kInv = invArray[k - 1];
            res = mulmod(k, kInv, GROUP_ORDER);
            if (res != 1) {
                validInverses = false;
                break;
            }
        }
        return validInverses;
    }

    // checkIndices determines whether or not each of these arrays contain
    // unique indices. There is no reason any index should appear twice.
    // All indices should be in {1, 2, ..., n} and this function ensures this.
    // n is the total number of participants; that is, n == addresses.length.
    function checkIndices(
        uint256[] memory honestIndices,
        uint256[] memory dishonestIndices,
        uint256 n
    ) internal pure returns (bool validIndices) {
        validIndices = true;
        uint256 k;
        uint256 f;
        uint256 curIdx;

        assert(n > 0);
        assert(n < 256);

        // Make sure each honestIndices list is unique
        for (k = 0; k < honestIndices.length; k++) {
            curIdx = honestIndices[k];
            // All indices must be between 1 and n
            if ((curIdx == 0) || (curIdx > n)) {
                validIndices = false;
                break;
            }
            // Only check for equality with previous indices
            if ((f & (1 << curIdx)) == 0) {
                f |= 1 << curIdx;
            } else {
                // We have seen this index before; invalid index sets
                validIndices = false;
                break;
            }
        }
        if (!validIndices) {
            return validIndices;
        }

        // Make sure each dishonestIndices list is unique and does not match
        // any from honestIndices.
        for (k = 0; k < dishonestIndices.length; k++) {
            curIdx = dishonestIndices[k];
            // All indices must be between 1 and n
            if ((curIdx == 0) || (curIdx > n)) {
                validIndices = false;
                break;
            }
            // Only check for equality with previous indices
            if ((f & (1 << curIdx)) == 0) {
                f |= 1 << curIdx;
            } else {
                // We have seen this index before; invalid index sets
                validIndices = false;
                break;
            }
        }
        return validIndices;
    }

    // computeArrayMax computes the maximum uin256 element of uint256Array
    function computeArrayMax(uint256[] memory uint256Array) internal pure returns (uint256) {
        uint256 curVal;
        uint256 maxVal = uint256Array[0];
        for (uint256 i = 1; i < uint256Array.length; i++) {
            curVal = uint256Array[i];
            if (curVal > maxVal) {
                maxVal = curVal;
            }
        }
        return maxVal;
    }
}