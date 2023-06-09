// SPDX-License-Identifier: LGPL 3.0
pragma solidity ^0.8.18;

import {BN256G2} from "./BN256G2.sol";

/**
 * @title BLS operations on bn254 curve
 * @author ARPA-Network adapted from https://github.com/ChihChengLiang/bls_solidity_python
 * @dev Homepage: https://github.com/ARPA-Network/BLS-TSS-Network
 *      Signature and Point hashed to G1 are represented by affine coordinate in big-endian order, deserialized from compressed format.
 *      Public key is represented and serialized by affine coordinate Q-x-re(x0), Q-x-im(x1), Q-y-re(y0), Q-y-im(y1) in big-endian order.
 */
library BLS {
    // Field order
    uint256 public constant N = 21888242871839275222246405745257275088696311157297823662689037894645226208583;

    // Negated genarator of G2
    uint256 public constant N_G2_X1 = 11559732032986387107991004021392285783925812861821192530917403151452391805634;
    uint256 public constant N_G2_X0 = 10857046999023057135944570762232829481370756359578518086990519993285655852781;
    uint256 public constant N_G2_Y1 = 17805874995975841540914202342111839520379459829704422454583296818431106115052;
    uint256 public constant N_G2_Y0 = 13392588948715843804641432497768002650278120570034223513918757245338268106653;

    uint256 public constant FIELD_MASK = 0x3fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;

    error MustNotBeInfinity();
    error InvalidPublicKeyEncoding();
    error InvalidSignatureFormat();
    error InvalidSignature();
    error InvalidPartialSignatureFormat();
    error InvalidPartialSignatures();
    error EmptyPartialSignatures();
    error InvalidPublicKey();
    error InvalidPartialPublicKey();

    function verifySingle(uint256[2] memory signature, uint256[4] memory pubkey, uint256[2] memory message)
        public
        view
        returns (bool)
    {
        uint256[12] memory input = [
            signature[0],
            signature[1],
            N_G2_X1,
            N_G2_X0,
            N_G2_Y1,
            N_G2_Y0,
            message[0],
            message[1],
            pubkey[1],
            pubkey[0],
            pubkey[3],
            pubkey[2]
        ];
        uint256[1] memory out;
        bool success;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            success := staticcall(sub(gas(), 2000), 8, input, 384, out, 0x20)
            switch success
            case 0 { invalid() }
        }
        require(success, "");
        return out[0] != 0;
    }

    function verifyPartials(uint256[2][] memory partials, uint256[4][] memory pubkeys, uint256[2] memory message)
        public
        view
        returns (bool)
    {
        uint256[2] memory aggregatedSignature;
        uint256[4] memory aggregatedPublicKey;
        for (uint256 i = 0; i < partials.length; i++) {
            aggregatedSignature = addPoints(aggregatedSignature, partials[i]);
            aggregatedPublicKey = BN256G2.ecTwistAdd(aggregatedPublicKey, pubkeys[i]);
        }

        uint256[12] memory input = [
            aggregatedSignature[0],
            aggregatedSignature[1],
            N_G2_X1,
            N_G2_X0,
            N_G2_Y1,
            N_G2_Y0,
            message[0],
            message[1],
            aggregatedPublicKey[1],
            aggregatedPublicKey[0],
            aggregatedPublicKey[3],
            aggregatedPublicKey[2]
        ];
        uint256[1] memory out;
        bool success;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            success := staticcall(sub(gas(), 2000), 8, input, 384, out, 0x20)
            switch success
            case 0 { invalid() }
        }
        require(success, "");
        return out[0] != 0;
    }

    // TODO a simple hash and increment implementation, can be improved later
    function hashToPoint(bytes memory data) public view returns (uint256[2] memory p) {
        bool found;
        bytes32 candidateHash = keccak256(data);
        while (true) {
            (p, found) = mapToPoint(candidateHash);
            if (found) {
                break;
            }
            candidateHash = keccak256(bytes.concat(candidateHash));
        }
    }

    //  we take the y-coordinate as the lexicographically largest of the two associated with the encoded x-coordinate
    function mapToPoint(bytes32 _x) internal view returns (uint256[2] memory p, bool found) {
        uint256 y;
        uint256 x = uint256(_x) % N;
        (y, found) = deriveYOnG1(x);
        if (found) {
            p[0] = x;
            p[1] = y > N / 2 ? N - y : y;
        }
    }

    function deriveYOnG1(uint256 x) internal view returns (uint256, bool) {
        uint256 y;
        y = mulmod(x, x, N);
        y = mulmod(y, x, N);
        y = addmod(y, 3, N);
        return sqrt(y);
    }

    function isValidPublicKey(uint256[4] memory publicKey) public pure returns (bool) {
        if ((publicKey[0] >= N) || (publicKey[1] >= N) || (publicKey[2] >= N || (publicKey[3] >= N))) {
            return false;
        } else {
            return isOnCurveG2(publicKey);
        }
    }

    function fromBytesPublicKey(bytes memory point) public pure returns (uint256[4] memory pubkey) {
        if (point.length != 128) {
            revert InvalidPublicKeyEncoding();
        }
        uint256 x0;
        uint256 x1;
        uint256 y0;
        uint256 y1;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            // look the first 32 bytes of a bytes struct is its length
            x0 := mload(add(point, 32))
            x1 := mload(add(point, 64))
            y0 := mload(add(point, 96))
            y1 := mload(add(point, 128))
        }
        pubkey = [x0, x1, y0, y1];
    }

    function decompress(uint256 compressedSignature) public view returns (uint256[2] memory uncompressed) {
        uint256 x = compressedSignature & FIELD_MASK;
        // The most significant bit, when set, indicates that the y-coordinate of the point
        // is the lexicographically largest of the two associated values.
        // The second-most significant bit indicates that the point is at infinity. If this bit is set,
        // the remaining bits of the group element's encoding should be set to zero.
        // We don't accept infinity as valid signature.
        uint256 decision = compressedSignature >> 254;
        if (decision & 1 == 1) {
            revert MustNotBeInfinity();
        }
        uint256 y;
        (y,) = deriveYOnG1(x);

        // If the following two conditions or their negative forms are not met at the same time, get the negative y.
        // 1. The most significant bit of compressed signature is set
        // 2. The y we recovered first is the lexicographically largest
        if (((decision >> 1) ^ (y > N / 2 ? 1 : 0)) == 1) {
            y = N - y;
        }
        return [x, y];
    }

    function isValid(uint256 compressedSignature) public view returns (bool) {
        uint256 x = compressedSignature & FIELD_MASK;
        if (x >= N) {
            return false;
        } else if (x == 0) {
            return false;
        }
        return isOnCurveG1(x);
    }

    function isOnCurveG1(uint256[2] memory point) internal pure returns (bool _isOnCurve) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let t0 := mload(point)
            let t1 := mload(add(point, 32))
            let t2 := mulmod(t0, t0, N)
            t2 := mulmod(t2, t0, N)
            t2 := addmod(t2, 3, N)
            t1 := mulmod(t1, t1, N)
            _isOnCurve := eq(t1, t2)
        }
    }

    function isOnCurveG1(uint256 x) internal view returns (bool _isOnCurve) {
        bool callSuccess;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let t0 := x
            let t1 := mulmod(t0, t0, N)
            t1 := mulmod(t1, t0, N)
            // x ^ 3 + b
            t1 := addmod(t1, 3, N)

            let freemem := mload(0x40)
            mstore(freemem, 0x20)
            mstore(add(freemem, 0x20), 0x20)
            mstore(add(freemem, 0x40), 0x20)
            mstore(add(freemem, 0x60), t1)
            // (N - 1) / 2 = 0x183227397098d014dc2822db40c0ac2ecbc0b548b438e5469e10460b6c3e7ea3
            mstore(add(freemem, 0x80), 0x183227397098d014dc2822db40c0ac2ecbc0b548b438e5469e10460b6c3e7ea3)
            // N = 0x30644e72e131a029b85045b68181585d97816a916871ca8d3c208c16d87cfd47
            mstore(add(freemem, 0xA0), 0x30644e72e131a029b85045b68181585d97816a916871ca8d3c208c16d87cfd47)
            callSuccess := staticcall(sub(gas(), 2000), 5, freemem, 0xC0, freemem, 0x20)
            _isOnCurve := eq(1, mload(freemem))
        }
    }

    function isOnCurveG2(uint256[4] memory point) internal pure returns (bool _isOnCurve) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            // x0, x1
            let t0 := mload(point)
            let t1 := mload(add(point, 32))
            // x0 ^ 2
            let t2 := mulmod(t0, t0, N)
            // x1 ^ 2
            let t3 := mulmod(t1, t1, N)
            // 3 * x0 ^ 2
            let t4 := add(add(t2, t2), t2)
            // 3 * x1 ^ 2
            let t5 := addmod(add(t3, t3), t3, N)
            // x0 * (x0 ^ 2 - 3 * x1 ^ 2)
            t2 := mulmod(add(t2, sub(N, t5)), t0, N)
            // x1 * (3 * x0 ^ 2 - x1 ^ 2)
            t3 := mulmod(add(t4, sub(N, t3)), t1, N)

            // x ^ 3 + b
            t0 := addmod(t2, 0x2b149d40ceb8aaae81be18991be06ac3b5b4c5e559dbefa33267e6dc24a138e5, N)
            t1 := addmod(t3, 0x009713b03af0fed4cd2cafadeed8fdf4a74fa084e52d1852e4a2bd0685c315d2, N)

            // y0, y1
            t2 := mload(add(point, 64))
            t3 := mload(add(point, 96))
            // y ^ 2
            t4 := mulmod(addmod(t2, t3, N), addmod(t2, sub(N, t3), N), N)
            t3 := mulmod(shl(1, t2), t3, N)

            // y ^ 2 == x ^ 3 + b
            _isOnCurve := and(eq(t0, t4), eq(t1, t3))
        }
    }

    function sqrt(uint256 xx) internal view returns (uint256 x, bool hasRoot) {
        bool callSuccess;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let freemem := mload(0x40)
            mstore(freemem, 0x20)
            mstore(add(freemem, 0x20), 0x20)
            mstore(add(freemem, 0x40), 0x20)
            mstore(add(freemem, 0x60), xx)
            // this is enabled by N % 4 = 3 and Fermat's little theorem
            // (N + 1) / 4 = 0xc19139cb84c680a6e14116da060561765e05aa45a1c72a34f082305b61f3f52
            mstore(add(freemem, 0x80), 0xc19139cb84c680a6e14116da060561765e05aa45a1c72a34f082305b61f3f52)
            // N = 0x30644e72e131a029b85045b68181585d97816a916871ca8d3c208c16d87cfd47
            mstore(add(freemem, 0xA0), 0x30644e72e131a029b85045b68181585d97816a916871ca8d3c208c16d87cfd47)
            callSuccess := staticcall(sub(gas(), 2000), 5, freemem, 0xC0, freemem, 0x20)
            x := mload(freemem)
            hasRoot := eq(xx, mulmod(x, x, N))
        }
        require(callSuccess, "BLS: sqrt modexp call failed");
    }

    /// @notice Add two points in G1
    function addPoints(uint256[2] memory p1, uint256[2] memory p2) internal view returns (uint256[2] memory ret) {
        uint256[4] memory input;
        input[0] = p1[0];
        input[1] = p1[1];
        input[2] = p2[0];
        input[3] = p2[1];
        bool success;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            success := staticcall(sub(gas(), 2000), 6, input, 0xc0, ret, 0x60)
        }
        // solhint-disable-next-line reason-string
        require(success);
    }
}