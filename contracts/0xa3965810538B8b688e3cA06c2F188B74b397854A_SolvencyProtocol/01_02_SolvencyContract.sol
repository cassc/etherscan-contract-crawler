// SPDX-License-Identifier: MIT
// solc --bin --abi SolvencyContract.sol -o ./SolvencyContract --overwrite

pragma solidity ^0.8.0;

import "Pairing.sol";

contract SolvencyProtocol {

    struct VerifyingKey {
        Pairing.G1Point alpha1;
        Pairing.G2Point beta2;
        Pairing.G2Point gamma2;
        Pairing.G2Point delta2;
        Pairing.G1Point IC0;
        Pairing.G1Point IC1;
    }

    struct Proof {
        Pairing.G1Point A;
        Pairing.G2Point B;
        Pairing.G1Point C;
    }

    event ProofPublished(bool verificationOutcome, string metadata, uint timestamp, uint vKeyId,
        uint[2] proofG1A, uint[4] proofG2B, uint[2] proofG1C, uint256 publicInput);

    address private owner;
    mapping (address => bool) public admins;
    mapping (uint => VerifyingKey) public verifyingKeys;
    mapping (uint => bool) public verifyingKeyIds;

    constructor() {
        admins[msg.sender] = true;
    }

    function addAdmin(address newAdmin) public {
        require (admins[msg.sender], "You must be an admin to add a new admin");
        admins[newAdmin] = true;
    }

    function delAdmin(address oldAdmin) public {
        require (admins[msg.sender], "You must be an admit to delete an admin");
        admins[oldAdmin] = false;
    }

    function addVerifyingKey(uint[2] memory alpha1,
        uint[4] memory beta2,
        uint[4] memory gamma2,
        uint[4] memory delta2,
        uint[4] memory IC,
        uint vKeyId
    ) public {
        require(admins[msg.sender], "You must be an admin to add a new verifying key!");
        require(!verifyingKeyIds[vKeyId], "This verifying key ID is already in use!");
        Pairing.G1Point memory _alpha1 = Pairing.G1Point(alpha1[0], alpha1[1]);
        Pairing.G2Point memory _beta2 = Pairing.G2Point([beta2[0], beta2[1]], [beta2[2], beta2[3]]);
        Pairing.G2Point memory _gamma2 = Pairing.G2Point([gamma2[0], gamma2[1]], [gamma2[2], gamma2[3]]);
        Pairing.G2Point memory _delta2 = Pairing.G2Point([delta2[0], delta2[1]], [delta2[2], delta2[3]]);

        assert(IC.length == 4);
        Pairing.G1Point memory IC0 = Pairing.G1Point(IC[0], IC[1]);
        Pairing.G1Point memory IC1 = Pairing.G1Point(IC[2], IC[3]);

        verifyingKeys[vKeyId] = VerifyingKey({
        alpha1: _alpha1,
        beta2: _beta2,
        gamma2: _gamma2,
        delta2: _delta2,
        IC0: IC0,
        IC1: IC1
        });
        verifyingKeyIds[vKeyId] = true;
    }

    function publishSolvencyProof(uint[2] memory a,
        uint[4] memory b,
        uint[2] memory c,
        uint256 publicInput,
        string calldata metadata,
        uint vKeyId) public returns (bool)
    {

        Proof memory proof = Proof({
        A: Pairing.G1Point(a[0], a[1]),
        B: Pairing.G2Point([b[0],b[1]], [b[2], b[3]]),
        C: Pairing.G1Point(c[0], c[1])
        });


        require(verifyingKeyIds[vKeyId], "Invalid verifying key ID");

        // copy function arguments to local memory to avoid "stack too deep" error
        uint256 _publicInput = publicInput;
        uint256 _vKeyId = vKeyId;

        uint[2] memory proofG1A = [proof.A.X, proof.A.Y];
        uint[4] memory proofG1B;
        proofG1B[0] = proof.B.X[0];
        proofG1B[1] = proof.B.X[1];
        proofG1B[2] = proof.B.Y[0];
        proofG1B[3] = proof.B.Y[1];

        uint[2] memory proofG1C = [proof.C.X,proof.C.Y];
        bool verified = verifyProof(proof, publicInput, vKeyId);

        emit ProofPublished(verified, metadata, block.timestamp, _vKeyId,
            proofG1A, proofG1B, proofG1C, _publicInput);

        return verified;
    }

    function verify(uint256 input, Proof memory proof, VerifyingKey memory verifyingKey) internal view returns (bool) {
        uint256 snark_scalar_field = 21888242871839275222246405745257275088548364400416034343698204186575808495617;

        Pairing.G1Point memory vk_x = verifyingKey.IC0;

        require(input < snark_scalar_field,"verifier-gte-snark-scalar-field");
        vk_x = Pairing.addition(vk_x, Pairing.scalar_mul(verifyingKey.IC1, input));

        return Pairing.pairingProd4(
            Pairing.negate(proof.A), proof.B,
            verifyingKey.alpha1, verifyingKey.beta2,
            vk_x, verifyingKey.gamma2,
            proof.C, verifyingKey.delta2
        );
    }
    /// @return r  bool true if proof is valid
    function verifyProof(
        Proof memory proof,
        uint256 input,
        uint vKeyId
    ) public view returns (bool r) {
        VerifyingKey memory verifyingKey = verifyingKeys[vKeyId];
        return verify(input, proof, verifyingKey);
    }

}