// SPDX-License-Identifier: UNLICENSED
// Copyright (c) ConsenSys
// Copyright (c) Eywa.Fi, 2021-2023 - all rights reserved
pragma solidity 0.8.17;

import "./ModUtils.sol";

/**
 * @title Verify BLS Threshold Signed values.
 *
 * Much of the code in this file is derived from here:
 * https://github.com/ConsenSys/gpact/blob/main/common/common/src/main/solidity/BlsSignatureVerification.sol
 * https://github.com/ConsenSys/gpact/blob/main/contracts/contracts/src/common/BlsSignatureVerification.sol
 */
library Bls {
    using ModUtils for uint256;

    struct E1Point {
        uint256 x;
        uint256 y;
    }

    /**
     * @dev Note that the ordering of the elements in each array needs to be the reverse of what you would
     * normally have, to match the ordering expected by the precompile.
     */
    struct E2Point {
        uint256[2] x;
        uint256[2] y;
    }

    /**
     * @dev P is a prime over which we form a basic field;
     * taken from go-ethereum/crypto/bn256/cloudflare/constants.go.
     */
    uint256 constant P = 21888242871839275222246405745257275088696311157297823662689037894645226208583;

    struct Epoch {
        /// @param sum of all participant public keys
        E2Point publicKey;
        /// @param // sum of H(Pub, i) hashes of all participants indexes
        E1Point precomputedSum;
        /// @param // participants count contributed to the epochKey
        uint8 participantsCount;
        /// @param epoch number
        uint32 epochNum;
        /// @param epoch hash
        bytes32 epochHash;
    }

    /**
     * @dev Tests that epoch is set or zero.
     */
    function isSet(Epoch memory epoch) internal pure returns (bool) {
        return epoch.publicKey.x[0] != 0 || epoch.publicKey.x[1] != 0;
    }

    /**
     * @dev Reset the epoch.
     */
    function reset(Epoch storage epoch) internal {
        epoch.publicKey.x[0] = 0;
        epoch.publicKey.x[1] = 0;
        epoch.precomputedSum.x = 0;
        epoch.epochHash = 0;
        epoch.participantsCount = 0;
    }

    /**
     * @dev Update epoch and precompute epoch sum as if all participants signed.
     *
     * @param epoch_ current epoch to update;
     * @param epochPublicKey sum of all participant public keys;
     * @param epochParticipantsCount number of participants;
     * @param epochNum number of participants;
     * @param epochHash epoch hash.
     */
    function update(
        Epoch storage epoch_,
        bytes memory epochPublicKey,
        uint8 epochParticipantsCount,
        uint32 epochNum,
        bytes32 epochHash
    ) internal {
        E2Point memory pub = decodeE2Point(epochPublicKey);
        E1Point memory sum = E1Point(0, 0);
        uint256 index = 0;
        bytes memory buf = abi.encodePacked(pub.x, pub.y, index);
        while (index < epochParticipantsCount) {
            assembly {
                mstore(add(buf, 160), index)
            } // overwrite index field, same as buf[128] = index
            sum = addCurveE1(sum, hashToCurveE1(buf));
            index++;
        }
        epoch_.publicKey = pub;
        epoch_.precomputedSum = sum;
        epoch_.participantsCount = epochParticipantsCount;
        epoch_.epochNum = epochNum;
        epoch_.epochHash = epochHash;
    }

    /**
     * @dev Checks if the BLS multisignature is valid in the current epoch.
     *
     * @param epoch_ current epoch;
     * @param partPublicKey Sum of participated public keys;
     * @param message Message that was signed;
     * @param partSignature Signature over the message;
     * @param signersBitmask Bitmask of participants in this signature;
     * @return True if the message was correctly signed by the given participants.
     */
    function verifyMultisig(
        Epoch memory epoch_,
        bytes memory partPublicKey,
        bytes memory message,
        bytes memory partSignature,
        uint256 signersBitmask
    ) internal view returns (bool) {
        E1Point memory sum = epoch_.precomputedSum;
        uint256 index = 0;
        uint256 mask = 1;
        bytes memory buf = abi.encodePacked(epoch_.publicKey.x, epoch_.publicKey.y, index);
        while (index < epoch_.participantsCount) {
            if (signersBitmask & mask == 0) {
                assembly {
                    mstore(add(buf, 160), index)
                } // overwrite index field, same as buf[128] = index
                sum = addCurveE1(sum, negate(hashToCurveE1(buf)));
            }
            mask <<= 1;
            index++;
        }

        E1Point[] memory e1points = new E1Point[](3);
        E2Point[] memory e2points = new E2Point[](3);
        e1points[0] = negate(decodeE1Point(partSignature));
        e1points[1] = hashToCurveE1(abi.encodePacked(epoch_.publicKey.x, epoch_.publicKey.y, message));
        e1points[2] = sum;
        e2points[0] = G2();
        e2points[1] = decodeE2Point(partPublicKey);
        e2points[2] = epoch_.publicKey;
        return pairing(e1points, e2points);
    }

    /**
     * @return The generator of E1.
     */
    function G1() private pure returns (E1Point memory) {
        return E1Point(1, 2);
    }

    /**
     * @return The generator of E2.
     */
    function G2() private pure returns (E2Point memory) {
        return E2Point({
            x: [
                11559732032986387107991004021392285783925812861821192530917403151452391805634,
                10857046999023057135944570762232829481370756359578518086990519993285655852781
            ],
            y: [
                4082367875863433681332203403145435568316851327593401208105741076214120093531,
                8495653923123431417604973247489272438418190587263600148770280649306958101930
            ]
        });
    }

    /**
     * Negate a point: Assuming the point isn't at infinity, the negation is same x value with -y.
     *
     * @dev Negates a point in E1;
     * @param _point Point to negate;
     * @return The negated point.
     */
    function negate(E1Point memory _point) private pure returns (E1Point memory) {
        if (isAtInfinity(_point)) {
            return E1Point(0, 0);
        }
        return E1Point(_point.x, P - (_point.y % P));
    }

    /**
     * Computes the pairing check e(p1[0], p2[0]) *  .... * e(p1[n], p2[n]) == 1
     *
     * @param _e1points List of points in E1;
     * @param _e2points List of points in E2;
     * @return True if pairing check succeeds.
     */
    function pairing(E1Point[] memory _e1points, E2Point[] memory _e2points) private view returns (bool) {
        require(_e1points.length == _e2points.length, "Bls: point count mismatch");

        uint256 elements = _e1points.length;
        uint256 inputSize = elements * 6;
        uint256[] memory input = new uint256[](inputSize);

        for (uint256 i = 0; i < elements; i++) {
            input[i * 6 + 0] = _e1points[i].x;
            input[i * 6 + 1] = _e1points[i].y;
            input[i * 6 + 2] = _e2points[i].x[0];
            input[i * 6 + 3] = _e2points[i].x[1];
            input[i * 6 + 4] = _e2points[i].y[0];
            input[i * 6 + 5] = _e2points[i].y[1];
        }

        uint256[1] memory out;
        bool success;
        assembly {
            // Start at memory offset 0x20 rather than 0 as input is a variable length array.
            // Location 0 is the length field.
            success := staticcall(sub(gas(), 2000), 8, add(input, 0x20), mul(inputSize, 0x20), out, 0x20)
        }
        // The pairing operation will fail if the input data isn't the correct size (this won't happen
        // given the code above), or if one of the points isn't on the curve.
        require(success, "Bls: pairing operation failed");
        return out[0] != 0;
    }

    /**
     * @dev Checks if the point is the point at infinity.
     *
     * @param _point a point on E1;
     * @return true if the point is the point at infinity.
     */
    function isAtInfinity(E1Point memory _point) private pure returns (bool) {
        return (_point.x == 0 && _point.y == 0);
    }

    /**
     * @dev Hash a byte array message, m, and map it deterministically to a point on G1.
     * Note that this approach was chosen for its simplicity /
     * lower gas cost on the EVM, rather than good distribution of points on G1.
     */
    function hashToCurveE1(bytes memory m) internal view returns (E1Point memory) {
        bytes32 h = sha256(m);
        uint256 x = uint256(h) % P;
        uint256 y;

        while (true) {
            y = YFromX(x);
            if (y > 0) {
                return E1Point(x, y);
            }
            x += 1;
        }
        revert("hashToCurveE1: unreachable end point");
    }

    /**
     * @dev g1YFromX computes a Y value for a G1 point based on an X value.
     * This computation is simply evaluating the curve equation for Y on a given X,
     * and allows a point on the curve to be represented by just an X value + a sign bit.
     */
    function YFromX(uint256 x) internal view returns (uint256) {
        return ((x.modExp(3, P) + 3) % P).modSqrt(P);
    }

    /**
     * @dev return the sum of two points of G1.
     */
    function addCurveE1(E1Point memory _p1, E1Point memory _p2) internal view returns (E1Point memory res) {
        uint256[4] memory input;
        input[0] = _p1.x;
        input[1] = _p1.y;
        input[2] = _p2.x;
        input[3] = _p2.y;
        bool success;
        assembly {
            success := staticcall(sub(gas(), 2000), 6, input, 0x80, res, 0x40)
        }
        require(success, "Bls: add points failed");
    }

    function decodeE1Point(bytes memory _sig) internal pure returns (E1Point memory signature) {
        uint256 sigx;
        uint256 sigy;
        assembly {
            sigx := mload(add(_sig, 0x20))
            sigy := mload(add(_sig, 0x40))
        }
        signature.x = sigx;
        signature.y = sigy;
    }

    function decodeE2Point(bytes memory _pubKey) internal pure returns (E2Point memory pubKey) {
        uint256 x1;
        uint256 x2;
        uint256 y1;
        uint256 y2;
        assembly {
            x1 := mload(add(_pubKey, 0x20))
            x2 := mload(add(_pubKey, 0x40))
            y1 := mload(add(_pubKey, 0x60))
            y2 := mload(add(_pubKey, 0x80))
        }
        pubKey.x[0] = x1;
        pubKey.x[1] = x2;
        pubKey.y[0] = y1;
        pubKey.y[1] = y2;
    }
}