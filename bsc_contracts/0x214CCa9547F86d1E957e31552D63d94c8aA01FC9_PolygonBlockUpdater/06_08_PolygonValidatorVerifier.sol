// SPDX-License-Identifier: AML
//
// Copyright 2017 Christian Reitwiessner
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to
// deal in the Software without restriction, including without limitation the
// rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
// sell copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
// FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
// IN THE SOFTWARE.

// 2019 OKIMS

pragma solidity ^0.8.0;

library PairingValidator {

    uint256 constant PRIME_Q = 21888242871839275222246405745257275088696311157297823662689037894645226208583;

    struct G1Point {
        uint256 X;
        uint256 Y;
    }

    // Encoding of field elements is: X[0] * z + X[1]
    struct G2Point {
        uint256[2] X;
        uint256[2] Y;
    }

    /*
     * @return The negation of p, i.e. p.plus(p.negate()) should be zero.
     */
    function negate(G1Point memory p) internal pure returns (G1Point memory) {

        // The prime q in the base field F_q for G1
        if (p.X == 0 && p.Y == 0) {
            return G1Point(0, 0);
        } else {
            return G1Point(p.X, PRIME_Q - (p.Y % PRIME_Q));
        }
    }

    /*
     * @return The sum of two points of G1
     */
    function plus(
        G1Point memory p1,
        G1Point memory p2
    ) internal view returns (G1Point memory r) {

        uint256[4] memory input;
        input[0] = p1.X;
        input[1] = p1.Y;
        input[2] = p2.X;
        input[3] = p2.Y;
        bool success;

        // solium-disable-next-line security/no-inline-assembly
        assembly {
            success := staticcall(sub(gas(), 2000), 6, input, 0xc0, r, 0x60)
        // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }

        require(success,"PairingValidator-add-failed");
    }

    /*
     * @return The product of a point on G1 and a scalar, i.e.
     *         p == p.scalar_mul(1) and p.plus(p) == p.scalar_mul(2) for all
     *         points p.
     */
    function scalar_mul(G1Point memory p, uint256 s) internal view returns (G1Point memory r) {

        uint256[3] memory input;
        input[0] = p.X;
        input[1] = p.Y;
        input[2] = s;
        bool success;
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            success := staticcall(sub(gas(), 2000), 7, input, 0x80, r, 0x60)
        // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }
        require (success,"PairingValidator-mul-failed");
    }

    /* @return The result of computing the PairingValidator check
     *         e(p1[0], p2[0]) *  .... * e(p1[n], p2[n]) == 1
     *         For example,
     *         PairingValidator([P1(), P1().negate()], [P2(), P2()]) should return true.
     */
    function pairing(
        G1Point memory a1,
        G2Point memory a2,
        G1Point memory b1,
        G2Point memory b2,
        G1Point memory c1,
        G2Point memory c2,
        G1Point memory d1,
        G2Point memory d2
    ) internal view returns (bool) {

        G1Point[4] memory p1 = [a1, b1, c1, d1];
        G2Point[4] memory p2 = [a2, b2, c2, d2];
        uint256 inputSize = 24;
        uint256[] memory input = new uint256[](inputSize);

        for (uint256 i = 0; i < 4; i++) {
            uint256 j = i * 6;
            input[j + 0] = p1[i].X;
            input[j + 1] = p1[i].Y;
            input[j + 2] = p2[i].X[0];
            input[j + 3] = p2[i].X[1];
            input[j + 4] = p2[i].Y[0];
            input[j + 5] = p2[i].Y[1];
        }

        uint256[1] memory out;
        bool success;

        // solium-disable-next-line security/no-inline-assembly
        assembly {
            success := staticcall(sub(gas(), 2000), 8, add(input, 0x20), mul(inputSize, 0x20), out, 0x20)
        // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }

        require(success,"PairingValidator-opcode-failed");

        return out[0] != 0;
    }
}

contract PolygonValidatorVerifier {

    using PairingValidator for *;

    uint256 constant SNARK_SCALAR_FIELD_VALIDATOR = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
    uint256 constant PRIME_Q_VALIDATOR = 21888242871839275222246405745257275088696311157297823662689037894645226208583;

    struct VerifyingKeyValidator {
        PairingValidator.G1Point alfa1;
        PairingValidator.G2Point beta2;
        PairingValidator.G2Point gamma2;
        PairingValidator.G2Point delta2;
        PairingValidator.G1Point[2] IC;
    }

    struct ProofValidator {
        PairingValidator.G1Point A;
        PairingValidator.G2Point B;
        PairingValidator.G1Point C;
    }

    function verifyingKeyValidator() internal pure returns (VerifyingKeyValidator memory vk) {
        vk.alfa1 = PairingValidator.G1Point(uint256(2142963309243564046285520911513248548686269335685669918486855955930453853182), uint256(10220919831260759562009363429782710775330033754927315957690054709379276330351));
        vk.beta2 = PairingValidator.G2Point([uint256(4236284727782314577314241924985465167199470913150432696908817815229703196756), uint256(653546495226406573335590199282558603021193261892820390130315071442541349880)], [uint256(19152558898526291580300486421378451016115615462373906914125255732394843413567), uint256(9221326570340613689226944761629282996668830620699731998621644615801046448384)]);
        vk.gamma2 = PairingValidator.G2Point([uint256(10961142770232307779874947647095933294550960621605824375316061975341136209), uint256(16891871092828784436150193768058268859907040334224172861193490806431952353659)], [uint256(19196930400482580676101256343999490645284060400357224487457275331622975465952), uint256(11250972528658975766317637909679686227976212308551979506985198793230318753021)]);
        vk.delta2 = PairingValidator.G2Point([uint256(14700950783081387387870913684305618987997475783336024160102358290557901004361), uint256(20290233848487857438452806025569387176622804002512271785089043470551632177163)], [uint256(5304045319306971284021385729085296168469847375165955600141626432227403763575), uint256(16076061668819328867029534519600355248365026044802570864295860782615472292362)]);
        vk.IC[0] = PairingValidator.G1Point(uint256(13626354952554832565983454298416453108888892548164866718546245084769179229512), uint256(12124869786953492949364750848405556094128270244235104156111674539835017300304));
        vk.IC[1] = PairingValidator.G1Point(uint256(8084455246271206239185733773173895021705183998655495398227196454716105119634), uint256(2803981673380606007434532411650481000086501585328920644413044532375236705598));
    }

    /*
     * @returns Whether the proof is valid given the hardcoded verifying key
     *          above and the public inputs
     */
    function verifyValidatorProof(
        uint256[2] memory a,
        uint256[2][2] memory b,
        uint256[2] memory c,
        uint256[1] memory input
    ) public view returns (bool r) {

        ProofValidator memory proof;
        proof.A = PairingValidator.G1Point(a[0], a[1]);
        proof.B = PairingValidator.G2Point([b[0][0], b[0][1]], [b[1][0], b[1][1]]);
        proof.C = PairingValidator.G1Point(c[0], c[1]);

        VerifyingKeyValidator memory vk = verifyingKeyValidator();

        // Compute the linear combination vk_x
        PairingValidator.G1Point memory vk_x = PairingValidator.G1Point(0, 0);

        // Make sure that proof.A, B, and C are each less than the prime q
        require(proof.A.X < PRIME_Q_VALIDATOR, "verifier-aX-gte-prime-q");
        require(proof.A.Y < PRIME_Q_VALIDATOR, "verifier-aY-gte-prime-q");

        require(proof.B.X[0] < PRIME_Q_VALIDATOR, "verifier-bX0-gte-prime-q");
        require(proof.B.Y[0] < PRIME_Q_VALIDATOR, "verifier-bY0-gte-prime-q");

        require(proof.B.X[1] < PRIME_Q_VALIDATOR, "verifier-bX1-gte-prime-q");
        require(proof.B.Y[1] < PRIME_Q_VALIDATOR, "verifier-bY1-gte-prime-q");

        require(proof.C.X < PRIME_Q_VALIDATOR, "verifier-cX-gte-prime-q");
        require(proof.C.Y < PRIME_Q_VALIDATOR, "verifier-cY-gte-prime-q");

        // Make sure that every input is less than the snark scalar field
        for (uint256 i = 0; i < input.length; i++) {
            require(input[i] < SNARK_SCALAR_FIELD_VALIDATOR,"verifier-gte-snark-scalar-field");
            vk_x = PairingValidator.plus(vk_x, PairingValidator.scalar_mul(vk.IC[i + 1], input[i]));
        }

        vk_x = PairingValidator.plus(vk_x, vk.IC[0]);

        return PairingValidator.pairing(
            PairingValidator.negate(proof.A),
            proof.B,
            vk.alfa1,
            vk.beta2,
            vk_x,
            vk.gamma2,
            proof.C,
            vk.delta2
        );
    }
}