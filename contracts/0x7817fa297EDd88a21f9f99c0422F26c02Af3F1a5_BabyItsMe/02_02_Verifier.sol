// This file is MIT Licensed.
//
// Copyright 2017 Christian Reitwiessner
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
// The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
pragma solidity ^0.8.0;

library Pairing {
    struct G1Point {
        uint256 X;
        uint256 Y;
    }
    // Encoding of field elements is: X[0] * z + X[1]

    struct G2Point {
        uint256[2] X;
        uint256[2] Y;
    }
    /// @return the generator of G1

    function P1() internal pure returns (G1Point memory) {
        return G1Point(1, 2);
    }
    /// @return the generator of G2

    function P2() internal pure returns (G2Point memory) {
        return G2Point(
            [
                10857046999023057135944570762232829481370756359578518086990519993285655852781,
                11559732032986387107991004021392285783925812861821192530917403151452391805634
            ],
            [
                8495653923123431417604973247489272438418190587263600148770280649306958101930,
                4082367875863433681332203403145435568316851327593401208105741076214120093531
            ]
        );
    }
    /// @return the negation of p, i.e. p.addition(p.negate()) should be zero.

    function negate(G1Point memory p) internal pure returns (G1Point memory) {
        // The prime q in the base field F_q for G1
        uint256 q = 21888242871839275222246405745257275088696311157297823662689037894645226208583;
        if (p.X == 0 && p.Y == 0) {
            return G1Point(0, 0);
        }
        return G1Point(p.X, q - (p.Y % q));
    }
    /// @return r the sum of two points of G1

    function addition(G1Point memory p1, G1Point memory p2) internal view returns (G1Point memory r) {
        uint256[4] memory input;
        input[0] = p1.X;
        input[1] = p1.Y;
        input[2] = p2.X;
        input[3] = p2.Y;
        bool success;
        assembly {
            success := staticcall(sub(gas(), 2000), 6, input, 0xc0, r, 0x60)
            // Use "invalid" to make gas estimation work
            switch success
            case 0 { invalid() }
        }
        require(success);
    }

    /// @return r the product of a point on G1 and a scalar, i.e.
    /// p == p.scalar_mul(1) and p.addition(p) == p.scalar_mul(2) for all points p.
    function scalar_mul(G1Point memory p, uint256 s) internal view returns (G1Point memory r) {
        uint256[3] memory input;
        input[0] = p.X;
        input[1] = p.Y;
        input[2] = s;
        bool success;
        assembly {
            success := staticcall(sub(gas(), 2000), 7, input, 0x80, r, 0x60)
            // Use "invalid" to make gas estimation work
            switch success
            case 0 { invalid() }
        }
        require(success);
    }
    /// @return the result of computing the pairing check
    /// e(p1[0], p2[0]) *  .... * e(p1[n], p2[n]) == 1
    /// For example pairing([P1(), P1().negate()], [P2(), P2()]) should
    /// return true.

    function pairing(G1Point[] memory p1, G2Point[] memory p2) internal view returns (bool) {
        require(p1.length == p2.length);
        uint256 elements = p1.length;
        uint256 inputSize = elements * 6;
        uint256[] memory input = new uint[](inputSize);
        for (uint256 i = 0; i < elements; i++) {
            input[i * 6 + 0] = p1[i].X;
            input[i * 6 + 1] = p1[i].Y;
            input[i * 6 + 2] = p2[i].X[1];
            input[i * 6 + 3] = p2[i].X[0];
            input[i * 6 + 4] = p2[i].Y[1];
            input[i * 6 + 5] = p2[i].Y[0];
        }
        uint256[1] memory out;
        bool success;
        assembly {
            success := staticcall(sub(gas(), 2000), 8, add(input, 0x20), mul(inputSize, 0x20), out, 0x20)
            // Use "invalid" to make gas estimation work
            switch success
            case 0 { invalid() }
        }
        require(success);
        return out[0] != 0;
    }
    /// Convenience method for a pairing check for two pairs.

    function pairingProd2(G1Point memory a1, G2Point memory a2, G1Point memory b1, G2Point memory b2)
        internal
        view
        returns (bool)
    {
        G1Point[] memory p1 = new G1Point[](2);
        G2Point[] memory p2 = new G2Point[](2);
        p1[0] = a1;
        p1[1] = b1;
        p2[0] = a2;
        p2[1] = b2;
        return pairing(p1, p2);
    }
    /// Convenience method for a pairing check for three pairs.

    function pairingProd3(
        G1Point memory a1,
        G2Point memory a2,
        G1Point memory b1,
        G2Point memory b2,
        G1Point memory c1,
        G2Point memory c2
    ) internal view returns (bool) {
        G1Point[] memory p1 = new G1Point[](3);
        G2Point[] memory p2 = new G2Point[](3);
        p1[0] = a1;
        p1[1] = b1;
        p1[2] = c1;
        p2[0] = a2;
        p2[1] = b2;
        p2[2] = c2;
        return pairing(p1, p2);
    }
    /// Convenience method for a pairing check for four pairs.

    function pairingProd4(
        G1Point memory a1,
        G2Point memory a2,
        G1Point memory b1,
        G2Point memory b2,
        G1Point memory c1,
        G2Point memory c2,
        G1Point memory d1,
        G2Point memory d2
    ) internal view returns (bool) {
        G1Point[] memory p1 = new G1Point[](4);
        G2Point[] memory p2 = new G2Point[](4);
        p1[0] = a1;
        p1[1] = b1;
        p1[2] = c1;
        p1[3] = d1;
        p2[0] = a2;
        p2[1] = b2;
        p2[2] = c2;
        p2[3] = d2;
        return pairing(p1, p2);
    }
}

contract Verifier {
    using Pairing for *;

    struct VerifyingKey {
        Pairing.G1Point alpha;
        Pairing.G2Point beta;
        Pairing.G2Point gamma;
        Pairing.G2Point delta;
        Pairing.G1Point[] gamma_abc;
    }

    struct Proof {
        Pairing.G1Point a;
        Pairing.G2Point b;
        Pairing.G1Point c;
    }

    function verifyingKey() internal pure returns (VerifyingKey memory vk) {
        vk.alpha = Pairing.G1Point(
            uint256(0x0284c469d8eaf677e29635e18886312bd0c6ba2a632674a2703a8d9a5d5a48db),
            uint256(0x19b4d4d74797c3307e59c683ccad9119397c90f76ad28c043ec9671a95502e76)
        );
        vk.beta = Pairing.G2Point(
            [
                uint256(0x0319296206e25c6e7ea35492e825fcdbea39b0980b72f18b3f7385d6d46352b0),
                uint256(0x10bc74487c379aad3a10da56c479ae5db4e4b3faeb354f4aa57ed4524a3e4527)
            ],
            [
                uint256(0x2971943778693059384530140201f76e29adf7a4222921b744f09045f2011e1d),
                uint256(0x21099f091b01503caab27b87ee9769840d27963846e35613d26190bc5c4d0cef)
            ]
        );
        vk.gamma = Pairing.G2Point(
            [
                uint256(0x2cd9c9e8f055f3663213f71c1c3f99c6b363b35f50e0fe2e8405d029deb1e295),
                uint256(0x0fdcd887987c8e156d574ee4e97cf66bf36e7a8539b8c4bd578ff7bced1a601c)
            ],
            [
                uint256(0x2d96d4c9dcf6ff4da92c433beb2749c86fff05bfd2d83c3da9a7d531903ec942),
                uint256(0x13fb1bdc1b558571d6ba4944428eeb52aa0d69378072aa64cf543d4189b8af78)
            ]
        );
        vk.delta = Pairing.G2Point(
            [
                uint256(0x122757890c3f43309334e26258842bb8e8ab0450d387ddf7bc20fc5e01619d92),
                uint256(0x00593e12fef04367a7d771cc137c7a3f0f245584f4a40e44c6281ca51e610027)
            ],
            [
                uint256(0x11b21f2409f28092f35b9cd195ee93ee5d0e11aca3e1a432c007243e186dec7c),
                uint256(0x1bcf98b5bbd114064cf46447c90092bbf9384056f13c9487d8021f73d92ac452)
            ]
        );
        vk.gamma_abc = new Pairing.G1Point[](5);
        vk.gamma_abc[0] = Pairing.G1Point(
            uint256(0x2fc73b5bbb85acbd703828a3df8ee04ef648832b3bbf2c9fd5bb51d4ab0ef984),
            uint256(0x197f3e6cf0bde2d74a7c29bbabe7ea80928b45b23478309ea671a2b973a7edf2)
        );
        vk.gamma_abc[1] = Pairing.G1Point(
            uint256(0x1b723ed82a7478e39551e2ab9346eda38a1c000cdd5f8ade3ccf6685f9d37b1e),
            uint256(0x26ad983f9927d8414cddfe79a4eda6717a8e82a0e85450e7ca745cd15af62c77)
        );
        vk.gamma_abc[2] = Pairing.G1Point(
            uint256(0x262988545555095a281b0c6ac183626fd44094e1cc230aa38a705030d69124f3),
            uint256(0x1f248dcfb5baf7962c1c481b9d52110825710ace9b94ef387f78651cb9d3335b)
        );
        vk.gamma_abc[3] = Pairing.G1Point(
            uint256(0x2b17ccfb2bf38f9ed35f4cb962b705028429e1e66679bff2d13a0f31049a2b3a),
            uint256(0x1abe95f952ab1cd0a71f61d4304c8e85a777cf5afcb1936b9113a6c8acf22c68)
        );
        vk.gamma_abc[4] = Pairing.G1Point(
            uint256(0x2d476a4fc5d6e7900b821ac91bc179164787f4c1532bd3b91facf951788f40af),
            uint256(0x2a45d903c16fe8f0d0a14b36ae3ff7252075a266a0c749d3215352f175c1c8f1)
        );
    }

    function verify(uint256[4] memory input, Proof memory proof) internal view returns (uint256) {
        uint256 snark_scalar_field = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
        VerifyingKey memory vk = verifyingKey();
        require(input.length + 1 == vk.gamma_abc.length);
        // Compute the linear combination vk_x
        Pairing.G1Point memory vk_x = Pairing.G1Point(0, 0);
        for (uint256 i = 0; i < input.length; i++) {
            require(input[i] < snark_scalar_field);
            vk_x = Pairing.addition(vk_x, Pairing.scalar_mul(vk.gamma_abc[i + 1], input[i]));
        }
        vk_x = Pairing.addition(vk_x, vk.gamma_abc[0]);
        if (
            !Pairing.pairingProd4(
                proof.a,
                proof.b,
                Pairing.negate(vk_x),
                vk.gamma,
                Pairing.negate(proof.c),
                vk.delta,
                Pairing.negate(vk.alpha),
                vk.beta
            )
        ) return 1;
        return 0;
    }
}